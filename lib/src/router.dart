import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/repositories/settings_service.dart';
import 'features/accounts/account_detail_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/budgets/budgets_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/debts/debts_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_setup_screen.dart';
import 'features/assistant/assistant_chat_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/security/security_screen.dart';
import 'features/export/export_screen.dart';
import 'features/import/import_screen.dart';
import 'features/settings/error_logs_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/backups_screen.dart';
import 'features/settings/currency_picker_screen.dart';
import 'features/settings/language_picker_screen.dart';
import 'features/settings/theme_picker_screen.dart';
import 'features/settings/reminders_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shared_budget/shared_budget_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/transactions/transfer_screen.dart';
import 'shell/app_shell.dart';

/// Native-feeling push / pop (horizontal). Avoids the janky vertical micro-slide.
Page<void> _fadePage(GoRouterState state, Widget child) {
  return CupertinoPage<void>(
    key: state.pageKey,
    child: child,
  );
}

Page<void> _instantPage(GoRouterState state, Widget child) {
  return MaterialPage<void>(
    key: state.pageKey,
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<bool>(
    settingsControllerProvider.select((s) => s.onboardingDone),
    (_, _) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation:
        ref.read(settingsControllerProvider).onboardingDone ? '/' : '/onboarding',
    redirect: (context, state) {
      final path = state.uri.path;
      final done = ref.read(settingsControllerProvider).onboardingDone;
      if (!done && !path.startsWith('/onboarding')) {
        return '/onboarding';
      }
      if (done && path.startsWith('/onboarding')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _instantPage(state, const OnboardingScreen()),
        routes: [
          GoRoute(
            path: 'setup',
            pageBuilder: (context, state) =>
                _instantPage(state, const OnboardingSetupScreen()),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/assistant',
        pageBuilder: (context, state) =>
            _fadePage(state, const AssistantChatScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _fadePage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/add',
        pageBuilder: (context, state) {
          final dateRaw = state.uri.queryParameters['date'];
          DateTime? initialDate;
          if (dateRaw != null && dateRaw.isNotEmpty) {
            initialDate = DateTime.tryParse(dateRaw);
          }
          return _fadePage(
            state,
            AddTransactionScreen(
              initialType: state.uri.queryParameters['type'],
              initialMode: state.uri.queryParameters['mode'],
              initialDate: initialDate,
            ),
          );
        },
      ),
      GoRoute(
        path: '/voice-ai',
        // Legacy deep link — voice entry is the assistant chat now.
        redirect: (context, state) => '/assistant',
      ),
      GoRoute(
        path: '/transfer',
        pageBuilder: (context, state) =>
            _fadePage(state, const TransferScreen()),
      ),
      GoRoute(
        path: '/tx/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          TransactionDetailScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) => _fadePage(
              state,
              AddTransactionScreen(
                editId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts',
        pageBuilder: (context, state) =>
            _fadePage(state, const AccountsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) => _fadePage(
              state,
              AccountDetailScreen(
                accountId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        pageBuilder: (context, state) =>
            _fadePage(state, const CategoriesScreen()),
      ),
      GoRoute(
        path: '/budgets',
        pageBuilder: (context, state) =>
            _fadePage(state, const BudgetsScreen()),
      ),
      GoRoute(
        path: '/debts',
        pageBuilder: (context, state) => _fadePage(state, const DebtsScreen()),
      ),
      GoRoute(
        path: '/goals',
        pageBuilder: (context, state) => _fadePage(state, const GoalsScreen()),
      ),
      GoRoute(
        path: '/subscriptions',
        pageBuilder: (context, state) =>
            _fadePage(state, const SubscriptionsScreen()),
      ),
      GoRoute(
        path: '/shared-budget',
        pageBuilder: (context, state) =>
            _fadePage(state, const SharedBudgetScreen()),
      ),
      GoRoute(
        path: '/recurring',
        pageBuilder: (context, state) =>
            _fadePage(state, const RecurringScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadePage(state, const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'currency',
            pageBuilder: (context, state) =>
                _fadePage(state, const CurrencyPickerScreen()),
          ),
          GoRoute(
            path: 'language',
            pageBuilder: (context, state) =>
                _fadePage(state, const LanguagePickerScreen()),
          ),
          GoRoute(
            path: 'theme',
            pageBuilder: (context, state) =>
                _fadePage(state, const ThemePickerScreen()),
          ),
          GoRoute(
            path: 'backups',
            pageBuilder: (context, state) =>
                _fadePage(state, const BackupsScreen()),
          ),
          GoRoute(
            path: 'export',
            pageBuilder: (context, state) =>
                _fadePage(state, const ExportScreen()),
          ),
          GoRoute(
            path: 'import',
            pageBuilder: (context, state) =>
                _fadePage(state, const ImportScreen()),
          ),
          GoRoute(
            path: 'account',
            pageBuilder: (context, state) =>
                _fadePage(state, const SignInScreen()),
          ),
          GoRoute(
            path: 'security',
            pageBuilder: (context, state) =>
                _fadePage(state, const SecurityScreen()),
          ),
          GoRoute(
            path: 'about',
            pageBuilder: (context, state) =>
                _fadePage(state, const AboutScreen()),
          ),
          GoRoute(
            path: 'error-logs',
            pageBuilder: (context, state) =>
                _fadePage(state, const ErrorLogsScreen()),
          ),
          GoRoute(
            path: 'reminders',
            pageBuilder: (context, state) =>
                _fadePage(state, const RemindersScreen()),
          ),
        ],
      ),
    ],
  );
});
