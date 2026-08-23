import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'src/core/app_boot_fallback.dart';
import 'src/core/firebase_app_check_bootstrap.dart';
import 'src/core/auto_sync_binder.dart';
import 'src/core/home_widget_sync.dart';
import 'src/data/repositories/auto_backup_runner.dart';
import 'src/data/repositories/backup_service.dart';
import 'src/core/notifications/daily_reminder.dart';
import 'src/core/notifications/smart_reminders.dart';
import 'src/core/pro/pro_controller.dart';
import 'src/core/theme/app_colors.dart';
import 'src/core/theme/app_theme.dart';
import 'src/data/repositories/providers.dart';
import 'src/data/repositories/settings_service.dart';
import 'src/data/repositories/scheduled_posting.dart';
import 'src/data/repositories/subscription_repository.dart';
import 'src/data/seed/seed_categories.dart';
import 'src/core/app_startup.dart';
import 'src/features/auth/cloud_restore_prompt.dart';
import 'src/features/security/lock_screen.dart';
import 'src/widgets/startup_banner.dart';
import 'src/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  var firebaseReady = false;
  String? firebaseError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
    try {
      await activateFirebaseAppCheck();
    } catch (e, st) {
      debugPrint('App Check init failed: $e\n$st');
    }
  } catch (e, st) {
    firebaseError = e.toString();
    debugPrint('Firebase init failed (app continues offline): $e\n$st');
  }

  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final shortestSide =
        view.physicalSize.shortestSide / view.devicePixelRatio;
    await SystemChrome.setPreferredOrientations(
      shortestSide >= 600
          ? const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
  } catch (e, st) {
    debugPrint('orientation: $e\n$st');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFFF2F2F2),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  try {
    await initializeDateFormatting();
  } catch (e, st) {
    debugPrint('date formatting: $e\n$st');
  }
  try {
    await configureHomeWidget();
  } catch (e, st) {
    debugPrint('home widget: $e\n$st');
  }
  try {
    await initDailyReminder();
  } catch (e, st) {
    debugPrint('daily reminder: $e\n$st');
  }

  late final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e, st) {
    debugPrint('SharedPreferences failed: $e\n$st');
    rethrow;
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      settingsBaseCurrencyProvider.overrideWith((ref) {
        return ref.watch(settingsControllerProvider).baseCurrency;
      }),
      appStartupProvider.overrideWith(
        (ref) => AppStartupState(
          firebaseReady: firebaseReady,
          firebaseError: firebaseError,
        ),
      ),
    ],
  );

  String? dataInitError;
  try {
    final db = container.read(databaseProvider);
    await seedCategoriesIfEmpty(db);
    await postDueScheduledItems(db);
    await runAutoLocalBackupIfDue(
      prefs: prefs,
      backup: container.read(backupServiceProvider),
    );
    await syncDailyReminder(container.read(settingsControllerProvider)).then(
      (result) async {
        if (result != ReminderSyncResult.noPermission) return;
        final s = container.read(settingsControllerProvider);
        if (!s.dailyReminderEnabled) return;
        await container
            .read(settingsControllerProvider.notifier)
            .setDailyReminderEnabled(false);
      },
    );
  } catch (e, st) {
    dataInitError = e.toString();
    debugPrint('startup data init: $e\n$st');
  }

  if (dataInitError != null) {
    container.read(appStartupProvider.notifier).state = AppStartupState(
      firebaseReady: firebaseReady,
      firebaseError: firebaseError,
      dataInitError: dataInitError,
    );
  }

  ErrorWidget.builder = (details) {
    return Material(
      color: AppColors.ink,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            details.exceptionAsString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ),
    );
  };

  runApp(UncontrolledProviderScope(
    container: container,
    child: const BudgetTrackerApp(),
  ));
}

class BudgetTrackerApp extends ConsumerWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);
    ref.listen<SettingsState>(settingsControllerProvider, (prev, next) {
      if (prev == next) return;
      syncDailyReminder(next).then((result) async {
        if (result != ReminderSyncResult.noPermission) return;
        if (!ref.read(settingsControllerProvider).dailyReminderEnabled) return;
        await ref
            .read(settingsControllerProvider.notifier)
            .setDailyReminderEnabled(false);
      });
      _syncSmart(ref);
    });
    ref.listen<ProState>(proControllerProvider, (prev, next) {
      if (prev?.isPro == next.isPro) return;
      _syncSmart(ref);
    });
    ref.listen(debtsProvider, (_, _) => _syncSmart(ref));
    ref.listen(subscriptionsProvider, (_, _) => _syncSmart(ref));
    ref.listen(goalsProvider, (_, _) => _syncSmart(ref));
    ref.listen(budgetsProvider, (_, _) => _syncSmart(ref));
    ref.listen(allTransactionsProvider, (_, _) => _syncSmart(ref));
    return MaterialApp.router(
      title: 'Monedero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.materialThemeMode,
      themeAnimationDuration: Duration.zero,
      locale: Locale(settings.locale),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final routed = child ?? const AppBootFallback();
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              final focus = FocusManager.instance.primaryFocus;
              if (focus != null && focus.hasFocus) focus.unfocus();
            },
            child: StartupBannerHost(
              child: AutoSyncBinder(
                child: CloudSyncFeedbackListener(
                  child: CloudLoginSyncBinder(
                    child: HomeWidgetBinder(
                      child: LockGate(child: routed),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('ru'),
        Locale('en'),
      ],
    );
  }
}

void _syncSmart(WidgetRef ref) {
  final settings = ref.read(settingsControllerProvider);
  final isPro = ref.read(proControllerProvider).isPro;
  final prefs = ref.read(sharedPreferencesProvider);
  syncSmartReminders(
    prefs: prefs,
    settings: settings,
    isPro: isPro,
    debts: ref.read(debtsProvider).valueOrNull ?? const [],
    subscriptions: ref.read(subscriptionsProvider).valueOrNull ?? const [],
    goals: ref.read(goalsProvider).valueOrNull ?? const [],
    budgets: ref.read(budgetsProvider).valueOrNull ?? const [],
    transactions: ref.read(allTransactionsProvider).valueOrNull ?? const [],
  );
}
