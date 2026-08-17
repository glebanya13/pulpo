import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Простой сервис пользовательских настроек через SharedPreferences.
class SettingsService {
  SettingsService(this._prefs);
  final SharedPreferences _prefs;

  static const _kOnboardingDone = 'onboarding_done';
  static const _kUserName = 'user_name';
  static const _kBaseCurrency = 'base_currency';
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) =>
      _prefs.setBool(_kOnboardingDone, v);

  String get userName => _prefs.getString(_kUserName) ?? 'User';
  Future<void> setUserName(String v) => _prefs.setString(_kUserName, v);

  String get baseCurrency => _prefs.getString(_kBaseCurrency) ?? 'EUR';
  Future<void> setBaseCurrency(String v) =>
      _prefs.setString(_kBaseCurrency, v);

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String v) => _prefs.setString(_kThemeMode, v);

  String get locale => _prefs.getString(_kLocale) ?? 'es';
  Future<void> setLocale(String v) => _prefs.setString(_kLocale, v);
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main()'),
);

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});

/// Reactive кэш ключевых настроек через Notifier.
class SettingsState {
  const SettingsState({
    required this.onboardingDone,
    required this.userName,
    required this.baseCurrency,
    required this.themeMode,
    required this.locale,
  });

  final bool onboardingDone;
  final String userName;
  final String baseCurrency;
  final String themeMode;
  final String locale;

  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  SettingsState copyWith({
    bool? onboardingDone,
    String? userName,
    String? baseCurrency,
    String? themeMode,
    String? locale,
  }) {
    return SettingsState(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      userName: userName ?? this.userName,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final s = ref.watch(settingsServiceProvider);
    return SettingsState(
      onboardingDone: s.onboardingDone,
      userName: s.userName,
      baseCurrency: s.baseCurrency,
      themeMode: s.themeMode,
      locale: s.locale,
    );
  }

  Future<void> completeOnboarding({
    required String name,
    required String currency,
    required String themeMode,
    required String locale,
  }) async {
    final s = ref.read(settingsServiceProvider);
    await s.setUserName(name);
    await s.setBaseCurrency(currency);
    await s.setThemeMode(themeMode);
    await s.setLocale(locale);
    await s.setOnboardingDone(true);
    state = state.copyWith(
      onboardingDone: true,
      userName: name,
      baseCurrency: currency,
      themeMode: themeMode,
      locale: locale,
    );
  }

  Future<void> markOnboardingDone() async {
    await ref.read(settingsServiceProvider).setOnboardingDone(true);
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> setTheme(String mode) async {
    await ref.read(settingsServiceProvider).setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setUserName(String name) async {
    await ref.read(settingsServiceProvider).setUserName(name);
    state = state.copyWith(userName: name);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
        SettingsController.new);
