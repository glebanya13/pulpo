import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/currencies.dart';
import 'account_repository.dart';

/// Простой сервис пользовательских настроек через SharedPreferences.
class SettingsService {
  SettingsService(this._prefs);
  final SharedPreferences _prefs;

  static const _kOnboardingDone = 'onboarding_done';
  static const _kUserName = 'user_name';
  static const _kBaseCurrency = 'base_currency';
  static const _kBaseCurrencyCountry = 'base_currency_country';
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kDailyReminder = 'daily_reminder';
  static const _kDailyReminderHour = 'daily_reminder_hour';
  static const _kDailyReminderMinute = 'daily_reminder_minute';
  static const _kSmartReminders = 'smart_reminders';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) =>
      _prefs.setBool(_kOnboardingDone, v);

  String get userName => _prefs.getString(_kUserName) ?? 'User';
  Future<void> setUserName(String v) => _prefs.setString(_kUserName, v);

  String get baseCurrency => _prefs.getString(_kBaseCurrency) ?? 'EUR';

  String get baseCurrencyCountry {
    final stored = _prefs.getString(_kBaseCurrencyCountry);
    if (stored != null && stored.isNotEmpty) return stored;
    return defaultCountryForCode(baseCurrency);
  }

  Future<void> setBaseCurrency(String v) =>
      _prefs.setString(_kBaseCurrency, v);

  Future<void> setBaseCurrencyCountry(String v) =>
      _prefs.setString(_kBaseCurrencyCountry, v);

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String v) => _prefs.setString(_kThemeMode, v);

  String get locale => _prefs.getString(_kLocale) ?? 'es';
  Future<void> setLocale(String v) => _prefs.setString(_kLocale, v);

  bool get dailyReminderEnabled => _prefs.getBool(_kDailyReminder) ?? true;
  Future<void> setDailyReminderEnabled(bool v) =>
      _prefs.setBool(_kDailyReminder, v);

  int get dailyReminderHour => _prefs.getInt(_kDailyReminderHour) ?? 21;
  Future<void> setDailyReminderHour(int v) =>
      _prefs.setInt(_kDailyReminderHour, v);

  int get dailyReminderMinute => _prefs.getInt(_kDailyReminderMinute) ?? 0;
  Future<void> setDailyReminderMinute(int v) =>
      _prefs.setInt(_kDailyReminderMinute, v);

  bool get smartRemindersEnabled => _prefs.getBool(_kSmartReminders) ?? false;
  Future<void> setSmartRemindersEnabled(bool v) =>
      _prefs.setBool(_kSmartReminders, v);
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
    required this.baseCurrencyCountry,
    required this.themeMode,
    required this.locale,
    required this.dailyReminderEnabled,
    required this.dailyReminderHour,
    required this.dailyReminderMinute,
    required this.smartRemindersEnabled,
  });

  final bool onboardingDone;
  final String userName;
  final String baseCurrency;
  final String baseCurrencyCountry;
  final String themeMode;
  final String locale;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final bool smartRemindersEnabled;

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
    String? baseCurrencyCountry,
    String? themeMode,
    String? locale,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? smartRemindersEnabled,
  }) {
    return SettingsState(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      userName: userName ?? this.userName,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      baseCurrencyCountry: baseCurrencyCountry ?? this.baseCurrencyCountry,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      smartRemindersEnabled:
          smartRemindersEnabled ?? this.smartRemindersEnabled,
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
      baseCurrencyCountry: s.baseCurrencyCountry,
      themeMode: s.themeMode,
      locale: s.locale,
      dailyReminderEnabled: s.dailyReminderEnabled,
      dailyReminderHour: s.dailyReminderHour,
      dailyReminderMinute: s.dailyReminderMinute,
      smartRemindersEnabled: s.smartRemindersEnabled,
    );
  }

  Future<void> completeOnboarding({
    required String name,
    required String currency,
    required String currencyCountry,
    required String themeMode,
    required String locale,
  }) async {
    final s = ref.read(settingsServiceProvider);
    await s.setUserName(name);
    await s.setBaseCurrency(currency);
    await s.setBaseCurrencyCountry(currencyCountry);
    await s.setThemeMode(themeMode);
    await s.setLocale(locale);
    await s.setOnboardingDone(true);
    state = state.copyWith(
      onboardingDone: true,
      userName: name,
      baseCurrency: currency,
      baseCurrencyCountry: currencyCountry,
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

  Future<void> setBaseCurrency(String currency, {required String country}) async {
    final s = ref.read(settingsServiceProvider);
    await s.setBaseCurrency(currency);
    await s.setBaseCurrencyCountry(country);
    state = state.copyWith(
      baseCurrency: currency,
      baseCurrencyCountry: country,
    );
  }

  Future<void> setLocale(String locale) async {
    await ref.read(settingsServiceProvider).setLocale(locale);
    await ref
        .read(accountRepositoryProvider)
        .relocalizeDefaultCashAccount(locale);
    state = state.copyWith(locale: locale);
  }

  Future<void> setUserName(String name) async {
    await ref.read(settingsServiceProvider).setUserName(name);
    state = state.copyWith(userName: name);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await ref.read(settingsServiceProvider).setDailyReminderEnabled(enabled);
    state = state.copyWith(dailyReminderEnabled: enabled);
  }

  Future<void> setDailyReminderTime(int hour, int minute) async {
    final s = ref.read(settingsServiceProvider);
    await s.setDailyReminderHour(hour);
    await s.setDailyReminderMinute(minute);
    state = state.copyWith(
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
    );
  }

  Future<void> setSmartRemindersEnabled(bool enabled) async {
    await ref.read(settingsServiceProvider).setSmartRemindersEnabled(enabled);
    state = state.copyWith(smartRemindersEnabled: enabled);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
        SettingsController.new);
