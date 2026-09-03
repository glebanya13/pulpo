import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../pro/pro_limits.dart';
import 'plural.dart';

/// Простой словарь переводов. Использование: `Tr.of(context).transactions`.
///
/// Локаль берётся из MaterialApp.locale через Localizations.localeOf.
class Tr {
  Tr(this._lang);
  final String _lang;

  static Tr of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return Tr(_dict.containsKey(code) ? code : 'es');
  }

  static Tr fromLang(String code) =>
      Tr(_dict.containsKey(code) ? code : 'es');

  String _get(String key) =>
      _dict[_lang]?[key] ??
      (_lang == 'uk' ? (_dict['ru']?[key]) : null) ??
      _dict['es']![key] ??
      key;

  /// Возвращает переведённое название категории по slug ('food', 'transport'...).
  /// Старые записи с именем «Comida» / «Еда» тоже находятся.
  String categoryName(String slugOrName) {
    final slug = _resolveCategorySlug(slugOrName);
    final key = 'cat_$slug';
    return _dict[_lang]?[key] ??
        (_lang == 'uk' ? (_dict['ru']?[key]) : null) ??
        _dict['es']?[key] ??
        slugOrName;
  }

  String _resolveCategorySlug(String raw) {
    if (_dict['es']?['cat_$raw'] != null) return raw;
    return _categoryNameToSlug[raw.toLowerCase()] ?? raw;
  }

  static Map<String, String>? _nameToSlugCache;

  static Map<String, String> get _categoryNameToSlug {
    final cached = _nameToSlugCache;
    if (cached != null) return cached;
    final map = <String, String>{};
    for (final lang in _dict.values) {
      for (final e in lang.entries) {
        if (!e.key.startsWith('cat_')) continue;
        map[e.value.toLowerCase()] = e.key.substring(4);
      }
    }
    return _nameToSlugCache = map;
  }

  // ─────────────────────── COMMON ───────────────────────
  String get save => _get('save');
  String get cancel => _get('cancel');
  String get delete => _get('delete');
  String get deleteTxTitle => _get('delete_tx_title');
  String get deleteTxBody => _get('delete_tx_body');
  String get txDeleted => _get('tx_deleted');
  String get undo => _get('undo');
  String get edit => _get('edit');
  String get add => _get('add');
  String get select => _get('select');
  String get search => _get('search');
  String get all => _get('all');
  String get today => _get('today');
  String get yesterday => _get('yesterday');
  String get empty => _get('empty');
  String get ok => _get('ok');
  String get done => _get('done');
  String get next => _get('next');
  String get back => _get('back');
  String get restore => _get('restore');
  String get retry => _get('retry');
  String get other => _get('other');

  // ─────────────────────── TX TYPES ───────────────────────
  String get income => _get('income');
  String get expense => _get('expense');
  String get transfer => _get('transfer');
  String get transferBetweenAccounts => _get('transfer_between');
  String get transferBetweenTitle => _get('transfer_between_title');
  String get transferExternal => _get('transfer_external');
  String get transferBetweenShort => _get('transfer_between_short');
  String get transferBetweenTab => _get('transfer_between_tab');
  String get transferExternalTab => _get('transfer_external_tab');
  String get transferBetweenHint => _get('transfer_between_hint');
  String get transferExternalHint => _get('transfer_external_hint');
  /// Compact labels for home balance quick actions.
  String get quickTransfer => _get('quick_transfer');
  String get quickExternal => _get('quick_external');
  String get monthBalance => _get('month_balance');
  String get monthNet => _get('month_net');
  String get signIn => _get('sign_in');
  String get signInApple => _get('sign_in_apple');
  String get signInGoogle => _get('sign_in_google');
  String get signInEmail => _get('sign_in_email');
  String get register => _get('register');
  String get signOut => _get('sign_out');
  String get signedInAs => _get('signed_in_as');
  String get deleteCloudAccount => _get('delete_cloud_account');
  String get deleteCloudAccountTitle => _get('delete_cloud_account_title');
  String get deleteCloudAccountBody => _get('delete_cloud_account_body');
  String get deleteCloudAccountRelogin => _get('delete_cloud_account_relogin');
  String get deleteCloudAccountFailed => _get('delete_cloud_account_failed');
  String get deleteCloudAccountOk => _get('delete_cloud_account_ok');
  String get deleteCloudConfirmIdentity =>
      _get('delete_cloud_confirm_identity');
  String get deleteCloudEnterPassword => _get('delete_cloud_enter_password');
  String get authFailed => _get('auth_failed');
  String get authInvalidEmail => _get('auth_invalid_email');
  String get authWeakPassword => _get('auth_weak_password');
  String get authWrongPassword => _get('auth_wrong_password');
  String get authUserDisabled => _get('auth_user_disabled');
  String get authTooMany => _get('auth_too_many');
  String get authCanceled => _get('auth_canceled');
  String get authEmailInUse => _get('auth_email_in_use');
  String get authNetworkError => _get('auth_network_error');
  String get cloudBackupOk => _get('cloud_backup_ok');
  String get cloudRestoreOk => _get('cloud_restore_ok');
  String get cloudEmpty => _get('cloud_empty');
  String get signInToSync => _get('sign_in_to_sync');
  String get email => _get('email');
  String get password => _get('password');
  String get firebaseNotReady => _get('firebase_not_ready');
  String get cloudBackup => _get('cloud_backup');
  String get cloudRestore => _get('cloud_restore');
  String get syncDevices => _get('sync_devices');
  String get security => _get('security');
  String get pinCode => _get('pin_code');
  String get pinCodeHint => _get('pin_code_hint');
  String get useBiometrics => _get('use_biometrics');
  String get biometricLockHint => _get('biometric_lock_hint');
  String get autoLock => _get('auto_lock');
  String get autoLockHint => _get('auto_lock_hint');
  String get biometricsUnavailable => _get('biometrics_unavailable');
  String get biometricsFailed => _get('biometrics_failed');
  String get biometricsNeedPin => _get('biometrics_need_pin');
  String get enterPin => _get('enter_pin');
  String get setPin => _get('set_pin');
  String get confirmPin => _get('confirm_pin');
  String get pinMismatch => _get('pin_mismatch');
  String get pinWrong => _get('pin_wrong');
  String get unlock => _get('unlock');
  String get unlockBiometricHint => _get('unlock_biometric_hint');
  String get exportCsv => _get('export_csv');
  String get exportExcel => _get('export_excel');
  String get exportPdf => _get('export_pdf');
  String get exportPeriod => _get('export_period');
  String get periodThisMonth => _get('period_this_month');
  String get periodLastMonth => _get('period_last_month');
  String get period3m => _get('period_3m');
  String get period6m => _get('period_6m');
  String get periodThisYear => _get('period_this_year');
  String get periodLastYear => _get('period_last_year');
  String get periodCustom => _get('period_custom');
  String get choosePeriod => _get('choose_period');
  String get restoreLocal => _get('restore_local');
  String get dataRestored => _get('data_restored');
  String get restoreFailed => _get('restore_failed');
  String get importBackupJson => _get('import_backup_json');
  String get cloudBackupFailed => _get('cloud_backup_failed');
  String get fxApproximateBalance => _get('fx_approximate_balance');
  String get importNoAccounts => _get('import_no_accounts');
  String get importNoRows => _get('import_no_rows');
  String get dataLoadDbError => _get('data_load_db_error');
  String get dataLoadNetworkError => _get('data_load_network_error');
  String get dataLoadGenericError => _get('data_load_generic_error');
  String get firebaseOfflineBanner => _get('firebase_offline_banner');
  String get dataInitFailedBanner => _get('data_init_failed_banner');
  String get accountSection => _get('account_section');

  // ─────────────────────── BOTTOM NAV / SECTIONS ───────────────────────
  String get home => _get('home');
  String get transactions => _get('transactions');
  String get transactionsSubtitle => _get('transactions_subtitle');
  String get analytics => _get('analytics');
  String get profile => _get('profile');
  String get profileAvatarChoose => _get('profile_avatar_choose');
  String get profileAvatarRemove => _get('profile_avatar_remove');
  String get profileAvatarUpdating => _get('profile_avatar_updating');
  String get profileAvatarUpdated => _get('profile_avatar_updated');
  String get profileAvatarUpdatedLocal => _get('profile_avatar_updated_local');
  String get profileAvatarRemoved => _get('profile_avatar_removed');

  // ─────────────────────── DASHBOARD ───────────────────────
  String get greetingMorning => _get('greeting_morning');
  String get greetingAfternoon => _get('greeting_afternoon');
  String get greetingEvening => _get('greeting_evening');
  String get greetingNight => _get('greeting_night');

  String greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) return greetingMorning;
    if (hour >= 12 && hour < 18) return greetingAfternoon;
    if (hour >= 18 && hour < 23) return greetingEvening;
    return greetingNight;
  }
  String get totalBalance => _get('total_balance');
  String get recentTransactions => _get('recent_transactions');
  String get seeAll => _get('see_all');
  String get emptyTransactions => _get('empty_transactions');
  String get calendar => _get('calendar');
  String get viewHistory => _get('view_history');
  String get calendarViewCalendar => _get('calendar_view_calendar');
  String get calendarViewDaily => _get('calendar_view_daily');
  String get calendarPickDate => _get('calendar_pick_date');
  String get noTxThisDay => _get('no_tx_this_day');
  String get enterAmount => _get('enter_amount');
  String get emptyFilterResults => _get('empty_filter_results');
  String get emptyFilterResultsHint => _get('empty_filter_results_hint');
  String get clearFilters => _get('clear_filters');

  /// Короткие подписи дней недели (пн-первый).
  List<String> get weekdayShort => [
        _get('weekday_mon'),
        _get('weekday_tue'),
        _get('weekday_wed'),
        _get('weekday_thu'),
        _get('weekday_fri'),
        _get('weekday_sat'),
        _get('weekday_sun'),
      ];

  // ─────────────────────── PROFILE ───────────────────────
  String get management => _get('management');
  String get recurring => _get('recurring');
  String get sectionSettings => _get('section_settings');
  String get accounts => _get('accounts');
  String get categories => _get('categories');
  String get budgets => _get('budgets');
  String get newBudget => _get('new_budget');
  String get editBudget => _get('edit_budget');
  String get deleteBudgetTitle => _get('delete_budget_title');
  String get budgetName => _get('budget_name');
  String get recurringOps => _get('recurring_ops');
  String get subscriptions => _get('subscriptions');
  String get debts => _get('debts');
  String get goals => _get('goals');
  String get newGoal => _get('new_goal');
  String get editGoal => _get('edit_goal');
  String get goalName => _get('goal_name');
  String get goalTarget => _get('goal_target');
  String get goalSaved => _get('goal_saved');
  String get goalsEmptyTitle => _get('goals_empty_title');
  String get goalsEmptyDesc => _get('goals_empty_desc');
  String get addToGoal => _get('add_to_goal');
  String get allSettings => _get('all_settings');
  String get accountsCountLabel => _get('accounts_count_label');
  String accountsCount(int n) => countPhrase(
        lang: _lang,
        n: n,
        esOne: 'cuenta',
        esMany: 'cuentas',
        enOne: 'account',
        enMany: 'accounts',
        ruOne: 'счёт',
        ruFew: 'счёта',
        ruMany: 'счетов',
      );
  String currenciesCount(int n) => countPhrase(
        lang: _lang,
        n: n,
        esOne: 'moneda',
        esMany: 'monedas',
        enOne: 'currency',
        enMany: 'currencies',
        ruOne: 'валюта',
        ruFew: 'валюты',
        ruMany: 'валют',
      );
  String peopleCount(int n) => countPhrase(
        lang: _lang,
        n: n,
        esOne: 'persona',
        esMany: 'personas',
        enOne: 'person',
        enMany: 'people',
        ruOne: 'человек',
        ruFew: 'человека',
        ruMany: 'человек',
      );
  String activeCount(int n) => countPhrase(
        lang: _lang,
        n: n,
        esOne: 'activo',
        esMany: 'activos',
        enOne: 'active',
        enMany: 'active',
        ruOne: 'активный',
        ruFew: 'активных',
        ruMany: 'активных',
      );
  String pausedCount(int n) => countPhrase(
        lang: _lang,
        n: n,
        esOne: 'en pausa',
        esMany: 'en pausa',
        enOne: 'paused',
        enMany: 'paused',
        ruOne: 'на паузе',
        ruFew: 'на паузе',
        ruMany: 'на паузе',
      );
  String daysLeftLabel(int n) => countPhrase(
        lang: _lang,
        n: n,
        esOne: 'día',
        esMany: 'días',
        enOne: 'day',
        enMany: 'days',
        ruOne: 'день',
        ruFew: 'дня',
        ruMany: 'дней',
      );
  String inDays(int n) {
    switch (_lang) {
      case 'uk':
        return 'через ${daysLeftLabel(n)}';
      case 'ru':
        return 'через ${daysLeftLabel(n)}';
      case 'en':
        return 'in ${daysLeftLabel(n)}';
      default:
        return 'en ${daysLeftLabel(n)}';
    }
  }
  String percentUsed(int pct) {
    switch (_lang) {
      case 'uk':
        return '$pct% використано';
      case 'ru':
        return '$pct% использовано';
      case 'en':
        return '$pct% used';
      default:
        return '$pct% usado';
    }
  }
  String get transactionsCount => _get('transactions_count');
  String get monthLabel => _get('month_label');
  String get baseCurrencyLabel => _get('base_currency_label');

  // ─────────────────────── SETTINGS ───────────────────────
  String get settings => _get('settings');
  String get profileSection => _get('profile_section');
  String get language => _get('language');
  String get interfaceLanguage => _get('interface_language');
  String get theme => _get('theme');
  String get themeDarkMode => _get('theme_dark_mode');
  String get themeDarkHint => _get('theme_dark_hint');
  String get dailyReminder => _get('daily_reminder');
  String dailyReminderAt(String time) =>
      _get('daily_reminder_at').replaceAll('{}', time);
  String get dailyReminderOffHint => _get('daily_reminder_off_hint');
  String get dailyReminderTime => _get('daily_reminder_time');
  String get dailyReminderCta => _get('daily_reminder_cta');
  String dailyReminderCtaOn(String time) =>
      _get('daily_reminder_cta_on').replaceAll('{}', time);
  String get dailyReminderCtaOff => _get('daily_reminder_cta_off');
  String get dailyReminderTitle => _get('daily_reminder_title');
  String get dailyReminderBody => _get('daily_reminder_body');
  String get reminderPermissionDenied => _get('reminder_permission_denied');
  String get themeLight => _get('theme_light');
  String get themeDark => _get('theme_dark');
  String get themeSystem => _get('theme_system');
  String themeLabel(String mode) {
    switch (mode) {
      case 'dark':
        return themeDark;
      case 'system':
        return themeSystem;
      default:
        return themeLight;
    }
  }
  String get baseCurrency => _get('base_currency');
  String get forTotalsReports => _get('for_totals_reports');
  String get shownInApp => _get('shown_in_app');
  String get name => _get('name');
  String get dataBackups => _get('data_backups');
  String get exportData => _get('export_data');
  String get jsonBackup => _get('json_backup');
  String get importBackup => _get('import_backup');
  String get about => _get('about');
  String get version => _get('version');
  String get errorLogsTitle => _get('error_logs_title');
  String get errorLogsSubtitle => _get('error_logs_subtitle');
  String get errorLogsEmpty => _get('error_logs_empty');
  String get errorLogsCopy => _get('error_logs_copy');
  String get errorLogsShare => _get('error_logs_share');
  String get errorLogsCopied => _get('error_logs_copied');

  String get privacyPolicy => _get('privacy_policy');
  String get termsOfUse => _get('terms_of_use');
  String get contactSupport => _get('contact_support');
  String get couldNotOpenLink => _get('could_not_open_link');
  String get enterName => _get('enter_name');
  String get yourName => _get('your_name');
  String get howToCall => _get('how_to_call');

  // ─────────────────────── ONBOARDING ───────────────────────
  String get takeControlOf => _get('take_control_of');
  String get finance => _get('finance');
  String get onboardingSubtitle => _get('onboarding_subtitle');
  String get getStarted => _get('get_started');
  String get tryDemo => _get('try_demo');
  String get continueWithoutAccount => _get('continue_without_account');
  String get guestName => _get('guest_name');
  String get orDivider => _get('or_divider');
  String get pleaseEnterName => _get('please_enter_name');
  String get setupTitle => _get('setup_title');
  String get setupSubtitle => _get('setup_subtitle');
  String get initialBalance => _get('initial_balance');
  String get currency => _get('currency');
  String get pleaseEnterEmailPassword => _get('please_enter_email_password');

  // ─────────────────────── TRANSACTIONS ───────────────────────
  String get newTransaction => _get('new_transaction');
  String get category => _get('category');
  String get account => _get('account');
  String get date => _get('date');
  String get note => _get('note');
  String get receipt => _get('receipt');
  String get receiptCamera => _get('receipt_camera');
  String get receiptGallery => _get('receipt_gallery');
  String get amount => _get('amount');
  String get emptyTransactionsList => _get('empty_transactions_list');
  String get enterNote => _get('enter_note');
  String get transactionSingular => _get('transaction_singular');

  // ─────────────────────── REPORTS ───────────────────────
  String get analyticsSubtitle => _get('analytics_subtitle');
  String get tabOverview => _get('tab_overview');
  String get tabCategories => _get('tab_categories');
  String get tabTrends => _get('tab_trends');
  String get tabFlows => _get('tab_flows');
  String expensesForPeriod(String period) =>
      _get('expenses_6_months').replaceAll('{}', period);
  String incomeForPeriod(String period) =>
      _get('income_for_period').replaceAll('{}', period);
  String incomeVsForPeriod(String period) =>
      _get('income_vs_expenses').replaceAll('{}', period);
  String get byCategoriesTitle => _get('by_categories');
  String get totalWord => _get('total_word');
  String get expensesByCategories => _get('expenses_by_categories');
  String get noExpensesThisMonth => _get('no_expenses_this_month');
  String noExpensesForPeriod(String period) =>
      _get('no_expenses_period').replaceAll('{}', period);
  String noIncomeForPeriod(String period) =>
      _get('no_income_period').replaceAll('{}', period);
  String get expenseThisMonth => _get('expense_this_month');
  String get expenseToday => _get('expense_today');
  String get vsPrevMonth => _get('vs_prev_month');
  String get vsYesterday => _get('vs_yesterday');
  String get cashFlow => _get('cash_flow');
  String get incomeUpper => _get('income_upper');
  String get expenseUpper => _get('expense_upper');
  String get netUpper => _get('net_upper');
  String get topIncomeSources => _get('top_income_sources');
  String get topExpenses => _get('top_expenses');

  // ─────────────────────── ACCOUNTS ───────────────────────
  String get myAccounts => _get('my_accounts');
  String get myAccount => _get('my_account');
  String get netWorth => _get('net_worth');
  String get inRealtime => _get('in_realtime');
  String get history12Weeks => _get('history_12_weeks');
  String get offlineFirstTag => _get('offline_first_tag');
  String get madeInSpainLine1 => _get('made_in_spain_line1');
  String get madeInSpainLine2 => _get('made_in_spain_line2');
  String get aboutSpainTitle => _get('about_spain_title');
  String get aboutSpainParagraph1 => _get('about_spain_p1');
  String get aboutSpainParagraph2 => _get('about_spain_p2');
  String get aboutSpainClosing1 => _get('about_spain_closing1');
  String get aboutSpainClosing2 => _get('about_spain_closing2');
  String txIdLabel(int id) => _get('tx_id').replaceAll('{}', '$id');
  String get bankAccounts => _get('bank_accounts');
  String get cashWallets => _get('cash_wallets');
  String get addAccount => _get('add_account');
  String get newAccount => _get('new_account');
  String get editAccount => _get('edit_account');
  String get deleteAccountTitle => _get('delete_account_title');
  String get deleteAccountBody => _get('delete_account_body');
  String get accountName => _get('account_name');
  String get includeInTotal => _get('include_in_total');
  String get resetAllData => _get('reset_all_data');
  String get resetAllDataSubtitle => _get('reset_all_data_subtitle');
  String get resetAllDataTitle => _get('reset_all_data_title');
  String get resetAllDataBody => _get('reset_all_data_body');
  String get resetSuccess => _get('reset_success');
  String get accountType => _get('account_type');

  // ─────────────────────── TRANSACTION LIST ───────────────────────
  String get filterAll => _get('filter_all');
  String get filter => _get('filter');
  String get filterAccount => _get('filter_account');
  String get filterCategory => _get('filter_category');

  // ─────────────────────── ONBOARDING BUTTONS ───────────────────────
  String get skip => _get('skip');
  String get finishSetup => _get('finish_setup');

  // ─────────────────────── ACCOUNT TYPES ───────────────────────
  String get accountTypeCash => _get('account_type_cash');
  String get accountTypeCard => _get('account_type_card');
  String get accountTypeBank => _get('account_type_bank');
  String get accountTypeEWallet => _get('account_type_ewallet');
  String get accountTypeCrypto => _get('account_type_crypto');
  String get accountTypeInvestment => _get('account_type_investment');
  String get accountTypeLoan => _get('account_type_loan');

  // ─────────────────────── TRANSACTION DETAIL ───────────────────────
  String get txNotFound => _get('tx_not_found');
  String get txLocation => _get('tx_location');
  String get txDuplicate => _get('tx_duplicate');
  String get incomeLower => _get('income_lower');
  String get expenseLower => _get('expense_lower');
  String get transferLower => _get('transfer_lower');

  // ─────────────────────── TRANSFER ───────────────────────
  String get transferFrom => _get('transfer_from');
  String get transferTo => _get('transfer_to');
  String get transferSending => _get('transfer_sending');
  String get transferRecipientGets => _get('transfer_recipient_gets');
  String get exchangeRate => _get('exchange_rate');
  String get ratePrefix => _get('rate_prefix'); // e.g. "Rate: 1 "
  String get fee => _get('fee');
  String get confirm => _get('confirm');
  String get selectAccount => _get('select_account');
  String get balancePrefix => _get('balance_prefix'); // "Saldo: "

  // ─────────────────────── CATEGORIES SCREEN ───────────────────────
  String get newCategory => _get('new_category');
  String get editCategory => _get('edit_category');
  String get deleteCategoryTitle => _get('delete_category_title');
  String get colorLabel => _get('color_label');
  String get iconLabel => _get('icon_label');
  String get titleLabel => _get('title_label');

  // ─────────────────────── DEBTS ───────────────────────
  String get iOwe => _get('i_owe');
  String get owedToMe => _get('owed_to_me');
  String get newDebt => _get('new_debt');
  String get editDebt => _get('edit_debt');
  String get deleteDebtTitle => _get('delete_debt_title');
  String get toFromWhom => _get('to_from_whom');
  String get withoutDueDate => _get('without_due_date');
  String get dueDateLabel => _get('due_date_label');
  String get duePrefix => _get('due_prefix'); // "Vence: "
  String get overdue => _get('overdue');
  String get dayShort => _get('day_short'); // 'd' / 'дн'
  String get paidOfTemplate => _get('paid_of_template'); // "Paid {p} of {t}"
  String get repayment => _get('repayment');
  String get debtsEmptyTitle => _get('debts_empty_title');
  String get debtsEmptyDesc => _get('debts_empty_desc');
  String get personsWord => _get('persons_word');
  String get activePlural => _get('active_plural'); // "активных"/"activos"

  // ─────────────────────── SUBSCRIPTIONS ───────────────────────
  String get perMonth => _get('per_month');
  String get perYear => _get('per_year');
  String get subsEmptyTitle => _get('subs_empty_title');
  String get subsEmptyDesc => _get('subs_empty_desc');
  String get nextPaymentLabel => _get('next_payment_label');
  String get allSubscriptions => _get('all_subscriptions');
  String get newSubscription => _get('new_subscription');
  String get editSubscription => _get('edit_subscription');
  String get deleteSubTitle => _get('delete_sub_title');
  String get serviceName => _get('service_name');
  String get periodicity => _get('periodicity');
  String get monthlyLabel => _get('monthly_label');
  String get yearlyLabel => _get('yearly_label');
  String get nextPaymentPrefix => _get('next_payment_prefix');
  String get inDaysShort => _get('in_days_short'); // "en {n} días" — {n} placeholder

  // ─────────────────────── RECURRING ───────────────────────
  String get activeTab => _get('active_tab');
  String get pausedTab => _get('paused_tab');
  String get pausedPlural => _get('paused_plural'); // "на паузе" / "en pausa"
  String get rulesEmptyTitle => _get('rules_empty_title');
  String get rulesEmptyDesc => _get('rules_empty_desc');
  String get newRule => _get('new_rule');
  String get editRule => _get('edit_rule');
  String get deleteRuleTitle => _get('delete_rule_title');
  String get frequencyLabel => _get('frequency_label');
  String get freqDaily => _get('freq_daily');
  String get freqWeekly => _get('freq_weekly');
  String get nextRunPrefix => _get('next_run_prefix');

  // ─────────────────────── REPORTS TITLES ───────────────────────
  String get byCategoriesMonthPrefix => _get('by_categories_month_prefix'); // "Por categoría · "
  String get expensesByCategoriesMonthPrefix =>
      _get('expenses_by_categories_month_prefix');
  String get incomeByCategoriesMonthPrefix =>
      _get('income_by_categories_month_prefix');
  String get cashFlowMonthPrefix => _get('cash_flow_month_prefix');

  // ─────────────────────── CURRENCY PICKER ───────────────────────
  String get searchCurrency => _get('search_currency');
  String get popularUpper => _get('popular_upper');
  String get cryptoUpper => _get('crypto_upper');

  // ─────────────────────── COMMON / ERROR ───────────────────────
  String get errorTitle => _get('error_title');
  String get errorFatalBody => _get('error_fatal_body');
  String get errorFatalHint => _get('error_fatal_hint');
  String get addAccountFirst => _get('add_account_first');
  String get accountNotFound => _get('account_not_found');
  String get backupCreated => _get('backup_created');
  String get autoBackup => _get('auto_backup');
  String get autoBackupDesc => _get('auto_backup_desc');
  String get createNow => _get('create_now');
  String get localBackupsUpper => _get('local_backups_upper');
  String get noBackupsTitle => _get('no_backups_title');
  String get noBackupsDesc => _get('no_backups_desc');
  String get emptyBudgetsTitle => _get('empty_budgets_title');
  String get spentThisMonth => _get('spent_this_month');
  String get outOfBudgetTemplate => _get('out_of_budget_template'); // "из {} бюджета"
  String get creditLimitPrefix => _get('credit_limit_prefix'); // "Лимит: "
  String get creditLimit => _get('credit_limit');
  String get creditLimitHint => _get('credit_limit_hint');
  String get autoCloudBackup => _get('auto_cloud_backup');
  String get autoCloudBackupDesc => _get('auto_cloud_backup_desc');
  String get lastSyncPrefix => _get('last_sync_prefix');
  String get neverSynced => _get('never_synced');
  String get cloudRestoreTitle => _get('cloud_restore_title');
  String get cloudRestoreBody => _get('cloud_restore_body');
  String get cloudRestoreUseCloud => _get('cloud_restore_use_cloud');
  String get cloudRestoreKeepLocal => _get('cloud_restore_keep_local');
  String get budgetCategories => _get('budget_categories');
  String get budgetCategoriesAll => _get('budget_categories_all');
  String get budgetRollover => _get('budget_rollover');
  String get budgetRolloverDesc => _get('budget_rollover_desc');
  String get pickDateRange => _get('pick_date_range');
  String get dateFrom => _get('date_from');
  String get dateTo => _get('date_to');
  String get exportPdfDate => _get('export_pdf_date');
  String get exportPdfType => _get('export_pdf_type');
  String get exportPdfAmount => _get('export_pdf_amount');
  String get exportPdfNote => _get('export_pdf_note');
  String get exportTotalIncome => _get('export_total_income');
  String get exportTotalExpense => _get('export_total_expense');
  String get exportNet => _get('export_net');
  String get exportFailed => _get('export_failed');
  String get formIncomplete => _get('form_incomplete');
  String get tagsLabel => _get('tags_label');
  String get tagsHint => _get('tags_hint');
  String proExpires(String date) => _get('pro_expires').replaceAll('{}', date);
  String proValidUntil(String date) =>
      _get('pro_valid_until').replaceAll('{}', date);
  String get proExpiresLoading => _get('pro_expires_loading');
  String proDaysLeft(int n) => _get('pro_days_left').replaceAll('{}', '$n');
  String get proManageSubscription => _get('pro_manage_subscription');
  String get sharedBudgetTitle => _get('shared_budget_title');
  String get sharedBudgetSubtitle => _get('shared_budget_subtitle');
  String get sharedBudgetCreate => _get('shared_budget_create');
  String get sharedBudgetJoin => _get('shared_budget_join');
  String get sharedBudgetJoinHint => _get('shared_budget_join_hint');
  String get sharedBudgetInviteCode => _get('shared_budget_invite_code');
  String get sharedBudgetSignIn => _get('shared_budget_sign_in');
  String get sharedBudgetEven => _get('shared_budget_even');
  String get sharedBudgetSyncExpenses => _get('shared_budget_sync');
  String get sharedBudgetLeave => _get('shared_budget_leave');
  String get sharedBudgetLeaveTitle => _get('shared_budget_leave_title');
  String get sharedBudgetLeaveBody => _get('shared_budget_leave_body');
  String get sharedBudgetCodeCopied => _get('shared_budget_code_copied');
  String get sharedBudgetInvalidCode => _get('shared_budget_invalid_code');
  String get sharedBudgetFull => _get('shared_budget_full');
  String get sharedBudgetAlreadyJoined => _get('shared_budget_already_joined');
  String get sharedBudgetFailed => _get('shared_budget_failed');
  String get sharedBudgetWaitingPartner => _get('shared_budget_waiting');
  String get youLabel => _get('you_label');
  String get widgetBudgetLeft => _get('widget_budget_left');
  String get widgetMonthExpense => _get('widget_month_expense');
  String sharedBudgetSynced(int n) =>
      _get('shared_budget_synced').replaceAll('{}', '$n');
  String sharedBudgetPartnerOwes(String amount) =>
      _get('shared_budget_partner_owes').replaceAll('{}', amount);
  String sharedBudgetYouOwe(String amount) =>
      _get('shared_budget_you_owe').replaceAll('{}', amount);
  String get selectShort => _get('select_short'); // "Выбрать"
  String get enterNoteHint => _get('enter_note_hint'); // "Введите заметку..."
  String get backupsShort => _get('backups_short'); // "Бэкапы"

  String get proTitle => _get('pro_title');
  String get proSubtitle => _get('pro_subtitle');
  String get proFeaturesHeading => _get('pro_features_heading');
  String get proPaywallTrialFootnote => _get('pro_paywall_trial_footnote');
  String get proStartFreeTrial => _get('pro_start_free_trial');
  String proTrialBadge(int days) =>
      _get('pro_trial_badge').replaceAll('{}', '$days');
  String proDiscountBadge(int pct) =>
      _get('pro_discount_badge').replaceAll('{}', '$pct');
  String get proAllFeatures => _get('pro_all_features');
  List<String> get proFeatureBullets => [
        _get('pro_feature_ai_chat'),
        _get('pro_feature_ai_quality'),
        _get('pro_feature_ai_receipts'),
        _get('pro_feature_ai_voice'),
        _get('pro_feature_accounts'),
        _get('pro_feature_budgets'),
        _get('pro_feature_goals'),
        _get('pro_feature_debts'),
        _get('pro_feature_stats'),
        _get('pro_feature_trends'),
        _get('pro_feature_cashflow'),
        _get('pro_feature_shared_budget'),
        _get('pro_feature_reminder_payments'),
        _get('pro_feature_reminder_subs'),
        _get('pro_feature_reminder_goals'),
        _get('pro_feature_cloud_backup'),
        _get('pro_feature_sync'),
        _get('pro_feature_export_excel'),
        _get('pro_feature_export_pdf'),
        _get('pro_feature_import_csv'),
      ];
  String get proCtaSubtitle => _get('pro_cta_subtitle');
  String get proGo => _get('pro_go');
  String get proRestore => _get('pro_restore');
  String get proSignInRequired => _get('pro_sign_in_required');
  String get proRestoreEmpty => _get('pro_restore_empty');
  String get proRestoreOk => _get('pro_restore_ok');
  String get proLegalNotice {
    if (!kIsWeb && Platform.isAndroid) {
      return _get('pro_legal_notice_android');
    }
    return _get('pro_legal_notice');
  }
  String get proYearly => _get('pro_yearly');
  String get proMonthly => _get('pro_monthly');
  String get proSemiAnnual => _get('pro_semi_annual');
  String get proYearlySave => _get('pro_yearly_save');
  String proYearlySavePercent(int pct) =>
      _get('pro_yearly_save_pct').replaceAll('{}', '$pct');
  String get proTrial => _get('pro_trial');
  String proTrialDays(int days) =>
      _get('pro_trial_days').replaceAll('{}', '$days');
  String cloudRestoreRemoteMeta(String date, int accounts, int txs) =>
      _get('cloud_restore_remote_meta')
          .replaceAll('{date}', date)
          .replaceAll('{a}', '$accounts')
          .replaceAll('{t}', '$txs');
  String cloudRestoreLocalMeta(int accounts, int txs) =>
      _get('cloud_restore_local_meta')
          .replaceAll('{a}', '$accounts')
          .replaceAll('{t}', '$txs');
  String get cloudRestoreMerge => _get('cloud_restore_merge');
  String get cloudRestoreMergeHint => _get('cloud_restore_merge_hint');
  String get cloudRestoreMergedOk => _get('cloud_restore_merged_ok');
  String get deleteCloudResetLocal => _get('delete_cloud_reset_local');
  String get importMapColumns => _get('import_map_columns');
  String get importColDate => _get('import_col_date');
  String get importColAmount => _get('import_col_amount');
  String get importColType => _get('import_col_type');
  String get importColCurrency => _get('import_col_currency');
  String get importColNote => _get('import_col_note');
  String get importColNone => _get('import_col_none');
  String get importSampleRows => _get('import_sample_rows');
  String get proActive => _get('pro_active');
  String get proActiveShort => _get('pro_active_short');
  String get proBuyFailed => _get('pro_buy_failed');
  String get proStoreEmpty => _get('pro_store_empty');
  String get proDebugUnlock => _get('pro_debug_unlock');
  String get aiRecognizeReceipt => _get('ai_recognize_receipt');
  String get aiVoiceEntry => _get('ai_voice_entry');
  String get aiVoiceEmptyTitle => _get('ai_voice_empty_title');
  String get aiVoiceEmptyHint => _get('ai_voice_empty_hint');
  String get aiVoiceHint => _get('ai_voice_hint');
  String get aiVoiceConfirmTitle => _get('ai_voice_confirm_title');
  String aiVoiceConfirmCount(int n) =>
      _get('ai_voice_confirm_count').replaceAll('{}', '$n');
  String get aiVoiceApprove => _get('ai_voice_approve');
  String aiVoiceSaved(int n) =>
      _get('ai_voice_saved').replaceAll('{}', '$n');
  String get aiListening => _get('ai_listening');
  String get aiConfirmTranscript => _get('ai_confirm_transcript');
  String get aiUseTranscript => _get('ai_use_transcript');
  String aiCategorySuggest(String name) =>
      _get('ai_category_suggest').replaceAll('{}', name);
  String get aiApplyCategory => _get('ai_apply_category');
  String get aiInsightTitle => _get('ai_insight_title');
  String get aiInsightGenerate => _get('ai_insight_generate');
  String get aiInsightHint => _get('ai_insight_hint');
  String get aiChatTitle => _get('ai_chat_title');
  String get aiChatHint => _get('ai_chat_hint');
  String get aiChatPlaceholder => _get('ai_chat_placeholder');
  String get aiChatWelcome => _get('ai_chat_welcome');
  String get aiClearChat => _get('ai_clear_chat');
  String get aiClearChatTitle => _get('ai_clear_chat_title');
  String get aiClearChatBody => _get('ai_clear_chat_body');
  String get aiAssistantEyebrow => _get('ai_assistant_eyebrow');
  String get aiRecording => _get('ai_recording');
  String get aiChatReceiptSent => _get('ai_chat_receipt_sent');
  String get aiReceiptUnreadable => _get('ai_receipt_unreadable');
  String aiAssistantRecorded(int count, String totalFormatted) =>
      _get('ai_assistant_recorded')
          .replaceFirst('{}', '$count')
          .replaceFirst('{}', totalFormatted);
  String aiAssistantReceiptSaved(String amount) =>
      _get('ai_assistant_receipt_saved').replaceAll('{}', amount);
  String get aiBusy => _get('ai_busy');
  String get aiParsing => _get('ai_parsing');
  String get aiFailed => _get('ai_failed');
  String get aiBlocked => _get('ai_blocked');
  String get aiEmptyResponse => _get('ai_empty_response');
  String get aiInvalidResponse => _get('ai_invalid_response');
  String get aiSpeechUnavailable => _get('ai_speech_unavailable');
  String get aiApiNotEnabled => _get('ai_api_not_enabled');
  String get aiPermissionDenied => _get('ai_permission_denied');
  String get aiQuotaExceeded => _get('ai_quota_exceeded');
  String get aiBillingDepleted => _get('ai_billing_depleted');
  String get aiFilled => _get('ai_filled');
  String get aiEnergyEmpty => _get('ai_energy_empty');
  String aiEnergyHint(int units) =>
      _get('ai_energy_hint').replaceAll('{}', '$units');
  String get proBadge => _get('pro_badge');
  String get importCsv => _get('import_csv');
  String get importCsvHint => _get('import_csv_hint');
  String get importPickFile => _get('import_pick_file');
  String importPreview(int n, int skipped) => _get('import_preview')
      .replaceAll('{n}', '$n')
      .replaceAll('{s}', '$skipped');
  String get importConfirm => _get('import_confirm');
  String get importFailed => _get('import_failed');
  String importDone(int n) => _get('import_done').replaceAll('{}', '$n');
  String importDuplicatesSkipped(int n) =>
      _get('import_duplicates_skipped').replaceAll('{}', '$n');
  String get remindersPageHint => _get('reminders_page_hint');
  String get dailyReminderSection => _get('daily_reminder_section');
  String get smartReminders => _get('smart_reminders');
  String get smartRemindersHint => _get('smart_reminders_hint');
  String get smartRemindersDesc => _get('smart_reminders_desc');
  String get smartDebtTitle => _get('smart_debt_title');
  String smartDebtBody(String name) =>
      _get('smart_debt_body').replaceAll('{}', name);
  String get smartSubTitle => _get('smart_sub_title');
  String smartSubBody(String name) =>
      _get('smart_sub_body').replaceAll('{}', name);
  String get smartGoalTitle => _get('smart_goal_title');
  String smartGoalBody(String name) =>
      _get('smart_goal_body').replaceAll('{}', name);
  String get smartBudgetTitle => _get('smart_budget_title');
  String smartBudgetBody(String name, String pct) =>
      _get('smart_budget_body').replaceFirst('{}', name).replaceFirst('{}', pct);

  String paywallBody(ProGate gate) => switch (gate) {
        ProGate.accounts => _get('pro_gate_accounts'),
        ProGate.goals => _get('pro_gate_goals'),
        ProGate.budgets => _get('pro_gate_budgets'),
        ProGate.debts => _get('pro_gate_debts'),
        ProGate.subscriptions => _get('pro_gate_subscriptions'),
        ProGate.recurring => _get('pro_gate_recurring'),
        ProGate.analytics => _get('pro_gate_analytics'),
        ProGate.trends => _get('pro_gate_trends'),
        ProGate.flows => _get('pro_gate_flows'),
        ProGate.currencies => _get('pro_gate_currencies'),
        ProGate.cloud => _get('pro_gate_cloud'),
        ProGate.sync => _get('pro_gate_sync'),
        ProGate.excel => _get('pro_gate_excel'),
        ProGate.pdf => _get('pro_gate_pdf'),
        ProGate.reminders => _get('pro_gate_reminders'),
        ProGate.importCsv => _get('pro_gate_import'),
        ProGate.sharedBudget => _get('pro_gate_shared_budget'),
        ProGate.ai => _get('pro_gate_ai'),
        ProGate.generic => _get('pro_subtitle'),
      };

  /// Локализованный лейбл типа счёта — enum не знает про context, поэтому helper здесь.
  String accountTypeLabel(int index) {
    switch (index) {
      case 0:
        return accountTypeCash;
      case 1:
        return accountTypeCard;
      case 2:
        return accountTypeBank;
      case 3:
        return accountTypeEWallet;
      case 4:
        return accountTypeCrypto;
      case 5:
        return accountTypeInvestment;
      case 6:
        return accountTypeLoan;
      default:
        return '';
    }
  }

  /// Форматирует "{n} {word}" — универсально для активных/пауз/человек.
  String withCount(int n, String word) => '$n $word';

  static const Map<String, Map<String, String>> _dict = {
    'es': {
      // common
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'delete_tx_title': '¿Eliminar transacción?',
      'delete_tx_body': 'Esta acción no se puede deshacer.',
      'tx_deleted': 'Transacción eliminada',
      'undo': 'Deshacer',
      'edit': 'Editar',
      'add': 'Añadir',
      'select': 'Seleccionar',
      'search': 'Buscar',
      'all': 'Todos',
      'today': 'Hoy',
      'yesterday': 'Ayer',
      'empty': 'Vacío',
      'ok': 'OK',
      'done': 'Listo',
      'next': 'Siguiente',
      'back': 'Atrás',
      'restore': 'Restaurar',
      'retry': 'Reintentar',
      'other': 'Otro',
      // tx types
      'income': 'Ingreso',
      'expense': 'Gasto',
      'transfer': 'Transferencia',
      // nav
      'home': 'Inicio',
      'transactions': 'Transacciones',
      'transactions_subtitle': 'Ingresos, gastos y transferencias',
      'analytics': 'Analítica',
      'profile': 'Perfil',
      // dashboard
      'greeting_morning': 'Buenos días 👋',
      'greeting_afternoon': 'Buenas tardes 👋',
      'greeting_evening': 'Buenas noches 👋',
      'greeting_night': 'Buenas noches 🌙',
      'total_balance': 'SALDO TOTAL',
      'recent_transactions': 'Transacciones recientes',
      'see_all': 'Ver todo →',
      'empty_transactions': 'Aún no hay transacciones. Toca + para añadir.',
      'calendar': 'Calendario',
      'view_history': 'Ver historial →',
      'calendar_view_calendar': 'Calendario',
      'calendar_view_daily': 'Diario',
      'calendar_pick_date': 'Elegir fecha',
      'no_tx_this_day': 'Sin transacciones este día',
      'enter_amount': 'Introduce un importe',
      'empty_filter_results': 'Sin resultados',
      'empty_filter_results_hint':
          'Prueba otros filtros o la búsqueda.',
      'clear_filters': 'Limpiar filtros',
      'weekday_mon': 'L',
      'weekday_tue': 'M',
      'weekday_wed': 'X',
      'weekday_thu': 'J',
      'weekday_fri': 'V',
      'weekday_sat': 'S',
      'weekday_sun': 'D',
      // profile
      'profile_avatar_choose': 'Elegir foto',
      'profile_avatar_remove': 'Quitar foto',
      'profile_avatar_updating': 'Actualizando foto…',
      'profile_avatar_updated': 'Foto de perfil actualizada',
      'profile_avatar_updated_local': 'Foto guardada en el dispositivo',
      'profile_avatar_removed': 'Foto de perfil eliminada',
      'management': 'Panel de control',
      'recurring': 'RECURRENTE',
      'section_settings': 'AJUSTES',
      'accounts': 'Cuentas',
      'categories': 'Categorías',
      'budgets': 'Presupuestos',
      'new_budget': 'Nuevo presupuesto',
      'edit_budget': 'Editar presupuesto',
      'delete_budget_title': '¿Eliminar presupuesto?',
      'budget_name': 'Nombre del presupuesto',
      'recurring_ops': 'Operaciones recurrentes',
      'subscriptions': 'Suscripciones',
      'debts': 'Deudas',
      'goals': 'Metas',
      'new_goal': 'Nueva meta',
      'edit_goal': 'Editar meta',
      'goal_name': 'Nombre',
      'goal_target': 'Objetivo',
      'goal_saved': 'Ahorrado',
      'goals_empty_title': 'Sin metas',
      'goals_empty_desc': 'Crea una meta de ahorro y sigue el progreso.',
      'add_to_goal': 'Añadir ahorro',
      'all_settings': 'Todos los ajustes',
      'accounts_count_label': 'cuentas',
      'transactions_count': 'transacciones',
      'month_label': 'este mes',
      'base_currency_label': 'Moneda principal',
      // settings
      'settings': 'Ajustes',
      'profile_section': 'Perfil',
      'language': 'Idioma',
      'interface_language': 'Idioma de la interfaz',
      'theme': 'Tema',
      'theme_dark_mode': 'Modo oscuro',
      'theme_dark_hint': 'Activar tema nocturno',
      'daily_reminder': 'Recordatorios diarios automáticos',
      'daily_reminder_at': 'Aviso a las {} para anotar ingresos y gastos',
      'daily_reminder_off_hint': 'Activa el interruptor y elige la hora',
      'daily_reminder_time': 'Hora',
      'daily_reminder_cta': 'Notificaciones',
      'daily_reminder_cta_on': 'Cada día a las {}',
      'daily_reminder_cta_off': 'Configurar horario',
      'daily_reminder_title': 'Recordatorio diario ⏰',
      'daily_reminder_body':
          'Mantén tus finanzas bajo control registrando tus transacciones del día.',
      'reminder_permission_denied':
          'Activa las notificaciones en Ajustes para recibir el recordatorio.',
      'theme_light': 'Claro',
      'theme_dark': 'Oscuro',
      'theme_system': 'Como el sistema',
      'base_currency': 'Moneda principal',
      'for_totals_reports': 'Para totales e informes',
      'shown_in_app': 'Se muestra en la aplicación',
      'name': 'Nombre',
      'data_backups': 'Datos y copias',
      'export_data': 'Exportar datos',
      'json_backup': 'Copia JSON',
      'import_backup': 'Importar copia',
      'about': 'Acerca de',
      'version': 'Versión',
      'error_logs_title': 'Registro de errores',
      'error_logs_subtitle':
          'Solo se guardan fallos (IA, red, etc.). Útil para diagnóstico.',
      'error_logs_empty': 'Todavía no hay errores registrados.',
      'error_logs_copy': 'Copiar',
      'error_logs_share': 'Compartir',
      'error_logs_copied': 'Errores copiados',
      'privacy_policy': 'Política de privacidad',
      'terms_of_use': 'Términos de uso',
      'contact_support': 'Soporte',
      'could_not_open_link': 'No se pudo abrir el enlace',
      'enter_name': 'Introduce tu nombre',
      'your_name': 'Tu nombre',
      'how_to_call': '¿Cómo debemos llamarte?',
      // onboarding
      'take_control_of': 'Toma el\ncontrol de tus',
      'finance': 'finanzas',
      'onboarding_subtitle':
          'Controla gastos, planifica presupuestos y alcanza metas. Todo sin conexión.',
      'get_started': 'Comenzar →',
      'try_demo': 'Probar con datos de ejemplo',
      'continue_without_account': 'Continuar sin iniciar sesión',
      'guest_name': 'Invitado',
      'or_divider': 'o',
      'please_enter_name': 'Por favor, introduce tu nombre',
      'please_enter_email_password': 'Introduce email y contraseña',
      'setup_title': 'Un poco sobre ti',
      'setup_subtitle':
          'Entra con tu cuenta o continúa como invitado. Nombre y moneda se guardan en el dispositivo.',
      'initial_balance': 'Saldo inicial',
      'currency': 'Moneda',
      // transactions
      'new_transaction': 'Nueva transacción',
      'category': 'Categoría',
      'account': 'Cuenta',
      'date': 'Fecha',
      'note': 'Nota',
      'receipt': 'Recibo',
      'receipt_camera': 'Cámara',
      'receipt_gallery': 'Galería',
      'amount': 'Importe',
      'empty_transactions_list': 'Sin transacciones.',
      'enter_note': 'Escribe una nota',
      'transaction_singular': 'Transacción',
      // reports
      'analytics_subtitle': 'A dónde va el dinero',
      'tab_overview': 'Resumen',
      'tab_categories': 'Categorías',
      'tab_trends': 'Tendencias',
      'tab_flows': 'Flujos',
      'expenses_6_months': 'Gastos · {}',
      'income_for_period': 'Ingresos · {}',
      'by_categories': 'Por categoría',
      'total_word': 'total',
      'expenses_by_categories': 'Gastos por categoría',
      'no_expenses_this_month': 'Sin gastos este mes',
      'no_expenses_period': 'Sin gastos · {}',
      'no_income_period': 'Sin ingresos · {}',
      'income_vs_expenses': 'Ingresos vs Gastos · {}',
      'expense_this_month': 'Gasto de este mes',
      'expense_today': 'Gasto de hoy',
      'vs_prev_month': 'vs mes anterior',
      'vs_yesterday': 'vs ayer',
      'cash_flow': 'Flujo de caja',
      'income_upper': 'INGRESO',
      'expense_upper': 'GASTO',
      'net_upper': 'NETO',
      'top_income_sources': 'Principales fuentes de ingreso',
      'top_expenses': 'Principales gastos',
      // accounts
      'my_accounts': 'Mis cuentas',
      'my_account': 'Mi cuenta',
      'net_worth': 'PATRIMONIO NETO',
      'in_realtime': '↑ en tiempo real',
      'history_12_weeks': '12 semanas',
      'offline_first_tag': 'Monedero · offline-first',
      'made_in_spain_line1': 'Hecho en España 🇪🇸',
      'made_in_spain_line2': 'Para los que hablamos español.',
      'about_spain_title': 'Hecho en España 🇪🇸',
      'about_spain_p1':
          'Creamos esta app porque queríamos una forma sencilla de gestionar nuestro dinero, hecha para nuestra manera de hablar y vivir.',
      'about_spain_p2': 'Ahora queremos compartirla contigo.',
      'about_spain_closing1': 'No es una app traducida al español.',
      'about_spain_closing2': 'Es una app creada en español. 🇪🇸',
      'tx_id': 'ID: txn_{}',
      'bank_accounts': 'Cuentas bancarias',
      'cash_wallets': 'Efectivo y carteras',
      'add_account': 'Añadir cuenta',
      'new_account': 'Nueva cuenta',
      'edit_account': 'Editar cuenta',
      'delete_account_title': '¿Eliminar cuenta?',
      'delete_account_body':
          'Se eliminarán todas las transacciones de esta cuenta. Esta acción no se puede deshacer.',
      'account_name': 'Nombre',
      'include_in_total': 'Incluir en el total',
      'reset_all_data': 'Restablecer datos locales',
      'reset_all_data_subtitle':
          'Borra cuentas y operaciones en este dispositivo. No elimina la cuenta en la nube.',
      'reset_all_data_title': '¿Borrar datos de este dispositivo?',
      'reset_all_data_body':
          'Se eliminarán cuentas, transacciones, categorías, presupuestos, deudas, metas y suscripciones en este teléfono. Ajustes y la cuenta en la nube no se tocan. No se puede deshacer.',
      'reset_success': 'Datos eliminados',
      'account_type': 'Tipo',
      // filters
      'filter_all': 'Todos',
      'filter': 'Filtro',
      'filter_account': 'Cuenta',
      'filter_category': 'Categoría',
      // onboarding buttons
      'skip': 'Omitir',
      'finish_setup': 'Listo',
      // categories
      'cat_food': 'Comida',
      'cat_transport': 'Transporte',
      'cat_housing': 'Vivienda',
      'cat_health': 'Salud',
      'cat_entertainment': 'Ocio',
      'cat_clothing': 'Ropa',
      'cat_communication': 'Comunicación',
      'cat_education': 'Educación',
      'cat_gifts': 'Regalos',
      'cat_beauty': 'Belleza',
      'cat_other_expense': 'Otro',
      'cat_salary': 'Salario',
      'cat_freelance': 'Freelance',
      'cat_gift_income': 'Regalo',
      'cat_investments': 'Inversiones',
      'cat_other_income': 'Otro',
      // account types
      'account_type_cash': 'Efectivo',
      'account_type_card': 'Tarjeta',
      'account_type_bank': 'Cuenta bancaria',
      'account_type_ewallet': 'Cartera electrónica',
      'account_type_crypto': 'Cripto',
      'account_type_investment': 'Inversión',
      'account_type_loan': 'Préstamo',
      // tx detail
      'tx_not_found': 'Transacción no encontrada',
      'tx_location': 'Lugar',
      'tx_duplicate': 'Duplicar',
      'income_lower': 'ingreso',
      'expense_lower': 'gasto',
      'transfer_lower': 'transferencia',
      // transfer
      'transfer_from': 'Desde',
      'transfer_to': 'Hacia',
      'transfer_sending': 'Envías',
      'transfer_recipient_gets': 'El destinatario recibe',
      'exchange_rate': 'Tipo de cambio',
      'rate_prefix': 'Tasa: 1 ',
      'fee': 'Comisión',
      'confirm': 'Confirmar',
      'select_account': 'Seleccionar cuenta',
      'balance_prefix': 'Saldo: ',
      // categories screen
      'new_category': 'Nueva categoría',
      'edit_category': 'Editar categoría',
      'delete_category_title': '¿Eliminar categoría?',
      'color_label': 'Color',
      'icon_label': 'Ícono',
      'title_label': 'Título',
      // debts
      'i_owe': 'Yo debo',
      'owed_to_me': 'Me deben',
      'new_debt': 'Nueva deuda',
      'edit_debt': 'Editar deuda',
      'delete_debt_title': '¿Eliminar deuda?',
      'to_from_whom': 'A quién / de quién',
      'without_due_date': 'Sin fecha',
      'due_date_label': 'Fecha de vencimiento',
      'due_prefix': 'Vence: ',
      'overdue': 'vencido',
      'day_short': 'd',
      'paid_of_template': 'Pagado {p} de {t}',
      'repayment': 'Pago',
      'debts_empty_title': 'Sin deudas',
      'debts_empty_desc':
          'Añade una deuda para llevar el control de préstamos y devoluciones.',
      'persons_word': 'personas',
      'active_plural': 'activos',
      // subscriptions
      'per_month': 'Al mes',
      'per_year': 'Al año',
      'subs_empty_title': 'Sin suscripciones',
      'subs_empty_desc':
          'Añade Netflix, Spotify y otros servicios\npara ver el gasto total.',
      'next_payment_label': 'Próximo pago',
      'all_subscriptions': 'Todas las suscripciones',
      'new_subscription': 'Nueva suscripción',
      'edit_subscription': 'Editar suscripción',
      'delete_sub_title': '¿Eliminar suscripción?',
      'service_name': 'Nombre del servicio',
      'periodicity': 'Periodicidad',
      'monthly_label': 'Mensual',
      'yearly_label': 'Anual',
      'next_payment_prefix': 'Próximo pago: ',
      'in_days_short': 'en {n} días',
      // recurring
      'active_tab': 'Activas',
      'paused_tab': 'Pausadas',
      'paused_plural': 'en pausa',
      'rules_empty_title': 'Sin operaciones recurrentes',
      'rules_empty_desc':
          'Automatiza cargos recurrentes: alquiler, facturas, salario.',
      'new_rule': 'Nueva regla',
      'edit_rule': 'Editar regla',
      'delete_rule_title': '¿Eliminar regla?',
      'frequency_label': 'Frecuencia',
      'freq_daily': 'Diario',
      'freq_weekly': 'Semanal',
      'next_run_prefix': 'Siguiente: ',
      // reports titles
      'by_categories_month_prefix': 'Por categoría · ',
      'expenses_by_categories_month_prefix': 'Gastos por categoría · ',
      'income_by_categories_month_prefix': 'Ingresos por categoría · ',
      'cash_flow_month_prefix': 'Flujo de caja · ',
      // currency picker
      'search_currency': 'Buscar moneda',
      'popular_upper': 'POPULARES',
      'crypto_upper': 'CRIPTO',
      // common error
      'error_title': 'Algo salió mal',
      'error_fatal_body':
          'Monedero encontró un error inesperado. Tus datos locales siguen guardados en el dispositivo.',
      'error_fatal_hint':
          'Cierra la app por completo (desliza hacia arriba en el selector de apps) y ábrela de nuevo.',
      'add_account_first': 'Añade primero una cuenta',
      'account_not_found': 'Cuenta no encontrada',
      'backup_created': 'Copia creada',
      'auto_backup': 'Automático',
      'auto_backup_desc': 'Copia local diaria',
      'create_now': 'Crear ahora',
      'local_backups_upper': 'COPIAS LOCALES',
      'no_backups_title': 'Sin copias',
      'no_backups_desc': 'Crea la primera copia\npara guardar tus datos.',
      'empty_budgets_title': 'Aún no hay presupuestos.',
      'spent_this_month': 'Gastado este mes',
      'out_of_budget_template': 'de {} de presupuesto',
      'credit_limit_prefix': 'Límite: ',
      'credit_limit': 'Límite de crédito',
      'credit_limit_hint': 'Opcional',
      'auto_cloud_backup': 'Copia en la nube',
      'auto_cloud_backup_desc': 'Subida diaria automática',
      'last_sync_prefix': 'Última sync: ',
      'never_synced': 'Aún no sincronizado',
      'cloud_restore_title': '¿Restaurar datos?',
      'cloud_restore_body':
          'Puedes reemplazar los datos locales con la copia en la nube o subir los datos locales a la nube.',
      'cloud_restore_remote_meta':
          'Nube: {date} · {a} cuentas · {t} movimientos',
      'cloud_restore_local_meta':
          'Local (se reemplazará): {a} cuentas · {t} movimientos',
      'cloud_restore_merge': 'Combinar',
      'cloud_restore_merge_hint':
          'Datos de la nube + movimientos locales que no están en la nube.',
      'cloud_restore_merged_ok': 'Datos combinados y subidos a la nube',
      'cloud_restore_use_cloud': 'Usar nube',
      'cloud_restore_keep_local': 'Mantener local',
      'delete_cloud_reset_local': 'También borrar datos de este dispositivo',
      'import_map_columns': 'Columnas',
      'import_col_date': 'Fecha',
      'import_col_amount': 'Importe',
      'import_col_type': 'Tipo',
      'import_col_currency': 'Moneda',
      'import_col_note': 'Nota',
      'import_col_none': '—',
      'import_sample_rows': 'Vista previa',
      'budget_categories': 'Categorías',
      'budget_categories_all': 'Todas',
      'budget_rollover': 'Arrastrar saldo',
      'budget_rollover_desc': 'El sobrante pasa al siguiente periodo',
      'pick_date_range': 'Elegir periodo',
      'date_from': 'Desde',
      'date_to': 'Hasta',
      'export_pdf_date': 'Fecha',
      'export_pdf_type': 'Tipo',
      'export_pdf_amount': 'Importe',
      'export_pdf_note': 'Nota',
      'export_total_income': 'Total ingresos',
      'export_total_expense': 'Total gastos',
      'export_net': 'Balance',
      'export_failed': 'No se pudo exportar',
      'form_incomplete': 'Revisa el nombre y el importe',
      'tags_label': 'Etiquetas',
      'tags_hint': 'viaje, trabajo…',
      'import_duplicates_skipped': 'Duplicados omitidos: {}',
      'pro_expires': 'Pro activo hasta {}',
      'pro_valid_until': 'Válido hasta {}',
      'pro_expires_loading': 'Cargando fecha de renovación…',
      'pro_days_left': '{} días restantes',
      'pro_manage_subscription': 'Gestionar suscripción',
      'shared_budget_title': 'Presupuesto compartido',
      'shared_budget_subtitle':
          'Rastrea y sincroniza transacciones con tu pareja',
      'shared_budget_create': 'Crear enlace de pareja',
      'shared_budget_join': 'Unirse con código',
      'shared_budget_join_hint': 'Introduce el código de invitación de tu pareja',
      'shared_budget_invite_code': 'Código de invitación',
      'shared_budget_sign_in': 'Inicia sesión para compartir un presupuesto',
      'shared_budget_even': 'Estáis a mano ✌️',
      'shared_budget_sync': 'Sincronizar mis gastos del mes',
      'shared_budget_leave': 'Salir del presupuesto',
      'shared_budget_leave_title': '¿Salir del presupuesto compartido?',
      'shared_budget_leave_body': 'Dejarás de ver los gastos compartidos.',
      'shared_budget_code_copied': 'Código copiado',
      'shared_budget_invalid_code': 'Código no válido',
      'shared_budget_full': 'Este presupuesto ya tiene pareja',
      'shared_budget_already_joined': 'Ya estás en un presupuesto compartido',
      'shared_budget_failed': 'No se pudo actualizar el presupuesto compartido',
      'shared_budget_waiting': 'Esperando pareja…',
      'shared_budget_synced': 'Sincronizados {} gastos',
      'shared_budget_partner_owes': 'Tu pareja te debe {}',
      'shared_budget_you_owe': 'Debes {} a tu pareja',
      'you_label': 'Tú',
      'pro_gate_shared_budget':
          'Comparte un presupuesto con tu pareja y sincroniza gastos en la nube.',
      'widget_budget_left': 'Queda',
      'widget_month_expense': 'Gasto',
      'smart_budget_title': 'Presupuesto',
      'smart_budget_body': '{} casi agotado ({})',
      'select_short': 'Elegir',
      'enter_note_hint': 'Escribe una nota...',
      'backups_short': 'Copias',
      'transfer_between': 'Transferencia interna',
      'transfer_between_title': 'Transferencia interna',
      'transfer_between_short': 'Transferencia interna',
      'transfer_between_tab': 'Transferencia interna',
      'transfer_external': 'Transferencia externa',
      'transfer_external_tab': 'Transferencia externa',
      'transfer_between_hint': 'Mueve dinero entre tus cuentas. No es ingreso ni gasto.',
      'transfer_external_hint': 'Envías dinero fuera de tus cuentas. Cuenta como gasto.',
      'quick_transfer': 'Entre',
      'quick_external': 'Fuera',
      'month_balance': 'Balance del mes',
      'month_net': 'Resultado',
      'sign_in': 'Iniciar sesión',
      'sign_in_apple': 'Continuar con Apple',
      'sign_in_google': 'Continuar con Google',
      'sign_in_email': 'Email y contraseña',
      'register': 'Crear cuenta',
      'sign_out': 'Cerrar sesión',
      'signed_in_as': 'Sesión iniciada',
      'delete_cloud_account': 'Eliminar cuenta en la nube',
      'delete_cloud_account_title': '¿Eliminar cuenta en la nube?',
      'delete_cloud_account_body':
          'Se borrará el login (Apple, Google o email), la copia en la nube, tu participación en el presupuesto compartido y tus gastos compartidos. Los datos locales en este dispositivo se quedan. No se puede deshacer.',
      'delete_cloud_account_relogin':
          'Confirma tu identidad (Apple, Google o contraseña) para eliminar la cuenta.',
      'delete_cloud_confirm_identity':
          'Para eliminar la cuenta debes confirmar el acceso. Continúa con el mismo método de inicio de sesión.',
      'delete_cloud_enter_password': 'Introduce tu contraseña para confirmar',
      'delete_cloud_account_failed': 'No se pudo eliminar la cuenta',
      'delete_cloud_account_ok': 'Cuenta eliminada',
      'auth_failed': 'No se pudo iniciar sesión',
      'auth_invalid_email': 'Email no válido',
      'auth_weak_password': 'La contraseña es demasiado corta',
      'auth_wrong_password': 'Email o contraseña incorrectos',
      'auth_user_disabled': 'Esta cuenta está desactivada',
      'auth_too_many': 'Demasiados intentos. Prueba más tarde',
      'auth_canceled': 'Inicio de sesión cancelado',
      'auth_email_in_use': 'Este email ya tiene cuenta. Inicia sesión.',
      'auth_network_error':
          'Sin conexión con el servidor. Comprueba la red del Mac o reinicia el simulador.',
      'cloud_backup_ok': 'Copia subida a la nube',
      'cloud_restore_ok': 'Datos restaurados desde la nube',
      'cloud_empty': 'Aún no hay copia en la nube',
      'sign_in_to_sync': 'Inicia sesión para sincronizar',
      'email': 'Email',
      'password': 'Contraseña',
      'firebase_not_ready': 'La nube se activará cuando conectemos Firebase.',
      'cloud_backup': 'Copia en la nube',
      'cloud_restore': 'Restaurar desde la nube',
      'sync_devices': 'Sincronizar dispositivos',
      'security': 'Seguridad',
      'pin_code': 'Código PIN',
      'pin_code_hint': 'Opcional. Para entrar si Face ID no funciona',
      'use_biometrics': 'Bloqueo biométrico',
      'biometric_lock_hint': 'Pide Face ID o huella al abrir la app',
      'auto_lock': 'Bloqueo automático',
      'auto_lock_hint': 'Bloquear al salir de la app',
      'biometrics_unavailable': 'La biometría no está disponible en este dispositivo',
      'biometrics_failed': 'No se pudo activar la biometría',
      'biometrics_need_pin': 'Crea un PIN primero — es el respaldo si Face ID o la huella fallan',
      'enter_pin': 'Introduce el PIN',
      'set_pin': 'Crear PIN',
      'confirm_pin': 'Confirma el PIN',
      'pin_mismatch': 'Los PIN no coinciden',
      'pin_wrong': 'PIN incorrecto',
      'unlock': 'Desbloquear',
      'unlock_biometric_hint': 'Usa Face ID o tu huella para continuar',
      'export_csv': 'Exportar datos',
      'export_excel': 'Exportar Excel',
      'export_pdf': 'Exportar PDF',
      'export_period': 'Periodo de exportación',
      'period_this_month': 'Este mes',
      'period_last_month': 'Mes pasado',
      'period_3m': '3 meses',
      'period_6m': '6 meses',
      'period_this_year': 'Este año',
      'period_last_year': 'Año pasado',
      'period_custom': 'Periodo personalizado',
      'choose_period': 'Elegir periodo',
      'restore_local': 'Restaurar',
      'data_restored': 'Datos restaurados',
      'restore_failed': 'No se pudo restaurar',
      'import_backup_json': 'Importar copia JSON',
      'cloud_backup_failed': 'No se pudo guardar la copia en la nube',
      'fx_approximate_balance': 'Tipos de cambio no disponibles · total aproximado',
      'import_no_accounts': 'Crea una cuenta antes de importar',
      'import_no_rows': 'No se encontraron transacciones en el archivo',
      'data_load_db_error': 'No se pudo leer la base de datos local',
      'data_load_network_error': 'Error de red al cargar datos',
      'data_load_generic_error': 'No se pudieron cargar los datos',
      'firebase_offline_banner':
          'Sin conexión a Firebase: entrada, nube e IA no están disponibles',
      'data_init_failed_banner':
          'Error al iniciar datos locales. Reinicia la app',
      'account_section': 'Cuenta',
      'pro_title': 'Monedero Pro',
      'pro_subtitle':
          'Obtén acceso a todas las funciones de la aplicación sin restricciones.',
      'pro_features_heading': 'FUNCIONES INCLUIDAS',
      'pro_paywall_trial_footnote':
          'Prueba gratis, luego renovación automática',
      'pro_start_free_trial': 'Empezar prueba gratis',
      'pro_trial_badge': '{} DÍAS GRATIS',
      'pro_discount_badge': '−{}%',
      'pro_all_features': 'Todas las funciones',
      'pro_feature_ai_chat': 'Asistente IA en el chat',
      'pro_feature_ai_quality': 'Calidad y velocidad premium de la IA',
      'pro_feature_ai_receipts': 'Escaneo de recibos con IA',
      'pro_feature_ai_voice': 'Entrada por voz con IA',
      'pro_feature_accounts': 'Cuentas sin límites',
      'pro_feature_budgets': 'Presupuestos sin límites',
      'pro_feature_goals': 'Metas financieras sin límites',
      'pro_feature_debts': 'Deudas sin límites',
      'pro_feature_stats': 'Estadísticas e informes detallados',
      'pro_feature_trends': 'Análisis de tendencias financieras',
      'pro_feature_cashflow': 'Flujos de caja',
      'pro_feature_shared_budget': 'Presupuesto compartido con tu pareja',
      'pro_feature_reminder_payments': 'Recordatorios de pagos',
      'pro_feature_reminder_subs': 'Recordatorios de suscripciones',
      'pro_feature_reminder_goals': 'Recordatorios de metas financieras',
      'pro_feature_cloud_backup': 'Copias de seguridad en la nube',
      'pro_feature_sync': 'Sincronización entre dispositivos',
      'pro_feature_export_excel': 'Exportar a Excel',
      'pro_feature_export_pdf': 'Exportar a PDF',
      'pro_feature_import_csv': 'Importar datos desde CSV',
      'pro_feature_no_ads': 'Sin anuncios',
      'pro_cta_subtitle': 'Acceso sin límites',
      'pro_go': 'Pasar a Pro',
      'pro_restore': 'Restaurar compras',
      'pro_sign_in_required': 'Inicia sesión para activar Pro',
      'pro_restore_empty': 'No se encontraron compras activas',
      'pro_restore_ok': 'Compras restauradas',
      'pro_legal_notice':
          'El pago se carga a tu Apple ID. La suscripción se renueva automáticamente salvo que la canceles al menos 24 h antes del final del periodo. Gestiona o cancela en Ajustes → Apple ID → Suscripciones. Si compras durante la prueba, pierdes el resto de días gratis. Al continuar aceptas los Términos y la Política de privacidad.',
      'pro_legal_notice_android':
          'El pago se carga a tu cuenta de Google Play. La suscripción se renueva automáticamente salvo que la canceles al menos 24 h antes del final del periodo. Gestiona o cancela en Google Play → Pagos y suscripciones → Suscripciones. Al continuar aceptas los Términos y la Política de privacidad.',
      'pro_yearly': 'Anual',
      'pro_monthly': 'Mensual',
      'pro_semi_annual': '6 meses',
      'pro_yearly_save': 'Ahorra 48%',
      'pro_yearly_save_pct': 'Ahorra {}%',
      'pro_trial': '7 días de prueba gratis',
      'pro_trial_days': '{} días de prueba gratis',
      'pro_active': 'Monedero Pro está activo',
      'pro_active_short': 'Activo',
      'pro_buy_failed': 'No se pudo completar la compra',
      'pro_store_empty':
          'Los precios no están disponibles ahora. Comprueba la conexión e inténtalo de nuevo.',
      'pro_debug_unlock': 'Desbloquear Pro (debug)',
      'import_csv': 'Importar CSV',
      'import_csv_hint':
          'Importa un CSV de Monedero o un extracto bancario con fecha e importe.',
      'import_pick_file': 'Elegir archivo',
      'import_preview': '{n} movimientos listos · {s} filas omitidas',
      'import_confirm': 'Importar',
      'import_failed': 'No se pudo importar el archivo',
      'import_done': 'Importadas {} transacciones',
      'reminders_page_hint':
          'Elige cuándo recordar gastos. Los avisos inteligentes son solo Pro.',
      'daily_reminder_section': 'Recordatorio diario',
      'smart_reminders': 'Recordatorios inteligentes',
      'smart_reminders_hint':
          'Deudas, suscripciones y metas',
      'smart_reminders_desc':
          'Avisos el día del pago, un día antes de la suscripción y recordatorios de metas y presupuestos.',
      'smart_debt_title': 'Pago pendiente',
      'smart_debt_body': 'Hoy vence un pago con {}',
      'smart_sub_title': 'Suscripción',
      'smart_sub_body': 'Pronto se cobra {}',
      'smart_goal_title': 'Meta',
      'smart_goal_body': 'Revisa tu meta: {}',
      'pro_gate_accounts':
          'La versión gratuita incluye hasta 3 cuentas.\nPasa a Pro para añadir cuentas ilimitadas.',
      'pro_gate_goals':
          'La versión gratuita incluye hasta 2 metas activas.\nPasa a Pro para crear metas ilimitadas.',
      'pro_gate_budgets':
          'La versión gratuita incluye hasta 3 presupuestos activos.\nPasa a Pro para crear presupuestos ilimitados.',
      'pro_gate_debts':
          'La versión gratuita incluye hasta 2 deudas activas.\nPasa a Pro para añadir deudas ilimitadas.',
      'pro_gate_subscriptions':
          'La versión gratuita incluye hasta 3 suscripciones activas.\nPasa a Pro para añadir suscripciones ilimitadas.',
      'pro_gate_recurring':
          'La versión gratuita incluye hasta 3 operaciones recurrentes.\nPasa a Pro para añadir operaciones ilimitadas.',
      'pro_gate_analytics':
          'La analítica avanzada está disponible en Pro.\nPasa a Pro para analizar 3, 6 y 12 meses.',
      'pro_gate_trends':
          'El análisis de tendencias está disponible en Pro.\nPasa a Pro para seguir ingresos y gastos en el tiempo.',
      'pro_gate_flows':
          'El análisis de flujos está disponible en Pro.\nPasa a Pro para ver el movimiento de tu dinero.',
      'pro_gate_currencies':
          'La versión gratuita incluye 1 moneda principal.\nPasa a Pro para usar varias monedas y cuentas.',
      'pro_gate_cloud':
          'Las copias en la nube están disponibles en Pro.\nGuarda tus datos y restáuralos en cualquier dispositivo.',
      'pro_gate_sync':
          'La sincronización entre dispositivos está disponible en Pro.\nPasa a Pro para tener tus datos en varios dispositivos.',
      'pro_gate_excel':
          'Exportar a Excel está disponible en Pro.\nPasa a Pro para exportar tus finanzas a Excel.',
      'pro_gate_pdf':
          'Exportar a PDF está disponible en Pro.\nPasa a Pro para crear informes PDF.',
      'pro_gate_reminders':
          'Los recordatorios inteligentes están disponibles en Pro.\nPasa a Pro para avisos de pagos, suscripciones y metas.',
      'pro_gate_import':
          'Importar CSV y extractos está disponible en Pro.\nPasa a Pro para importar tus movimientos.',
      'pro_gate_ai':
          'El asistente IA (voz, recibos, chat) está en Pro.\nInicia sesión y pasa a Pro para usarlo.',
      'ai_recognize_receipt': 'Reconocer con IA',
      'ai_voice_entry': 'Registrar con voz',
      'ai_voice_empty_title': 'Aún no hay operaciones',
      'ai_voice_empty_hint':
          'Asistente IA: di la operación y la guardo al instante.',
      'ai_voice_hint': 'Di algo como: gasté 10 en taxi y 20 en comida',
      'ai_voice_confirm_title': 'Confirmación',
      'ai_voice_confirm_count': '{} transacciones',
      'ai_voice_approve': 'Aprobar',
      'ai_voice_saved': 'Guardadas {} operaciones',
      'ai_listening': 'Escuchando…',
      'ai_confirm_transcript': '¿Usar este texto?',
      'ai_use_transcript': 'Usar',
      'ai_category_suggest': 'IA sugiere: {}',
      'ai_apply_category': 'Aplicar',
      'ai_insight_title': 'Análisis financiero con IA',
      'ai_insight_generate': 'Generar',
      'ai_insight_hint':
          'Ingresos, gastos y cambios clave.',
      'ai_chat_title': 'Asistente',
      'ai_chat_hint': 'Voz, foto o texto — registra gastos e ingresos.',
      'ai_chat_placeholder': 'Mensaje…',
      'ai_chat_welcome':
          'Hola. Soy tu asistente financiero. Puedo registrar un gasto o ingreso — escribe «Café 60» o «Salario 25000». También puedes enviar una foto del recibo, hablar por micrófono o preguntar sobre tus datos en la app.',
      'ai_clear_chat': 'Borrar chat',
      'ai_clear_chat_title': '¿Borrar el chat?',
      'ai_clear_chat_body':
          'Se eliminará el historial de este chat en el dispositivo y en la nube. No se puede deshacer.',
      'ai_assistant_eyebrow': 'AI',
      'ai_recording': 'Grabando…',
      'ai_chat_receipt_sent': '📷 Recibo',
      'ai_receipt_unreadable': 'No pude leer el recibo. Prueba otra foto o escribe la operación.',
      'ai_assistant_recorded': 'Registradas {} operaciones por {}',
      'ai_assistant_receipt_saved': 'Gasto del recibo registrado: {}',
      'ai_busy': 'Pensando…',
      'ai_parsing': 'Leyendo operaciones…',
      'ai_failed': 'No se pudo completar la solicitud de IA. Inténtalo de nuevo.',
      'ai_blocked': 'La IA bloqueó la respuesta. Reformula el mensaje.',
      'ai_empty_response': 'La IA no devolvió texto. Inténtalo de nuevo.',
      'ai_invalid_response': 'La IA devolvió un formato inesperado. Inténtalo de nuevo.',
      'ai_speech_unavailable':
          'El micrófono no está disponible. Escribe el gasto o prueba en un iPhone real.',
      'ai_api_not_enabled':
          'Activa Gemini / Firebase AI Logic en la consola de Firebase.',
      'ai_permission_denied':
          'Firebase rechazó la IA (App Check). En debug: copia el token de la consola y guárdalo en Firebase → App Check → Manage debug tokens.',
      'ai_quota_exceeded': 'Se alcanzó el límite de uso de IA. Prueba más tarde.',
      'ai_billing_depleted':
          'El asistente de IA no está disponible ahora. Inténtalo más tarde.',
      'ai_filled': 'Campos rellenados con IA',
      'ai_energy_empty':
          'Sin energía. Pasa a Pro para usar el asistente sin límites.',
      'ai_energy_hint':
          'Energía del asistente: {} de 100. Pasa a Pro para uso ilimitado.',
      'pro_badge': 'PRO',
    },
    'ru': {
      // common
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'delete_tx_title': 'Удалить транзакцию?',
      'delete_tx_body': 'Это действие нельзя отменить.',
      'tx_deleted': 'Транзакция удалена',
      'undo': 'Отменить',
      'edit': 'Изменить',
      'add': 'Добавить',
      'select': 'Выбрать',
      'search': 'Поиск',
      'all': 'Все',
      'today': 'Сегодня',
      'yesterday': 'Вчера',
      'empty': 'Пусто',
      'ok': 'OK',
      'done': 'Готово',
      'next': 'Далее',
      'back': 'Назад',
      'restore': 'Восстановить',
      'retry': 'Повторить',
      'other': 'Другое',
      // tx types
      'income': 'Доход',
      'expense': 'Расход',
      'transfer': 'Перевод',
      // nav
      'home': 'Главная',
      'transactions': 'Транзакции',
      'transactions_subtitle': 'Доходы, расходы и переводы',
      'analytics': 'Аналитика',
      'profile': 'Профиль',
      // dashboard
      'greeting_morning': 'Доброе утро 👋',
      'greeting_afternoon': 'Добрый день 👋',
      'greeting_evening': 'Добрый вечер 👋',
      'greeting_night': 'Доброй ночи 🌙',
      'total_balance': 'ОБЩИЙ БАЛАНС',
      'recent_transactions': 'Недавние транзакции',
      'see_all': 'Все →',
      'empty_transactions': 'Пока пусто. Нажмите + чтобы добавить.',
      'calendar': 'Календарь',
      'view_history': 'История →',
      'calendar_view_calendar': 'Календарь',
      'calendar_view_daily': 'По дням',
      'calendar_pick_date': 'Выбрать дату',
      'no_tx_this_day': 'Транзакций за этот день нет',
      'enter_amount': 'Введите сумму',
      'empty_filter_results': 'Ничего не найдено',
      'empty_filter_results_hint':
          'Попробуйте изменить фильтры или поиск.',
      'clear_filters': 'Сбросить фильтры',
      'weekday_mon': 'Пн',
      'weekday_tue': 'Вт',
      'weekday_wed': 'Ср',
      'weekday_thu': 'Чт',
      'weekday_fri': 'Пт',
      'weekday_sat': 'Сб',
      'weekday_sun': 'Вс',
      // profile
      'profile_avatar_choose': 'Выбрать фото',
      'profile_avatar_remove': 'Удалить фото',
      'profile_avatar_updating': 'Обновляем фото…',
      'profile_avatar_updated': 'Фото профиля обновлено',
      'profile_avatar_updated_local': 'Фото сохранено на устройстве',
      'profile_avatar_removed': 'Фото профиля удалено',
      'management': 'Панель управления',
      'recurring': 'РЕГУЛЯРНОЕ',
      'section_settings': 'НАСТРОЙКИ',
      'accounts': 'Счета',
      'categories': 'Категории',
      'budgets': 'Бюджеты',
      'new_budget': 'Новый бюджет',
      'edit_budget': 'Изменить бюджет',
      'delete_budget_title': 'Удалить бюджет?',
      'budget_name': 'Название бюджета',
      'recurring_ops': 'Регулярные операции',
      'goals': 'Цели',
      'new_goal': 'Новая цель',
      'edit_goal': 'Изменить цель',
      'goal_name': 'Название',
      'goal_target': 'Сумма цели',
      'goal_saved': 'Накоплено',
      'goals_empty_title': 'Нет целей',
      'goals_empty_desc': 'Создай цель накопления и следи за прогрессом.',
      'add_to_goal': 'Пополнить',
      'subscriptions': 'Подписки',
      'debts': 'Долги',
      'all_settings': 'Все настройки',
      'accounts_count_label': 'счетов',
      'transactions_count': 'транзакций',
      'month_label': 'этот месяц',
      'base_currency_label': 'Основная валюта',
      // settings
      'settings': 'Настройки',
      'profile_section': 'Профиль',
      'language': 'Язык',
      'interface_language': 'Язык интерфейса',
      'theme': 'Тема',
      'theme_dark_mode': 'Тёмный режим',
      'theme_dark_hint': 'Включить ночную тему',
      'daily_reminder': 'Автоматические ежедневные напоминания',
      'daily_reminder_at': 'Напоминание в {} записать доходы и расходы',
      'daily_reminder_off_hint': 'Включи переключатель и выбери время',
      'daily_reminder_time': 'Время',
      'daily_reminder_cta': 'Уведомления',
      'daily_reminder_cta_on': 'Каждый день в {}',
      'daily_reminder_cta_off': 'Настроить расписание',
      'daily_reminder_title': 'Ежедневное напоминание ⏰',
      'daily_reminder_body':
          'Запиши доходы и расходы за сегодня — так проще держать финансы под контролем.',
      'reminder_permission_denied':
          'Разреши уведомления в настройках системы, чтобы получать напоминание.',
      'theme_light': 'Светлая',
      'theme_dark': 'Тёмная',
      'theme_system': 'Как в системе',
      'base_currency': 'Базовая валюта',
      'for_totals_reports': 'Для общих итогов и отчётов',
      'shown_in_app': 'Отображается в приложении',
      'name': 'Имя',
      'data_backups': 'Данные и бэкапы',
      'export_data': 'Экспорт данных',
      'json_backup': 'JSON бэкап',
      'import_backup': 'Импорт из бэкапа',
      'about': 'О приложении',
      'version': 'Версия',
      'error_logs_title': 'Журнал ошибок',
      'error_logs_subtitle':
          'Пишутся только сбои (ИИ, сеть и т.д.) — для диагностики.',
      'error_logs_empty': 'Пока нет записанных ошибок.',
      'error_logs_copy': 'Копировать',
      'error_logs_share': 'Поделиться',
      'error_logs_copied': 'Ошибки скопированы',
      'privacy_policy': 'Политика конфиденциальности',
      'terms_of_use': 'Условия использования',
      'contact_support': 'Поддержка',
      'could_not_open_link': 'Не удалось открыть ссылку',
      'enter_name': 'Введите имя',
      'your_name': 'Ваше имя',
      'how_to_call': 'Как к вам обращаться?',
      // onboarding
      'take_control_of': 'Возьмите под\nконтроль',
      'finance': 'финансы',
      'onboarding_subtitle':
          'Учёт расходов, бюджеты и цели. Всё работает офлайн.',
      'get_started': 'Начать →',
      'try_demo': 'Попробовать с примером',
      'continue_without_account': 'Продолжить без входа',
      'guest_name': 'Гость',
      'or_divider': 'или',
      'please_enter_name': 'Пожалуйста, введите имя',
      'please_enter_email_password': 'Введите email и пароль',
      'setup_title': 'Немного о вас',
      'setup_subtitle':
          'Войдите в аккаунт или продолжите как гость. Имя и валюта сохранятся на устройстве.',
      'initial_balance': 'Начальный баланс',
      'currency': 'Валюта',
      // transactions
      'new_transaction': 'Новая транзакция',
      'category': 'Категория',
      'account': 'Счёт',
      'date': 'Дата',
      'note': 'Заметка',
      'receipt': 'Чек',
      'receipt_camera': 'Камера',
      'receipt_gallery': 'Галерея',
      'amount': 'Сумма',
      'empty_transactions_list': 'Транзакций нет.',
      'enter_note': 'Введите заметку',
      'transaction_singular': 'Транзакция',
      // reports
      'analytics_subtitle': 'Куда уходят деньги',
      'tab_overview': 'Общее',
      'tab_categories': 'Категории',
      'tab_trends': 'Тренды',
      'tab_flows': 'Потоки',
      'expenses_6_months': 'Расходы · {}',
      'income_for_period': 'Доходы · {}',
      'by_categories': 'По категориям',
      'total_word': 'всего',
      'expenses_by_categories': 'Расходы по категориям',
      'no_expenses_this_month': 'Нет расходов за этот месяц',
      'no_expenses_period': 'Нет расходов · {}',
      'no_income_period': 'Нет доходов · {}',
      'income_vs_expenses': 'Доходы vs Расходы · {}',
      'expense_this_month': 'Расход в этом месяце',
      'expense_today': 'Расход сегодня',
      'vs_prev_month': 'vs прошлый месяц',
      'vs_yesterday': 'vs вчера',
      'cash_flow': 'Денежный поток',
      'income_upper': 'ПРИХОД',
      'expense_upper': 'РАСХОД',
      'net_upper': 'ЧИСТО',
      'top_income_sources': 'Топ источников дохода',
      'top_expenses': 'Топ расходов',
      // accounts
      'my_accounts': 'Мои счета',
      'my_account': 'Мой аккаунт',
      'net_worth': 'ЧИСТЫЙ КАПИТАЛ',
      'in_realtime': '↑ в реальном времени',
      'history_12_weeks': '12 недель',
      'offline_first_tag': 'Monedero · офлайн',
      'made_in_spain_line1': 'Сделано в Испании 🇪🇸',
      'made_in_spain_line2': 'Для тех, кто говорит по-испански.',
      'about_spain_title': 'Сделано в Испании 🇪🇸',
      'about_spain_p1':
          'Мы создали это приложение, потому что хотели простой способ управлять деньгами — для нашего языка и нашего образа жизни.',
      'about_spain_p2': 'Теперь мы хотим поделиться им с вами.',
      'about_spain_closing1': 'Это не приложение, переведённое на испанский.',
      'about_spain_closing2': 'Это приложение, созданное на испанском. 🇪🇸',
      'tx_id': 'ID: txn_{}',
      'bank_accounts': 'Банковские счета',
      'cash_wallets': 'Наличные и кошельки',
      'add_account': 'Добавить счёт',
      'new_account': 'Новый счёт',
      'edit_account': 'Изменить счёт',
      'delete_account_title': 'Удалить счёт?',
      'delete_account_body':
          'Все транзакции по этому счёту будут удалены. Это действие нельзя отменить.',
      'account_name': 'Название',
      'include_in_total': 'Учитывать в общем балансе',
      'reset_all_data': 'Сбросить данные на устройстве',
      'reset_all_data_subtitle':
          'Удалит счета и операции на этом телефоне. Облачный аккаунт не удаляется.',
      'reset_all_data_title': 'Удалить данные с устройства?',
      'reset_all_data_body':
          'На этом телефоне будут удалены счета, транзакции, категории, бюджеты, долги, цели и подписки. Настройки и облачный аккаунт останутся. Это нельзя отменить.',
      'reset_success': 'Данные удалены',
      'account_type': 'Тип',
      // filters
      'filter_all': 'Все',
      'filter': 'Фильтр',
      'filter_account': 'Счёт',
      'filter_category': 'Категория',
      // onboarding buttons
      'skip': 'Пропустить',
      'finish_setup': 'Готово',
      // categories
      'cat_food': 'Еда',
      'cat_transport': 'Транспорт',
      'cat_housing': 'Жильё',
      'cat_health': 'Здоровье',
      'cat_entertainment': 'Развлечения',
      'cat_clothing': 'Одежда',
      'cat_communication': 'Связь',
      'cat_education': 'Образование',
      'cat_gifts': 'Подарки',
      'cat_beauty': 'Красота',
      'cat_other_expense': 'Другое',
      'cat_salary': 'Зарплата',
      'cat_freelance': 'Фриланс',
      'cat_gift_income': 'Подарок',
      'cat_investments': 'Инвестиции',
      'cat_other_income': 'Другое',
      // account types
      'account_type_cash': 'Наличные',
      'account_type_card': 'Карта',
      'account_type_bank': 'Банковский счёт',
      'account_type_ewallet': 'Эл. кошелёк',
      'account_type_crypto': 'Крипта',
      'account_type_investment': 'Инвестиции',
      'account_type_loan': 'Займ/Кредит',
      // tx detail
      'tx_not_found': 'Транзакция не найдена',
      'tx_location': 'Место',
      'tx_duplicate': 'Дублировать',
      'income_lower': 'доход',
      'expense_lower': 'расход',
      'transfer_lower': 'перевод',
      // transfer
      'transfer_from': 'Откуда',
      'transfer_to': 'Куда',
      'transfer_sending': 'Отправляете',
      'transfer_recipient_gets': 'Получатель получит',
      'exchange_rate': 'Курс обмена',
      'rate_prefix': 'Курс: 1 ',
      'fee': 'Комиссия',
      'confirm': 'Подтвердить',
      'select_account': 'Выбрать счёт',
      'balance_prefix': 'Баланс: ',
      // categories screen
      'new_category': 'Новая категория',
      'edit_category': 'Изменить категорию',
      'delete_category_title': 'Удалить категорию?',
      'color_label': 'Цвет',
      'icon_label': 'Иконка',
      'title_label': 'Название',
      // debts
      'i_owe': 'Я должен',
      'owed_to_me': 'Мне должны',
      'new_debt': 'Новый долг',
      'edit_debt': 'Изменить долг',
      'delete_debt_title': 'Удалить долг?',
      'to_from_whom': 'Кому / от кого',
      'without_due_date': 'Без срока',
      'due_date_label': 'Срок возврата',
      'due_prefix': 'Срок: ',
      'overdue': 'просрочен',
      'day_short': 'дн',
      'paid_of_template': 'Погашено {p} из {t}',
      'repayment': 'Возврат',
      'debts_empty_title': 'Долгов нет',
      'debts_empty_desc':
          'Добавьте долг, чтобы вести учёт займов и возвратов.',
      'persons_word': 'человек',
      'active_plural': 'активных',
      // subscriptions
      'per_month': 'В месяц',
      'per_year': 'В год',
      'subs_empty_title': 'Подписок нет',
      'subs_empty_desc':
          'Добавьте Netflix, Spotify и другие сервисы,\nчтобы видеть общие расходы.',
      'next_payment_label': 'Ближайший платёж',
      'all_subscriptions': 'Все подписки',
      'new_subscription': 'Новая подписка',
      'edit_subscription': 'Изменить подписку',
      'delete_sub_title': 'Удалить подписку?',
      'service_name': 'Название сервиса',
      'periodicity': 'Периодичность',
      'monthly_label': 'Ежемесячно',
      'yearly_label': 'Ежегодно',
      'next_payment_prefix': 'Следующий платёж: ',
      'in_days_short': 'через {n} дн.',
      // recurring
      'active_tab': 'Активные',
      'paused_tab': 'Пауза',
      'paused_plural': 'на паузе',
      'rules_empty_title': 'Регулярных операций нет',
      'rules_empty_desc':
          'Автоматизируйте регулярные списания: аренду, счета, зарплату.',
      'new_rule': 'Новое правило',
      'edit_rule': 'Изменить правило',
      'delete_rule_title': 'Удалить правило?',
      'frequency_label': 'Частота',
      'freq_daily': 'Ежедневно',
      'freq_weekly': 'Еженедельно',
      'next_run_prefix': 'Далее: ',
      // reports titles
      'by_categories_month_prefix': 'По категориям · ',
      'expenses_by_categories_month_prefix': 'Расходы по категориям · ',
      'income_by_categories_month_prefix': 'Доходы по категориям · ',
      'cash_flow_month_prefix': 'Денежный поток · ',
      // currency picker
      'search_currency': 'Поиск валюты',
      'popular_upper': 'ПОПУЛЯРНЫЕ',
      'crypto_upper': 'КРИПТО',
      // common error
      'error_title': 'Что-то пошло не так',
      'error_fatal_body':
          'Monedero столкнулся с неожиданной ошибкой. Локальные данные на устройстве сохранены.',
      'error_fatal_hint':
          'Полностью закройте приложение (смахните из переключателя) и откройте снова.',
      'add_account_first': 'Сначала добавьте счёт',
      'account_not_found': 'Счёт не найден',
      'backup_created': 'Бэкап создан',
      'auto_backup': 'Автоматически',
      'auto_backup_desc': 'Ежедневный локальный бэкап',
      'create_now': 'Создать сейчас',
      'local_backups_upper': 'ЛОКАЛЬНЫЕ БЭКАПЫ',
      'no_backups_title': 'Бэкапов нет',
      'no_backups_desc': 'Создайте первый бэкап,\nчтобы сохранить данные.',
      'empty_budgets_title': 'Ещё нет бюджетов.',
      'spent_this_month': 'Потрачено в этом месяце',
      'out_of_budget_template': 'из {} бюджета',
      'credit_limit_prefix': 'Лимит: ',
      'credit_limit': 'Кредитный лимит',
      'credit_limit_hint': 'Необязательно',
      'auto_cloud_backup': 'Облачный бэкап',
      'auto_cloud_backup_desc': 'Ежедневная автозагрузка',
      'last_sync_prefix': 'Последняя sync: ',
      'never_synced': 'Ещё не синхронизировано',
      'cloud_restore_title': 'Восстановить данные?',
      'cloud_restore_body':
          'Можно заменить локальные данные облачной копией или загрузить локальные данные в облако.',
      'cloud_restore_remote_meta':
          'Облако: {date} · {a} счетов · {t} операций',
      'cloud_restore_local_meta':
          'Локально (будет заменено): {a} счетов · {t} операций',
      'cloud_restore_merge': 'Объединить',
      'cloud_restore_merge_hint':
          'Данные из облака + локальные операции, которых нет в облаке.',
      'cloud_restore_merged_ok': 'Данные объединены и загружены в облако',
      'cloud_restore_use_cloud': 'Из облака',
      'cloud_restore_keep_local': 'Оставить локальные',
      'delete_cloud_reset_local': 'Также стереть данные на этом устройстве',
      'import_map_columns': 'Столбцы',
      'import_col_date': 'Дата',
      'import_col_amount': 'Сумма',
      'import_col_type': 'Тип',
      'import_col_currency': 'Валюта',
      'import_col_note': 'Заметка',
      'import_col_none': '—',
      'import_sample_rows': 'Превью',
      'budget_categories': 'Категории',
      'budget_categories_all': 'Все',
      'budget_rollover': 'Перенос остатка',
      'budget_rollover_desc': 'Непотраченное переносится на следующий период',
      'pick_date_range': 'Выбрать период',
      'date_from': 'С',
      'date_to': 'По',
      'export_pdf_date': 'Дата',
      'export_pdf_type': 'Тип',
      'export_pdf_amount': 'Сумма',
      'export_pdf_note': 'Заметка',
      'export_total_income': 'Всего доходов',
      'export_total_expense': 'Всего расходов',
      'export_net': 'Баланс',
      'export_failed': 'Не удалось экспортировать',
      'form_incomplete': 'Проверьте название и сумму',
      'tags_label': 'Теги',
      'tags_hint': 'отпуск, работа…',
      'import_duplicates_skipped': 'Пропущено дубликатов: {}',
      'pro_expires': 'Pro до {}',
      'pro_valid_until': 'Действует до {}',
      'pro_expires_loading': 'Загрузка даты продления…',
      'pro_days_left': 'Осталось {} дн.',
      'pro_manage_subscription': 'Управление подпиской',
      'shared_budget_title': 'Общий бюджет',
      'shared_budget_subtitle':
          'Отслеживайте и синхронизируйте траты с партнёром',
      'shared_budget_create': 'Создать парный бюджет',
      'shared_budget_join': 'Присоединиться по коду',
      'shared_budget_join_hint': 'Введите код приглашения партнёра',
      'shared_budget_invite_code': 'Код приглашения',
      'shared_budget_sign_in': 'Войдите, чтобы делиться бюджетом',
      'shared_budget_even': 'Вы в расчёте ✌️',
      'shared_budget_sync': 'Синхронизировать мои траты за месяц',
      'shared_budget_leave': 'Выйти из общего бюджета',
      'shared_budget_leave_title': 'Выйти из общего бюджета?',
      'shared_budget_leave_body': 'Вы перестанете видеть общие траты.',
      'shared_budget_code_copied': 'Код скопирован',
      'shared_budget_invalid_code': 'Неверный код',
      'shared_budget_full': 'В этом бюджете уже есть партнёр',
      'shared_budget_already_joined': 'Вы уже в общем бюджете',
      'shared_budget_failed': 'Не удалось обновить общий бюджет',
      'shared_budget_waiting': 'Ждём партнёра…',
      'shared_budget_synced': 'Синхронизировано {} трат',
      'shared_budget_partner_owes': 'Партнёр должен вам {}',
      'shared_budget_you_owe': 'Вы должны партнёру {}',
      'you_label': 'Вы',
      'pro_gate_shared_budget':
          'Общий бюджет с партнёром и синхронизация трат в облаке.',
      'widget_budget_left': 'Осталось',
      'widget_month_expense': 'Расход',
      'smart_budget_title': 'Бюджет',
      'smart_budget_body': '{} почти исчерпан ({})',
      'select_short': 'Выбрать',
      'enter_note_hint': 'Введите заметку...',
      'backups_short': 'Бэкапы',
      'transfer_between': 'Внутренний перевод',
      'transfer_between_title': 'Перевод между счетами',
      'transfer_between_short': 'Внутренний перевод',
      'transfer_between_tab': 'Внутренний перевод',
      'transfer_external': 'Внешний перевод',
      'transfer_external_tab': 'Внешний перевод',
      'transfer_between_hint': 'Перевод между своими счетами. Это не доход и не расход.',
      'transfer_external_hint': 'Деньги уходят вовне. Считается расходом.',
      'quick_transfer': 'Между',
      'quick_external': 'Вне',
      'month_balance': 'Баланс за месяц',
      'month_net': 'Итого',
      'sign_in': 'Войти',
      'sign_in_apple': 'Продолжить с Apple',
      'sign_in_google': 'Продолжить с Google',
      'sign_in_email': 'Email и пароль',
      'register': 'Создать аккаунт',
      'sign_out': 'Выйти',
      'signed_in_as': 'Вы вошли',
      'delete_cloud_account': 'Удалить облачный аккаунт',
      'delete_cloud_account_title': 'Удалить облачный аккаунт?',
      'delete_cloud_account_body':
          'Будут удалены логин (Apple, Google или email), облачная копия, участие в общем бюджете и ваши общие расходы. Данные на этом телефоне останутся. Это нельзя отменить.',
      'delete_cloud_account_relogin':
          'Подтвердите вход (Apple, Google или пароль), чтобы удалить аккаунт.',
      'delete_cloud_confirm_identity':
          'Чтобы удалить аккаунт, подтвердите доступ тем же способом входа.',
      'delete_cloud_enter_password': 'Введите пароль для подтверждения',
      'delete_cloud_account_failed': 'Не удалось удалить аккаунт',
      'delete_cloud_account_ok': 'Аккаунт удалён',
      'auth_failed': 'Не удалось войти',
      'auth_invalid_email': 'Некорректный email',
      'auth_weak_password': 'Пароль слишком короткий',
      'auth_wrong_password': 'Неверный email или пароль',
      'auth_user_disabled': 'Аккаунт отключён',
      'auth_too_many': 'Слишком много попыток. Позже',
      'auth_canceled': 'Вход отменён',
      'auth_email_in_use': 'Этот email уже зарегистрирован. Войдите.',
      'auth_network_error':
          'Нет связи с сервером. Проверь интернет на Mac или перезапусти симулятор.',
      'cloud_backup_ok': 'Копия загружена в облако',
      'cloud_restore_ok': 'Данные восстановлены из облака',
      'cloud_empty': 'В облаке пока нет копии',
      'sign_in_to_sync': 'Войдите, чтобы синхронизировать',
      'email': 'Email',
      'password': 'Пароль',
      'firebase_not_ready': 'Облако включим, когда заказчик даст Firebase.',
      'cloud_backup': 'Облачная копия',
      'cloud_restore': 'Восстановить из облака',
      'sync_devices': 'Синхронизация устройств',
      'security': 'Безопасность',
      'pin_code': 'PIN-код',
      'pin_code_hint': 'Необязательно. Если Face ID не сработает',
      'use_biometrics': 'Биометрический замок',
      'biometric_lock_hint': 'Спрашивать Face ID или отпечаток при входе',
      'auto_lock': 'Автоблокировка',
      'auto_lock_hint': 'Блокировать при выходе из приложения',
      'biometrics_unavailable': 'Биометрия на этом устройстве недоступна',
      'biometrics_failed': 'Не удалось включить биометрию',
      'biometrics_need_pin': 'Сначала создайте PIN — запасной вход, если Face ID или отпечаток не сработают',
      'enter_pin': 'Введите PIN',
      'set_pin': 'Создать PIN',
      'confirm_pin': 'Повторите PIN',
      'pin_mismatch': 'PIN не совпадает',
      'pin_wrong': 'Неверный PIN',
      'unlock': 'Разблокировать',
      'unlock_biometric_hint': 'Используй Face ID или отпечаток, чтобы продолжить',
      'export_csv': 'Экспорт данных',
      'export_excel': 'Экспорт Excel',
      'export_pdf': 'Экспорт PDF',
      'export_period': 'Период экспорта',
      'period_this_month': 'Этот месяц',
      'period_last_month': 'Прошлый месяц',
      'period_3m': '3 месяца',
      'period_6m': '6 месяцев',
      'period_this_year': 'Этот год',
      'period_last_year': 'Прошлый год',
      'period_custom': 'Свой период',
      'choose_period': 'Выбрать период',
      'restore_local': 'Восстановить',
      'data_restored': 'Данные восстановлены',
      'restore_failed': 'Не удалось восстановить',
      'import_backup_json': 'Импорт JSON-копии',
      'cloud_backup_failed': 'Не удалось сохранить облачную копию',
      'fx_approximate_balance': 'Курсы недоступны · баланс приблизительный',
      'import_no_accounts': 'Сначала создайте счёт',
      'import_no_rows': 'В файле не найдено операций',
      'data_load_db_error': 'Не удалось прочитать локальную базу',
      'data_load_network_error': 'Ошибка сети при загрузке данных',
      'data_load_generic_error': 'Не удалось загрузить данные',
      'firebase_offline_banner':
          'Нет связи с Firebase: вход, облако и ИИ недоступны',
      'data_init_failed_banner':
          'Ошибка локальных данных. Перезапустите приложение',
      'account_section': 'Аккаунт',
      'pro_title': 'Monedero Pro',
      'pro_subtitle':
          'Получите доступ ко всем функциям приложения без ограничений.',
      'pro_features_heading': 'ВКЛЮЧЁННЫЕ ФУНКЦИИ',
      'pro_paywall_trial_footnote':
          'Бесплатный период, затем автопродление',
      'pro_start_free_trial': 'Начать бесплатный период',
      'pro_trial_badge': '{} ДНЕЙ БЕСПЛАТНО',
      'pro_discount_badge': '−{}%',
      'pro_all_features': 'Все функции',
      'pro_feature_ai_chat': 'ИИ-ассистент в чате',
      'pro_feature_ai_quality': 'Премиальное качество и скорость ИИ',
      'pro_feature_ai_receipts': 'Сканирование чеков с ИИ',
      'pro_feature_ai_voice': 'Голосовой ввод с ИИ',
      'pro_feature_accounts': 'Счета без ограничений',
      'pro_feature_budgets': 'Бюджеты без ограничений',
      'pro_feature_goals': 'Финансовые цели без ограничений',
      'pro_feature_debts': 'Долги без ограничений',
      'pro_feature_stats': 'Подробная статистика и отчёты',
      'pro_feature_trends': 'Анализ финансовых трендов',
      'pro_feature_cashflow': 'Денежные потоки',
      'pro_feature_shared_budget': 'Общий бюджет с партнёром',
      'pro_feature_reminder_payments': 'Напоминания о платежах',
      'pro_feature_reminder_subs': 'Напоминания о подписках',
      'pro_feature_reminder_goals': 'Напоминания о финансовых целях',
      'pro_feature_cloud_backup': 'Облачные резервные копии',
      'pro_feature_sync': 'Синхронизация между устройствами',
      'pro_feature_export_excel': 'Экспорт в Excel',
      'pro_feature_export_pdf': 'Экспорт в PDF',
      'pro_feature_import_csv': 'Импорт данных из CSV',
      'pro_feature_no_ads': 'Без рекламы',
      'pro_cta_subtitle': 'Доступ без ограничений',
      'pro_go': 'Перейти на Pro',
      'pro_restore': 'Восстановить покупки',
      'pro_sign_in_required': 'Войдите в аккаунт, чтобы активировать Pro',
      'pro_restore_empty': 'Активных покупок не найдено',
      'pro_restore_ok': 'Покупки восстановлены',
      'pro_legal_notice':
          'Оплата списывается с Apple ID. Подписка продлевается автоматически, если не отменить её минимум за 24 часа до конца периода. Управление: Настройки → Apple ID → Подписки. Покупка во время пробного периода отменяет оставшиеся дни триала. Продолжая, вы принимаете Условия использования и Политику конфиденциальности.',
      'pro_legal_notice_android':
          'Оплата списывается с аккаунта Google Play. Подписка продлевается автоматически, если не отменить её минимум за 24 часа до конца периода. Управление: Google Play → Платежи и подписки → Подписки. Продолжая, вы принимаете Условия использования и Политику конфиденциальности.',
      'pro_yearly': 'На год',
      'pro_monthly': 'На месяц',
      'pro_semi_annual': '6 месяцев',
      'pro_yearly_save': '−48%',
      'pro_yearly_save_pct': '−{}%',
      'pro_trial': '7 дней бесплатно',
      'pro_trial_days': '{} дней бесплатно',
      'pro_active': 'Monedero Pro активен',
      'pro_active_short': 'Активен',
      'pro_buy_failed': 'Не удалось завершить покупку',
      'pro_store_empty':
          'Цены сейчас недоступны. Проверьте интернет и попробуйте снова.',
      'pro_debug_unlock': 'Открыть Pro (debug)',
      'import_csv': 'Импорт CSV',
      'import_csv_hint':
          'Импортируйте CSV Monedero или банковскую выписку с датой и суммой.',
      'import_pick_file': 'Выбрать файл',
      'import_preview': '{n} операций готово · {s} строк пропущено',
      'import_confirm': 'Импортировать',
      'import_failed': 'Не удалось импортировать файл',
      'import_done': 'Импортировано {} операций',
      'reminders_page_hint':
          'Настрой, когда напоминать о расходах. Умные уведомления — только в Pro.',
      'daily_reminder_section': 'Ежедневное напоминание',
      'smart_reminders': 'Умные напоминания',
      'smart_reminders_hint':
          'Платежи, подписки и цели',
      'smart_reminders_desc':
          'Напомним в день долга, за день до списания подписки и по целям с бюджетами.',
      'smart_debt_title': 'Платёж',
      'smart_debt_body': 'Сегодня срок платежа: {}',
      'smart_sub_title': 'Подписка',
      'smart_sub_body': 'Скоро спишется {}',
      'smart_goal_title': 'Цель',
      'smart_goal_body': 'Проверьте цель: {}',
      'pro_gate_accounts':
          'Доступно до 3 счетов в бесплатной версии.\nПерейдите на Pro, чтобы добавить неограниченное количество счетов.',
      'pro_gate_goals':
          'Доступно до 2 активных целей в бесплатной версии.\nПерейдите на Pro, чтобы создать неограниченное количество целей.',
      'pro_gate_budgets':
          'Доступно до 3 активных бюджетов в бесплатной версии.\nПерейдите на Pro, чтобы создать неограниченное количество бюджетов.',
      'pro_gate_debts':
          'Доступно до 2 активных долгов в бесплатной версии.\nПерейдите на Pro, чтобы добавить неограниченное количество долгов.',
      'pro_gate_subscriptions':
          'Доступно до 3 активных подписок в бесплатной версии.\nПерейдите на Pro, чтобы добавить неограниченное количество подписок.',
      'pro_gate_recurring':
          'Доступно до 3 регулярных операций в бесплатной версии.\nПерейдите на Pro, чтобы добавить неограниченное количество регулярных операций.',
      'pro_gate_analytics':
          'Расширенная аналитика доступна в Pro.\nПерейдите на Pro, чтобы анализировать свои финансы за 3, 6 и 12 месяцев.',
      'pro_gate_trends':
          'Расширенный анализ тенденций доступен в Pro.\nПерейдите на Pro, чтобы отслеживать изменения доходов и расходов.',
      'pro_gate_flows':
          'Расширенный анализ денежных потоков доступен в Pro.\nПерейдите на Pro, чтобы подробно анализировать движение ваших денег.',
      'pro_gate_currencies':
          'В бесплатной версии доступна 1 основная валюта.\nПерейдите на Pro, чтобы использовать несколько валют и счета в разных валютах.',
      'pro_gate_cloud':
          'Облачные копии доступны в Pro.\nСохраняйте свои финансовые данные в облаке и восстанавливайте их на любом устройстве.',
      'pro_gate_sync':
          'Синхронизация между устройствами доступна в Pro.\nПерейдите на Pro, чтобы синхронизировать свои финансовые данные между устройствами.',
      'pro_gate_excel':
          'Экспорт в Excel доступен в Pro.\nПерейдите на Pro, чтобы экспортировать свои финансовые данные в Excel.',
      'pro_gate_pdf':
          'Экспорт в PDF доступен в Pro.\nПерейдите на Pro, чтобы создавать PDF-отчёты о своих финансах.',
      'pro_gate_reminders':
          'Напоминания доступны в Pro.\nПерейдите на Pro, чтобы получать напоминания о платежах, подписках и финансовых целях.',
      'pro_gate_import':
          'Импорт CSV и выписок доступен в Pro.\nПерейдите на Pro, чтобы импортировать операции.',
      'pro_gate_ai':
          'AI-ассистент (голос, чеки, чат) доступен в Pro.\nВойдите в аккаунт и перейдите на Pro.',
      'ai_recognize_receipt': 'Распознать с ИИ',
      'ai_voice_entry': 'Записать голосом',
      'ai_voice_empty_title': 'Пока нет операций',
      'ai_voice_empty_hint':
          'AI-ассистент — скажи операцию, я сохраню.',
      'ai_voice_hint': 'Скажи: потратил 10 на такси и 20 на еду',
      'ai_voice_confirm_title': 'Подтверждение',
      'ai_voice_confirm_count': '{} транзакции',
      'ai_voice_approve': 'Одобрить',
      'ai_voice_saved': 'Сохранено операций: {}',
      'ai_listening': 'Слушаю…',
      'ai_confirm_transcript': 'Использовать этот текст?',
      'ai_use_transcript': 'Использовать',
      'ai_category_suggest': 'ИИ предлагает: {}',
      'ai_apply_category': 'Применить',
      'ai_insight_title': 'ИИ-анализ финансов',
      'ai_insight_generate': 'Сгенерировать',
      'ai_insight_hint':
          'Доходы, расходы и ключевые изменения.',
      'ai_chat_title': 'Ассистент',
      'ai_chat_hint': 'Голос, фото или текст — запишу расходы и доходы.',
      'ai_chat_placeholder': 'Сообщение…',
      'ai_chat_welcome':
          'Привет! Я твой финансовый ассистент. Могу записать расход или доход — напиши «Кофе 60» или «Зарплата 25000». Можно отправить фото чека, сказать голосом или спросить про данные в приложении.',
      'ai_clear_chat': 'Очистить чат',
      'ai_clear_chat_title': 'Очистить чат?',
      'ai_clear_chat_body':
          'История этого чата будет удалена на устройстве и в облаке. Отменить нельзя.',
      'ai_assistant_eyebrow': 'AI',
      'ai_recording': 'Записываю…',
      'ai_chat_receipt_sent': '📷 Чек',
      'ai_receipt_unreadable': 'Не удалось прочитать чек. Попробуй другое фото или напиши операцию текстом.',
      'ai_assistant_recorded': 'Записано {} операций на {}',
      'ai_assistant_receipt_saved': 'Расход по чеку записан: {}',
      'ai_busy': 'Думаю…',
      'ai_parsing': 'Разбираю операции…',
      'ai_failed': 'Не удалось выполнить запрос к ИИ. Попробуйте ещё раз.',
      'ai_blocked': 'ИИ заблокировал ответ. Переформулируйте сообщение.',
      'ai_empty_response': 'ИИ вернул пустой ответ. Попробуйте ещё раз.',
      'ai_invalid_response': 'ИИ вернул неожиданный формат. Попробуйте ещё раз.',
      'ai_speech_unavailable':
          'Микрофон недоступен. Введите расход текстом или попробуйте на реальном iPhone.',
      'ai_api_not_enabled':
          'Включите Gemini / Firebase AI Logic в консоли Firebase.',
      'ai_permission_denied':
          'Firebase отклонил ИИ (App Check). В debug: скопируйте токен из логов и сохраните в Firebase → App Check → Manage debug tokens.',
      'ai_quota_exceeded': 'Лимит ИИ исчерпан. Попробуйте позже.',
      'ai_billing_depleted':
          'ИИ-ассистент временно недоступен. Попробуйте позже.',
      'ai_filled': 'Поля заполнены с помощью ИИ',
      'ai_energy_empty':
          'Энергия закончилась. Перейдите на Pro для безлимитного ассистента.',
      'ai_energy_hint':
          'Энергия ассистента: {} из 100. Pro — безлимитный доступ.',
      'pro_badge': 'PRO',
    },
    'en': {
      // common
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'delete_tx_title': 'Delete transaction?',
      'delete_tx_body': 'This action cannot be undone.',
      'tx_deleted': 'Transaction deleted',
      'undo': 'Undo',
      'edit': 'Edit',
      'add': 'Add',
      'select': 'Select',
      'search': 'Search',
      'all': 'All',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'empty': 'Empty',
      'ok': 'OK',
      'done': 'Done',
      'next': 'Next',
      'back': 'Back',
      'restore': 'Restore',
      'retry': 'Retry',
      'other': 'Other',
      // tx types
      'income': 'Income',
      'expense': 'Expense',
      'transfer': 'Transfer',
      // nav
      'home': 'Home',
      'transactions': 'Transactions',
      'transactions_subtitle': 'Income, expenses and transfers',
      'analytics': 'Analytics',
      'profile': 'Profile',
      // dashboard
      'greeting_morning': 'Good morning 👋',
      'greeting_afternoon': 'Good afternoon 👋',
      'greeting_evening': 'Good evening 👋',
      'greeting_night': 'Good night 🌙',
      'total_balance': 'TOTAL BALANCE',
      'recent_transactions': 'Recent transactions',
      'see_all': 'See all →',
      'empty_transactions': 'No transactions yet. Tap + to add.',
      'calendar': 'Calendar',
      'view_history': 'View history →',
      'calendar_view_calendar': 'Calendar',
      'calendar_view_daily': 'Daily',
      'calendar_pick_date': 'Pick date',
      'no_tx_this_day': 'No transactions on this day',
      'enter_amount': 'Enter an amount',
      'empty_filter_results': 'No matches',
      'empty_filter_results_hint': 'Try changing filters or search.',
      'clear_filters': 'Clear filters',
      'weekday_mon': 'Mo',
      'weekday_tue': 'Tu',
      'weekday_wed': 'We',
      'weekday_thu': 'Th',
      'weekday_fri': 'Fr',
      'weekday_sat': 'Sa',
      'weekday_sun': 'Su',
      // profile
      'profile_avatar_choose': 'Choose photo',
      'profile_avatar_remove': 'Remove photo',
      'profile_avatar_updating': 'Updating photo…',
      'profile_avatar_updated': 'Profile photo updated',
      'profile_avatar_updated_local': 'Photo saved on this device',
      'profile_avatar_removed': 'Profile photo removed',
      'management': 'Control panel',
      'recurring': 'RECURRING',
      'section_settings': 'SETTINGS',
      'accounts': 'Accounts',
      'categories': 'Categories',
      'budgets': 'Budgets',
      'new_budget': 'New budget',
      'edit_budget': 'Edit budget',
      'delete_budget_title': 'Delete budget?',
      'budget_name': 'Budget name',
      'recurring_ops': 'Recurring operations',
      'goals': 'Goals',
      'new_goal': 'New goal',
      'edit_goal': 'Edit goal',
      'goal_name': 'Name',
      'goal_target': 'Target',
      'goal_saved': 'Saved',
      'goals_empty_title': 'No goals yet',
      'goals_empty_desc': 'Create a savings goal and track progress.',
      'add_to_goal': 'Add savings',
      'subscriptions': 'Subscriptions',
      'debts': 'Debts',
      'all_settings': 'All settings',
      'accounts_count_label': 'accounts',
      'transactions_count': 'transactions',
      'month_label': 'this month',
      'base_currency_label': 'Base currency',
      // settings
      'settings': 'Settings',
      'profile_section': 'Profile',
      'language': 'Language',
      'interface_language': 'Interface language',
      'theme': 'Theme',
      'theme_dark_mode': 'Dark mode',
      'theme_dark_hint': 'Enable night theme',
      'daily_reminder': 'Automated daily reminders',
      'daily_reminder_at': 'Reminder at {} to log income and expenses',
      'daily_reminder_off_hint': 'Turn on the switch and pick a time',
      'daily_reminder_time': 'Time',
      'daily_reminder_cta': 'Notifications',
      'daily_reminder_cta_on': 'Every day at {}',
      'daily_reminder_cta_off': 'Set up schedule',
      'daily_reminder_title': 'Daily reminder ⏰',
      'daily_reminder_body':
          "Keep your finances in check by logging today's transactions.",
      'reminder_permission_denied':
          'Allow notifications in system settings to receive the reminder.',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_system': 'Match system',
      'base_currency': 'Base currency',
      'for_totals_reports': 'Used for totals and reports',
      'shown_in_app': 'Shown throughout the app',
      'name': 'Name',
      'data_backups': 'Data & backups',
      'export_data': 'Export data',
      'json_backup': 'JSON backup',
      'import_backup': 'Import from backup',
      'about': 'About',
      'version': 'Version',
      'error_logs_title': 'Error log',
      'error_logs_subtitle':
          'Only failures are stored (AI, network, etc.) for diagnostics.',
      'error_logs_empty': 'No errors recorded yet.',
      'error_logs_copy': 'Copy',
      'error_logs_share': 'Share',
      'error_logs_copied': 'Errors copied',
      'privacy_policy': 'Privacy Policy',
      'terms_of_use': 'Terms of Use',
      'contact_support': 'Support',
      'could_not_open_link': 'Could not open the link',
      'enter_name': 'Enter your name',
      'your_name': 'Your name',
      'how_to_call': 'How should we address you?',
      // onboarding
      'take_control_of': 'Take control\nof your',
      'finance': 'money',
      'onboarding_subtitle':
          'Track expenses, plan budgets, and reach goals. Fully offline.',
      'get_started': 'Get Started →',
      'try_demo': 'Try with sample data',
      'continue_without_account': 'Continue without signing in',
      'guest_name': 'Guest',
      'or_divider': 'or',
      'please_enter_name': 'Please enter your name',
      'please_enter_email_password': 'Enter email and password',
      'setup_title': 'A bit about you',
      'setup_subtitle':
          'Sign in or continue as a guest. Name and currency are saved on this device.',
      'initial_balance': 'Initial balance',
      'currency': 'Currency',
      // transactions
      'new_transaction': 'New transaction',
      'category': 'Category',
      'account': 'Account',
      'date': 'Date',
      'note': 'Note',
      'receipt': 'Receipt',
      'receipt_camera': 'Camera',
      'receipt_gallery': 'Gallery',
      'amount': 'Amount',
      'empty_transactions_list': 'No transactions.',
      'enter_note': 'Enter a note',
      'transaction_singular': 'Transaction',
      // reports
      'analytics_subtitle': 'Where the money goes',
      'tab_overview': 'Overview',
      'tab_categories': 'Categories',
      'tab_trends': 'Trends',
      'tab_flows': 'Flows',
      'expenses_6_months': 'Expenses · {}',
      'income_for_period': 'Income · {}',
      'by_categories': 'By category',
      'total_word': 'total',
      'expenses_by_categories': 'Expenses by category',
      'no_expenses_this_month': 'No expenses this month',
      'no_expenses_period': 'No expenses · {}',
      'no_income_period': 'No income · {}',
      'income_vs_expenses': 'Income vs Expenses · {}',
      'expense_this_month': 'Expense this month',
      'expense_today': 'Expense today',
      'vs_prev_month': 'vs previous month',
      'vs_yesterday': 'vs yesterday',
      'cash_flow': 'Cash flow',
      'income_upper': 'INCOME',
      'expense_upper': 'EXPENSE',
      'net_upper': 'NET',
      'top_income_sources': 'Top income sources',
      'top_expenses': 'Top expenses',
      // accounts
      'my_accounts': 'My accounts',
      'my_account': 'My account',
      'net_worth': 'NET WORTH',
      'in_realtime': '↑ live',
      'history_12_weeks': '12 weeks',
      'offline_first_tag': 'Monedero · offline-first',
      'made_in_spain_line1': 'Made in Spain 🇪🇸',
      'made_in_spain_line2': 'For Spanish speakers.',
      'about_spain_title': 'Made in Spain 🇪🇸',
      'about_spain_p1':
          'We built this app because we wanted a simple way to manage our money — made for how we speak and live.',
      'about_spain_p2': 'Now we want to share it with you.',
      'about_spain_closing1': "It's not an app translated into Spanish.",
      'about_spain_closing2': "It's an app created in Spanish. 🇪🇸",
      'tx_id': 'ID: txn_{}',
      'bank_accounts': 'Bank accounts',
      'cash_wallets': 'Cash & wallets',
      'add_account': 'Add account',
      'new_account': 'New account',
      'edit_account': 'Edit account',
      'delete_account_title': 'Delete account?',
      'delete_account_body':
          'All transactions for this account will be deleted. This action cannot be undone.',
      'account_name': 'Name',
      'include_in_total': 'Include in total',
      'reset_all_data': 'Reset data on this device',
      'reset_all_data_subtitle':
          'Erases accounts and transactions here. Does not delete the cloud account.',
      'reset_all_data_title': 'Erase data on this device?',
      'reset_all_data_body':
          'Accounts, transactions, categories, budgets, debts, goals and subscriptions on this phone will be deleted. Settings and the cloud account stay. This cannot be undone.',
      'reset_success': 'All data cleared',
      'account_type': 'Type',
      // filters
      'filter_all': 'All',
      'filter': 'Filter',
      'filter_account': 'Account',
      'filter_category': 'Category',
      // onboarding buttons
      'skip': 'Skip',
      'finish_setup': 'Done',
      // categories
      'cat_food': 'Food',
      'cat_transport': 'Transport',
      'cat_housing': 'Housing',
      'cat_health': 'Health',
      'cat_entertainment': 'Entertainment',
      'cat_clothing': 'Clothing',
      'cat_communication': 'Communication',
      'cat_education': 'Education',
      'cat_gifts': 'Gifts',
      'cat_beauty': 'Beauty',
      'cat_other_expense': 'Other',
      'cat_salary': 'Salary',
      'cat_freelance': 'Freelance',
      'cat_gift_income': 'Gift',
      'cat_investments': 'Investments',
      'cat_other_income': 'Other',
      // account types
      'account_type_cash': 'Cash',
      'account_type_card': 'Card',
      'account_type_bank': 'Bank account',
      'account_type_ewallet': 'E-wallet',
      'account_type_crypto': 'Crypto',
      'account_type_investment': 'Investment',
      'account_type_loan': 'Loan',
      // tx detail
      'tx_not_found': 'Transaction not found',
      'tx_location': 'Location',
      'tx_duplicate': 'Duplicate',
      'income_lower': 'income',
      'expense_lower': 'expense',
      'transfer_lower': 'transfer',
      // transfer
      'transfer_from': 'From',
      'transfer_to': 'To',
      'transfer_sending': 'Sending',
      'transfer_recipient_gets': 'Recipient gets',
      'exchange_rate': 'Exchange rate',
      'rate_prefix': 'Rate: 1 ',
      'fee': 'Fee',
      'confirm': 'Confirm',
      'select_account': 'Select account',
      'balance_prefix': 'Balance: ',
      // categories screen
      'new_category': 'New category',
      'edit_category': 'Edit category',
      'delete_category_title': 'Delete category?',
      'color_label': 'Color',
      'icon_label': 'Icon',
      'title_label': 'Title',
      // debts
      'i_owe': 'I owe',
      'owed_to_me': 'Owed to me',
      'new_debt': 'New debt',
      'edit_debt': 'Edit debt',
      'delete_debt_title': 'Delete debt?',
      'to_from_whom': 'To / from whom',
      'without_due_date': 'No due date',
      'due_date_label': 'Due date',
      'due_prefix': 'Due: ',
      'overdue': 'overdue',
      'day_short': 'd',
      'paid_of_template': 'Paid {p} of {t}',
      'repayment': 'Repayment',
      'debts_empty_title': 'No debts',
      'debts_empty_desc':
          'Add a debt to track loans and repayments.',
      'persons_word': 'people',
      'active_plural': 'active',
      // subscriptions
      'per_month': 'Per month',
      'per_year': 'Per year',
      'subs_empty_title': 'No subscriptions',
      'subs_empty_desc':
          'Add Netflix, Spotify and other services\nto see total spend.',
      'next_payment_label': 'Next payment',
      'all_subscriptions': 'All subscriptions',
      'new_subscription': 'New subscription',
      'edit_subscription': 'Edit subscription',
      'delete_sub_title': 'Delete subscription?',
      'service_name': 'Service name',
      'periodicity': 'Periodicity',
      'monthly_label': 'Monthly',
      'yearly_label': 'Yearly',
      'next_payment_prefix': 'Next payment: ',
      'in_days_short': 'in {n} days',
      // recurring
      'active_tab': 'Active',
      'paused_tab': 'Paused',
      'paused_plural': 'paused',
      'rules_empty_title': 'No recurring operations',
      'rules_empty_desc':
          'Automate recurring transactions: rent, bills, salary.',
      'new_rule': 'New rule',
      'edit_rule': 'Edit rule',
      'delete_rule_title': 'Delete rule?',
      'frequency_label': 'Frequency',
      'freq_daily': 'Daily',
      'freq_weekly': 'Weekly',
      'next_run_prefix': 'Next: ',
      // reports titles
      'by_categories_month_prefix': 'By category · ',
      'expenses_by_categories_month_prefix': 'Expenses by category · ',
      'income_by_categories_month_prefix': 'Income by category · ',
      'cash_flow_month_prefix': 'Cash flow · ',
      // currency picker
      'search_currency': 'Search currency',
      'popular_upper': 'POPULAR',
      'crypto_upper': 'CRYPTO',
      // common error
      'error_title': 'Something went wrong',
      'error_fatal_body':
          'Monedero hit an unexpected error. Your local data is still saved on this device.',
      'error_fatal_hint':
          'Fully close the app (swipe it away in the app switcher) and open it again.',
      'add_account_first': 'Add an account first',
      'account_not_found': 'Account not found',
      'backup_created': 'Backup created',
      'auto_backup': 'Automatic',
      'auto_backup_desc': 'Daily local backup',
      'create_now': 'Create now',
      'local_backups_upper': 'LOCAL BACKUPS',
      'no_backups_title': 'No backups',
      'no_backups_desc': 'Create your first backup\nto save your data.',
      'empty_budgets_title': 'No budgets yet.',
      'spent_this_month': 'Spent this month',
      'out_of_budget_template': 'of {} budget',
      'credit_limit_prefix': 'Limit: ',
      'credit_limit': 'Credit limit',
      'credit_limit_hint': 'Optional',
      'auto_cloud_backup': 'Cloud backup',
      'auto_cloud_backup_desc': 'Daily automatic upload',
      'last_sync_prefix': 'Last sync: ',
      'never_synced': 'Not synced yet',
      'cloud_restore_title': 'Restore data?',
      'cloud_restore_body':
          'Replace local data with the cloud copy, or upload local data to the cloud.',
      'cloud_restore_remote_meta':
          'Cloud: {date} · {a} accounts · {t} transactions',
      'cloud_restore_local_meta':
          'Local (will be replaced): {a} accounts · {t} transactions',
      'cloud_restore_merge': 'Merge',
      'cloud_restore_merge_hint':
          'Cloud data + local transactions that are not in the cloud.',
      'cloud_restore_merged_ok': 'Data merged and uploaded to the cloud',
      'cloud_restore_use_cloud': 'Use cloud',
      'cloud_restore_keep_local': 'Keep local',
      'delete_cloud_reset_local': 'Also erase data on this device',
      'import_map_columns': 'Columns',
      'import_col_date': 'Date',
      'import_col_amount': 'Amount',
      'import_col_type': 'Type',
      'import_col_currency': 'Currency',
      'import_col_note': 'Note',
      'import_col_none': '—',
      'import_sample_rows': 'Preview',
      'budget_categories': 'Categories',
      'budget_categories_all': 'All',
      'budget_rollover': 'Rollover',
      'budget_rollover_desc': 'Unused amount carries to the next period',
      'pick_date_range': 'Pick date range',
      'date_from': 'From',
      'date_to': 'To',
      'export_pdf_date': 'Date',
      'export_pdf_type': 'Type',
      'export_pdf_amount': 'Amount',
      'export_pdf_note': 'Note',
      'export_total_income': 'Total income',
      'export_total_expense': 'Total expenses',
      'export_net': 'Net',
      'export_failed': 'Could not export',
      'form_incomplete': 'Check the name and amount',
      'tags_label': 'Tags',
      'tags_hint': 'trip, work…',
      'import_duplicates_skipped': 'Duplicates skipped: {}',
      'pro_expires': 'Pro until {}',
      'pro_valid_until': 'Valid until {}',
      'pro_expires_loading': 'Loading renewal date…',
      'pro_days_left': '{} days left',
      'pro_manage_subscription': 'Manage subscription',
      'shared_budget_title': 'Shared budget',
      'shared_budget_subtitle':
          'Track and sync transactions with your partner',
      'shared_budget_create': 'Create partner link',
      'shared_budget_join': 'Join with code',
      'shared_budget_join_hint': 'Enter your partner\'s invite code',
      'shared_budget_invite_code': 'Invite code',
      'shared_budget_sign_in': 'Sign in to share a budget',
      'shared_budget_even': 'You are even ✌️',
      'shared_budget_sync': 'Sync my expenses this month',
      'shared_budget_leave': 'Leave shared budget',
      'shared_budget_leave_title': 'Leave shared budget?',
      'shared_budget_leave_body': 'You will stop seeing shared expenses.',
      'shared_budget_code_copied': 'Code copied',
      'shared_budget_invalid_code': 'Invalid code',
      'shared_budget_full': 'This budget already has a partner',
      'shared_budget_already_joined': 'You are already in a shared budget',
      'shared_budget_failed': 'Could not update shared budget',
      'shared_budget_waiting': 'Waiting for partner…',
      'shared_budget_synced': 'Synced {} expenses',
      'shared_budget_partner_owes': 'Partner owes you {}',
      'shared_budget_you_owe': 'You owe partner {}',
      'you_label': 'You',
      'pro_gate_shared_budget':
          'Share a budget with your partner and sync expenses in the cloud.',
      'widget_budget_left': 'Left',
      'widget_month_expense': 'Expense',
      'smart_budget_title': 'Budget',
      'smart_budget_body': '{} almost used up ({})',
      'select_short': 'Select',
      'enter_note_hint': 'Enter a note...',
      'backups_short': 'Backups',
      'transfer_between': 'Internal transfer',
      'transfer_between_title': 'Internal transfer',
      'transfer_between_short': 'Internal transfer',
      'transfer_between_tab': 'Internal transfer',
      'transfer_external': 'External transfer',
      'transfer_external_tab': 'External transfer',
      'transfer_between_hint': 'Move money between your own accounts. Not income or expense.',
      'transfer_external_hint': 'Send money outside your accounts. Counts as an expense.',
      'quick_transfer': 'Move',
      'quick_external': 'Send',
      'month_balance': 'This month',
      'month_net': 'Net',
      'sign_in': 'Sign in',
      'sign_in_apple': 'Continue with Apple',
      'sign_in_google': 'Continue with Google',
      'sign_in_email': 'Email and password',
      'register': 'Create account',
      'sign_out': 'Sign out',
      'signed_in_as': 'Signed in',
      'delete_cloud_account': 'Delete cloud account',
      'delete_cloud_account_title': 'Delete cloud account?',
      'delete_cloud_account_body':
          'Your Apple, Google or email login, cloud backup, shared-budget membership and your shared expenses will be removed from our servers. Data on this device stays. This cannot be undone.',
      'delete_cloud_account_relogin':
          'Confirm your identity (Apple, Google, or password) to delete the account.',
      'delete_cloud_confirm_identity':
          'To delete the account, confirm access with the same sign-in method.',
      'delete_cloud_enter_password': 'Enter your password to confirm',
      'delete_cloud_account_failed': 'Could not delete account',
      'delete_cloud_account_ok': 'Account deleted',
      'auth_failed': 'Could not sign in',
      'auth_invalid_email': 'Invalid email',
      'auth_weak_password': 'Password is too short',
      'auth_wrong_password': 'Wrong email or password',
      'auth_user_disabled': 'This account is disabled',
      'auth_too_many': 'Too many attempts. Try later',
      'auth_canceled': 'Sign-in cancelled',
      'auth_email_in_use': 'This email already has an account. Sign in.',
      'auth_network_error':
          'Cannot reach the server. Check Mac network or restart the simulator.',
      'cloud_backup_ok': 'Backup uploaded to the cloud',
      'cloud_restore_ok': 'Data restored from the cloud',
      'cloud_empty': 'No cloud backup yet',
      'sign_in_to_sync': 'Sign in to sync',
      'email': 'Email',
      'password': 'Password',
      'firebase_not_ready': 'Cloud sign-in will turn on when Firebase is connected.',
      'cloud_backup': 'Cloud backup',
      'cloud_restore': 'Restore from cloud',
      'sync_devices': 'Sync devices',
      'security': 'Security',
      'pin_code': 'PIN code',
      'pin_code_hint': 'Optional. Use if Face ID is unavailable',
      'use_biometrics': 'Biometric lock',
      'biometric_lock_hint': 'Require Face ID or fingerprint when opening the app',
      'auto_lock': 'Auto-lock',
      'auto_lock_hint': 'Lock when you leave the app',
      'biometrics_unavailable': 'Biometrics are not available on this device',
      'biometrics_failed': 'Could not enable biometrics',
      'biometrics_need_pin': 'Create a PIN first — it’s the backup if Face ID or fingerprint fails',
      'enter_pin': 'Enter PIN',
      'set_pin': 'Create PIN',
      'confirm_pin': 'Confirm PIN',
      'pin_mismatch': 'PINs do not match',
      'pin_wrong': 'Wrong PIN',
      'unlock': 'Unlock',
      'unlock_biometric_hint': 'Use Face ID or fingerprint to continue',
      'export_csv': 'Export data',
      'export_excel': 'Export Excel',
      'export_pdf': 'Export PDF',
      'export_period': 'Export period',
      'period_this_month': 'This month',
      'period_last_month': 'Last month',
      'period_3m': '3 months',
      'period_6m': '6 months',
      'period_this_year': 'This year',
      'period_last_year': 'Last year',
      'period_custom': 'Custom range',
      'choose_period': 'Choose period',
      'restore_local': 'Restore',
      'data_restored': 'Data restored',
      'restore_failed': 'Could not restore',
      'import_backup_json': 'Import JSON backup',
      'cloud_backup_failed': 'Cloud backup failed',
      'fx_approximate_balance': 'Exchange rates unavailable · approximate total',
      'import_no_accounts': 'Create an account before importing',
      'import_no_rows': 'No transactions found in the file',
      'data_load_db_error': 'Could not read the local database',
      'data_load_network_error': 'Network error while loading data',
      'data_load_generic_error': 'Could not load data',
      'firebase_offline_banner':
          'Firebase unavailable: sign-in, cloud and AI are offline',
      'data_init_failed_banner':
          'Local data failed to start. Please restart the app',
      'account_section': 'Account',
      'pro_title': 'Monedero Pro',
      'pro_subtitle':
          'Get access to all app features without restrictions.',
      'pro_features_heading': 'INCLUDED FEATURES',
      'pro_paywall_trial_footnote':
          'Free trial, then auto-renewal',
      'pro_start_free_trial': 'Start free trial',
      'pro_trial_badge': '{} DAYS FREE',
      'pro_discount_badge': '−{}%',
      'pro_all_features': 'All features',
      'pro_feature_ai_chat': 'AI assistant in chat',
      'pro_feature_ai_quality': 'Premium AI quality and speed',
      'pro_feature_ai_receipts': 'AI receipt scanning',
      'pro_feature_ai_voice': 'AI voice input',
      'pro_feature_accounts': 'Unlimited accounts',
      'pro_feature_budgets': 'Unlimited budgets',
      'pro_feature_goals': 'Unlimited financial goals',
      'pro_feature_debts': 'Unlimited debts',
      'pro_feature_stats': 'Detailed statistics and reports',
      'pro_feature_trends': 'Financial trend analysis',
      'pro_feature_cashflow': 'Cash flow',
      'pro_feature_shared_budget': 'Shared budget with your partner',
      'pro_feature_reminder_payments': 'Payment reminders',
      'pro_feature_reminder_subs': 'Subscription reminders',
      'pro_feature_reminder_goals': 'Financial goal reminders',
      'pro_feature_cloud_backup': 'Cloud backups',
      'pro_feature_sync': 'Sync across devices',
      'pro_feature_export_excel': 'Export to Excel',
      'pro_feature_export_pdf': 'Export to PDF',
      'pro_feature_import_csv': 'Import data from CSV',
      'pro_feature_no_ads': 'No ads',
      'pro_cta_subtitle': 'Unlimited access',
      'pro_go': 'Go Pro',
      'pro_restore': 'Restore purchases',
      'pro_sign_in_required': 'Sign in to activate Pro',
      'pro_restore_empty': 'No active purchases found',
      'pro_restore_ok': 'Purchases restored',
      'pro_legal_notice':
          'Payment will be charged to your Apple ID. Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple ID → Subscriptions. Any unused free trial is forfeited when you purchase. By continuing you agree to the Terms of Use and Privacy Policy.',
      'pro_legal_notice_android':
          'Payment will be charged to your Google Play account. Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Google Play → Payments & subscriptions → Subscriptions. By continuing you agree to the Terms of Use and Privacy Policy.',
      'pro_yearly': 'Yearly',
      'pro_monthly': 'Monthly',
      'pro_semi_annual': '6 months',
      'pro_yearly_save': 'Save 48%',
      'pro_yearly_save_pct': 'Save {}%',
      'pro_trial': '7-day free trial',
      'pro_trial_days': '{}-day free trial',
      'pro_active': 'Monedero Pro is active',
      'pro_active_short': 'Active',
      'pro_buy_failed': 'Could not complete the purchase',
      'pro_store_empty':
          'Prices are unavailable right now. Check your connection and try again.',
      'pro_debug_unlock': 'Unlock Pro (debug)',
      'import_csv': 'Import CSV',
      'import_csv_hint':
          'Import a Monedero CSV or a bank statement with date and amount.',
      'import_pick_file': 'Choose file',
      'import_preview': '{n} transactions ready · {s} rows skipped',
      'import_confirm': 'Import',
      'import_failed': 'Could not import the file',
      'import_done': 'Imported {} transactions',
      'reminders_page_hint':
          'Choose when to log expenses. Smart alerts are Pro only.',
      'daily_reminder_section': 'Daily reminder',
      'smart_reminders': 'Smart reminders',
      'smart_reminders_hint':
          'Debts, subscriptions and goals',
      'smart_reminders_desc':
          'Alerts on debt due dates, a day before subscriptions, and goal or budget nudges.',
      'smart_debt_title': 'Payment due',
      'smart_debt_body': 'A payment with {} is due today',
      'smart_sub_title': 'Subscription',
      'smart_sub_body': '{} will be charged soon',
      'smart_goal_title': 'Goal',
      'smart_goal_body': 'Check your goal: {}',
      'pro_gate_accounts':
          'The free version includes up to 3 accounts.\nGo Pro to add unlimited accounts.',
      'pro_gate_goals':
          'The free version includes up to 2 active goals.\nGo Pro to create unlimited goals.',
      'pro_gate_budgets':
          'The free version includes up to 3 active budgets.\nGo Pro to create unlimited budgets.',
      'pro_gate_debts':
          'The free version includes up to 2 active debts.\nGo Pro to add unlimited debts.',
      'pro_gate_subscriptions':
          'The free version includes up to 3 active subscriptions.\nGo Pro to add unlimited subscriptions.',
      'pro_gate_recurring':
          'The free version includes up to 3 recurring operations.\nGo Pro to add unlimited recurring operations.',
      'pro_gate_analytics':
          'Advanced analytics is available in Pro.\nGo Pro to analyze 3, 6 and 12 months.',
      'pro_gate_trends':
          'Trend analysis is available in Pro.\nGo Pro to track income and expenses over time.',
      'pro_gate_flows':
          'Cash-flow analysis is available in Pro.\nGo Pro to see how your money moves.',
      'pro_gate_currencies':
          'The free version includes 1 base currency.\nGo Pro to use multiple currencies and accounts.',
      'pro_gate_cloud':
          'Cloud backups are available in Pro.\nSave your data and restore it on any device.',
      'pro_gate_sync':
          'Device sync is available in Pro.\nGo Pro to keep your data across devices.',
      'pro_gate_excel':
          'Excel export is available in Pro.\nGo Pro to export your finances to Excel.',
      'pro_gate_pdf':
          'PDF export is available in Pro.\nGo Pro to create PDF reports.',
      'pro_gate_reminders':
          'Smart reminders are available in Pro.\nGo Pro for payment, subscription and goal alerts.',
      'pro_gate_import':
          'CSV and statement import is available in Pro.\nGo Pro to import your transactions.',
      'pro_gate_ai':
          'AI assistant (voice, receipts, chat) is a Pro feature.\nSign in and go Pro to use it.',
      'ai_recognize_receipt': 'Recognize with AI',
      'ai_voice_entry': 'Record by voice',
      'ai_voice_empty_title': 'No transactions yet',
      'ai_voice_empty_hint':
          'AI assistant — say a transaction and I\'ll save it.',
      'ai_voice_hint': 'Say: I spent 10 on taxi and 20 on food',
      'ai_voice_confirm_title': 'Confirmation',
      'ai_voice_confirm_count': '{} transactions',
      'ai_voice_approve': 'Approve',
      'ai_voice_saved': 'Saved {} transactions',
      'ai_listening': 'Listening…',
      'ai_confirm_transcript': 'Use this text?',
      'ai_use_transcript': 'Use',
      'ai_category_suggest': 'AI suggests: {}',
      'ai_apply_category': 'Apply',
      'ai_insight_title': 'AI financial analysis',
      'ai_insight_generate': 'Generate',
      'ai_insight_hint':
          'Income, expenses and key changes.',
      'ai_chat_title': 'Assistant',
      'ai_chat_hint': 'Voice, photo, or text — log expenses and income.',
      'ai_chat_placeholder': 'Message…',
      'ai_chat_welcome':
          'Hi! I\'m your financial assistant. I can log an expense or income — try «Coffee 60» or «Salary 25000». Send a receipt photo, use the mic, or ask about your app data.',
      'ai_clear_chat': 'Clear chat',
      'ai_clear_chat_title': 'Clear chat?',
      'ai_clear_chat_body':
          'This chat history will be deleted on this device and in the cloud. This cannot be undone.',
      'ai_assistant_eyebrow': 'AI',
      'ai_recording': 'Recording…',
      'ai_chat_receipt_sent': '📷 Receipt',
      'ai_receipt_unreadable': 'Could not read the receipt. Try another photo or type the transaction.',
      'ai_assistant_recorded': 'Saved {} transactions for {}',
      'ai_assistant_receipt_saved': 'Receipt expense saved: {}',
      'ai_busy': 'Thinking…',
      'ai_parsing': 'Parsing transactions…',
      'ai_failed': 'Could not complete the AI request. Try again.',
      'ai_blocked': 'The AI blocked that reply. Rephrase your message.',
      'ai_empty_response': 'The AI returned an empty reply. Try again.',
      'ai_invalid_response': 'The AI returned an unexpected format. Try again.',
      'ai_speech_unavailable':
          'Microphone unavailable. Type the expense or try on a real iPhone.',
      'ai_api_not_enabled':
          'Enable Gemini / Firebase AI Logic in the Firebase console.',
      'ai_permission_denied':
          'Firebase rejected AI (App Check). In debug: copy the token from logs and save it in Firebase → App Check → Manage debug tokens.',
      'ai_quota_exceeded': 'AI usage limit reached. Try again later.',
      'ai_billing_depleted':
          'The AI assistant is temporarily unavailable. Try again later.',
      'ai_filled': 'Fields filled with AI',
      'ai_energy_empty':
          'Out of energy. Upgrade to Pro for unlimited assistant use.',
      'ai_energy_hint':
          'Assistant energy: {} of 100. Upgrade to Pro for unlimited use.',
      'pro_badge': 'PRO',
    },
        'uk': {
      'save': 'Зберегти',
      'cancel': 'Скасувати',
      'delete': 'Видалити',
      'delete_tx_title': 'Видалити транзакцію?',
      'delete_tx_body': 'Цю дію неможливо скасувати.',
      'tx_deleted': 'Транзакцію видалено',
      'undo': 'Скасувати',
      'edit': 'Змінити',
      'add': 'Додати',
      'select': 'Вибрати',
      'search': 'Пошук',
      'all': 'Усі',
      'today': 'Сьогодні',
      'yesterday': 'Вчора',
      'empty': 'Порожнє',
      'ok': 'OK',
      'done': 'Готово',
      'next': 'Далі',
      'back': 'Назад',
      'restore': 'Відновити',
      'retry': 'Повторити',
      'other': 'Інше',
      'income': 'Дохід',
      'expense': 'Витрата',
      'transfer': 'Переказ',
      'home': 'Головна',
      'transactions': 'Транзакції',
      'transactions_subtitle': 'Доходи, витрати та перекази',
      'analytics': 'Аналітика',
      'profile': 'Профіль',
      'greeting_morning': 'Доброго ранку 👋',
      'greeting_afternoon': 'Добрий день 👋',
      'greeting_evening': 'Добрий вечір 👋',
      'greeting_night': 'Надобраніч 🌙',
      'total_balance': 'Загальний баланс',
      'recent_transactions': 'Останні транзакції',
      'see_all': 'Усі',
      'empty_transactions': 'Поки що порожньо. Натисніть +, щоб додати.',
      'calendar': 'Календар',
      'view_history': 'Історія →',
      'calendar_view_calendar': 'Календар',
      'calendar_view_daily': 'По днях',
      'calendar_pick_date': 'Вибрати дату',
      'no_tx_this_day': 'Немає транзакцій за цей день',
      'enter_amount': 'Введіть суму',
      'empty_filter_results': 'Нічого не знайдено',
      'empty_filter_results_hint':
          'Спробуйте змінити фільтри або пошук.',
      'clear_filters': 'Скинути фільтри',
      'weekday_mon': 'Пн',
      'weekday_tue': 'Вт',
      'weekday_wed': 'Ср',
      'weekday_thu': 'Чт',
      'weekday_fri': 'Пт',
      'weekday_sat': 'Сб',
      'weekday_sun': 'Нд',
      'management': 'Панель керування',
      'profile_avatar_choose': 'Обрати фото',
      'profile_avatar_remove': 'Видалити фото',
      'profile_avatar_updating': 'Оновлюємо фото…',
      'profile_avatar_updated': 'Фото профілю оновлено',
      'profile_avatar_updated_local': 'Фото збережено на пристрої',
      'profile_avatar_removed': 'Фото профілю видалено',
      'recurring': 'РЕГУЛЯРНЕ',
      'section_settings': 'НАЛАШТУВАННЯ',
      'accounts': 'Рахунки',
      'categories': 'Категорії',
      'budgets': 'Бюджети',
      'new_budget': 'Новий бюджет',
      'edit_budget': 'Редагувати бюджет',
      'delete_budget_title': 'Видалити бюджет?',
      'budget_name': 'Назва бюджету',
      'recurring_ops': 'Регулярні операції',
      'goals': 'Цілі',
      'new_goal': 'Нова ціль',
      'edit_goal': 'Редагувати ціль',
      'goal_name': 'Назва',
      'goal_target': 'Сума цілі',
      'goal_saved': 'Накопичено',
      'goals_empty_title': 'Немає цілей',
      'goals_empty_desc': 'Створіть ціль накопичення та відстежуйте прогрес.',
      'add_to_goal': 'Поповнити',
      'subscriptions': 'Підписки',
      'debts': 'Борги',
      'all_settings': 'Усі налаштування',
      'accounts_count_label': 'рахунки',
      'transactions_count': 'операції',
      'month_label': 'за місяць',
      'base_currency_label': 'Базова валюта',
      'settings': 'Налаштування',
      'profile_section': 'Профіль',
      'language': 'Мова',
      'interface_language': 'Мова інтерфейсу',
      'theme': 'Тема',
      'theme_dark_mode': 'Темний режим',
      'theme_dark_hint': 'Увімкнути нічну тему',
      'daily_reminder': 'Щоденні нагадування',
      'daily_reminder_at': 'Нагадування в {} про реєстрацію доходів і витрат',
      'daily_reminder_off_hint': 'Увімкніть перемикач і виберіть час',
      'daily_reminder_time': 'Час',
      'daily_reminder_cta': 'Сповіщення',
      'daily_reminder_cta_on': 'Щодня о {}',
      'daily_reminder_cta_off': 'Настроїти розклад',
      'daily_reminder_title': 'Щоденне нагадування',
      'daily_reminder_body': 'Запишіть доходи та витрати на сьогодні — легше тримати фінанси під контролем.',
      'reminder_permission_denied': 'Дозволити отримувати сповіщення в налаштуваннях системи.',
      'theme_light': 'Світло',
      'theme_dark': 'Темний',
      'theme_system': 'Як у системі',
      'base_currency': 'Базова валюта',
      'for_totals_reports': 'Для загальних підсумків та звітів',
      'shown_in_app': 'Відображається в додатку',
      'name': 'Ім\'я',
      'data_backups': 'Дані та бекапи',
      'export_data': 'Експорт даних',
      'json_backup': 'JSON-бекап',
      'import_backup': 'Імпорт з бекапу',
      'about': 'Про додаток',
      'version': 'Версія',
      'error_logs_title': 'Журнал помилок',
      'error_logs_subtitle': 'Для діагностики записуються лише збої (AI, мережа тощо).',
      'error_logs_empty': 'Поки що немає зареєстрованих помилок.',
      'error_logs_copy': 'Копіювати',
      'error_logs_share': 'Поділитися',
      'error_logs_copied': 'Помилки скопійовано',
      'privacy_policy': 'Політика конфіденційності',
      'terms_of_use': 'Умови використання',
      'contact_support': 'Підтримка',
      'could_not_open_link': 'Не вдалося відкрити посилання',
      'enter_name': 'Введіть ім\'я',
      'your_name': 'Ваше ім\'я',
      'how_to_call': 'Як до вас звертатися?',
      'take_control_of': 'Візьміть під\nконтроль',
      'finance': 'Фінанси',
      'onboarding_subtitle': 'Облік витрат, бюджети й цілі. Усе працює офлайн.',
      'get_started': 'Почати',
      'try_demo': 'Спробувати демо',
      'continue_without_account': 'Продовжити без входу',
      'guest_name': 'Гість',
      'or_divider': 'або',
      'please_enter_name': 'Будь ласка, введіть ваше ім\'я',
      'please_enter_email_password': 'Введіть email і пароль',
      'setup_title': 'Трохи про вас',
      'setup_subtitle': 'Увійдіть у свій акаунт або продовжте як гість. Ім\'я та валюту буде збережено на пристрої.',
      'initial_balance': 'Початковий баланс',
      'currency': 'Валюта',
      'new_transaction': 'Нова транзакція',
      'category': 'Категорія',
      'account': 'Рахунок',
      'date': 'Дата',
      'note': 'Нотатка',
      'receipt': 'Чек',
      'receipt_camera': 'Камера',
      'receipt_gallery': 'Галерея',
      'amount': 'Сума',
      'empty_transactions_list': 'Немає транзакцій',
      'enter_note': 'Введіть нотатку',
      'transaction_singular': 'Транзакція',
      'analytics_subtitle': 'Куди йдуть гроші',
      'tab_overview': 'Огляд',
      'tab_categories': 'Категорії',
      'tab_trends': 'Тренди',
      'tab_flows': 'Потоки',
      'expenses_6_months': 'Витрати · {}',
      'income_for_period': 'Доходи · {}',
      'by_categories': 'За категоріями',
      'total_word': 'усього',
      'expenses_by_categories': 'Витрати за категоріями',
      'no_expenses_this_month': 'Жодних витрат за цей місяць',
      'no_expenses_period': 'Немає витрат · {}',
      'no_income_period': 'Немає доходів · {}',
      'income_vs_expenses': 'Доходи vs витрати · {}',
      'expense_this_month': 'Витрати цього місяця',
      'expense_today': 'Витрати сьогодні',
      'vs_prev_month': 'проти минулого місяця',
      'vs_yesterday': 'порівняно з учора',
      'cash_flow': 'Грошовий потік',
      'income_upper': 'ДОХІД',
      'expense_upper': 'ВИТРАТИ',
      'net_upper': 'САЛЬДО',
      'top_income_sources': 'Топ джерел доходу',
      'top_expenses': 'Топ витрат',
      'my_accounts': 'Мої рахунки',
      'my_account': 'Мій акаунт',
      'net_worth': 'ЧИСТИЙ КАПІТАЛ',
      'in_realtime': '↑ у реальному часі',
      'history_12_weeks': '12 тижнів',
      'offline_first_tag': 'Monedero · офлайн',
      'made_in_spain_line1': 'Зроблено в Іспанії 🇪🇸',
      'made_in_spain_line2': 'Для тих, хто говорить іспанською.',
      'about_spain_title': 'Зроблено в Іспанії 🇪🇸',
      'about_spain_p1':
          'Ми створили цей застосунок, бо хотіли простий спосіб керувати грошима — для нашої мови та нашого способу життя.',
      'about_spain_p2': 'Тепер хочемо поділитися ним з вами.',
      'about_spain_closing1': 'Це не застосунок, перекладений іспанською.',
      'about_spain_closing2': 'Це застосунок, створений іспанською. 🇪🇸',
      'tx_id': 'ID: txn_{}',
      'bank_accounts': 'Банківські рахунки',
      'cash_wallets': 'Готівка та гаманці',
      'add_account': 'Додати рахунок',
      'new_account': 'Новий рахунок',
      'edit_account': 'Редагувати рахунок',
      'delete_account_title': 'Видалити рахунок?',
      'delete_account_body': 'Усі транзакції на цьому рахунку буде видалено. Цю дію неможливо скасувати.',
      'account_name': 'Назва',
      'include_in_total': 'Враховувати в загальному балансі',
      'reset_all_data': 'Скинути дані на пристрої',
      'reset_all_data_subtitle': 'Видалить рахунки й операції на цьому телефоні. Хмарний акаунт не видаляється.',
      'reset_all_data_title': 'Видалити дані з пристрою?',
      'reset_all_data_body': 'На цьому телефоні буде видалено рахунки, транзакції, категорії, бюджети, борги, цілі та підписки. Налаштування і хмарний акаунт залишаться. Це не можна скасувати.',
      'reset_success': 'Дані видалено',
      'account_type': 'Тип',
      'filter_all': 'Всі',
      'filter': 'Фільтр',
      'filter_account': 'Рахунок',
      'filter_category': 'Категорія',
      'skip': 'Пропустити',
      'finish_setup': 'Готово',
      'cat_food': 'Їжа',
      'cat_transport': 'Транспорт',
      'cat_housing': 'Житло',
      'cat_health': 'Здоров\'я',
      'cat_entertainment': 'Розваги',
      'cat_clothing': 'Одяг',
      'cat_communication': 'Зв\'язок',
      'cat_education': 'Освіта',
      'cat_gifts': 'Подарунки',
      'cat_beauty': 'Краса',
      'cat_other_expense': 'Інше',
      'cat_salary': 'Зарплата',
      'cat_freelance': 'Фріланс',
      'cat_gift_income': 'Подарунок',
      'cat_investments': 'Інвестиції',
      'cat_other_income': 'Інше',
      'account_type_cash': 'Готівка',
      'account_type_card': 'Карта',
      'account_type_bank': 'Банківський рахунок',
      'account_type_ewallet': 'Ел. гаманець',
      'account_type_crypto': 'Крипта',
      'account_type_investment': 'Інвестиції',
      'account_type_loan': 'Позика/кредит',
      'tx_not_found': 'Транзакцію не знайдено',
      'tx_location': 'Місце',
      'tx_duplicate': 'Дублювати',
      'income_lower': 'дохід',
      'expense_lower': 'витрата',
      'transfer_lower': 'переказ',
      'transfer_from': 'Звідки',
      'transfer_to': 'Куди',
      'transfer_sending': 'Надсилання',
      'transfer_recipient_gets': 'Отримувач отримає',
      'exchange_rate': 'Курс обміну',
      'rate_prefix': 'Курс: 1',
      'fee': 'Комісія',
      'confirm': 'Підтвердити',
      'select_account': 'Вибрати рахунок',
      'balance_prefix': 'Баланс:',
      'new_category': 'Нова категорія',
      'edit_category': 'Редагувати категорію',
      'delete_category_title': 'Видалити категорію?',
      'color_label': 'Колір',
      'icon_label': 'Іконка',
      'title_label': 'Назва',
      'i_owe': 'Я винен',
      'owed_to_me': 'Мені винні',
      'new_debt': 'Новий борг',
      'edit_debt': 'Редагувати борг',
      'delete_debt_title': 'Видалити борг?',
      'to_from_whom': 'Кому / від кого',
      'without_due_date': 'Без терміну',
      'due_date_label': 'Термін повернення',
      'due_prefix': 'До:',
      'overdue': 'прострочено',
      'day_short': 'дн',
      'paid_of_template': 'Погашено {p} з {t}',
      'repayment': 'Повернення',
      'debts_empty_title': 'Немає боргів',
      'debts_empty_desc': 'Додайте борг, щоб вести облік позик і повернень.',
      'persons_word': 'осіб',
      'active_plural': 'активних',
      'per_month': 'на місяць',
      'per_year': 'на рік',
      'subs_empty_title': 'Немає підписок',
      'subs_empty_desc': 'Додайте Netflix, Spotify та інші сервіси,\nщоб бачити загальні витрати.',
      'next_payment_label': 'Найближчий платіж',
      'all_subscriptions': 'Усі підписки',
      'new_subscription': 'Нова підписка',
      'edit_subscription': 'Змінити підписку',
      'delete_sub_title': 'Видалити підписку?',
      'service_name': 'Назва сервісу',
      'periodicity': 'Періодичність',
      'monthly_label': 'Щомісяця',
      'yearly_label': 'Щорічно',
      'next_payment_prefix': 'Наступний платіж: ',
      'in_days_short': 'через {n} днів',
      'active_tab': 'Активні',
      'paused_tab': 'Пауза',
      'paused_plural': 'на паузі',
      'rules_empty_title': 'Немає регулярних операцій',
      'rules_empty_desc': 'Автоматизуйте регулярні платежі: оренду, рахунки, зарплату.',
      'new_rule': 'Нове правило',
      'edit_rule': 'Редагувати правило',
      'delete_rule_title': 'Видалити правило?',
      'frequency_label': 'Частота',
      'freq_daily': 'Щодня',
      'freq_weekly': 'Щотижня',
      'next_run_prefix': 'Далі:',
      'by_categories_month_prefix': 'За категоріями ·',
      'expenses_by_categories_month_prefix': 'Витрати за категоріями ·',
      'income_by_categories_month_prefix': 'Доходи за категоріями ·',
      'cash_flow_month_prefix': 'Грошовий потік ·',
      'search_currency': 'Пошук валюти',
      'popular_upper': 'ПОПУЛЯРНЕ',
      'crypto_upper': 'КРИПТОВАЛЮТА',
      'error_title': 'Щось пішло не так',
      'error_fatal_body':
          'Monedero зіткнувся з неочікуваною помилкою. Локальні дані на пристрої збережені.',
      'error_fatal_hint':
          'Повністю закрийте застосунок (проведіть у перемикачі) і відкрийте знову.',
      'add_account_first': 'Спочатку додайте рахунок',
      'account_not_found': 'Рахунок не знайдено',
      'backup_created': 'Резервну копію створено',
      'auto_backup': 'Автоматично',
      'auto_backup_desc': 'Щоденне локальне резервне копіювання',
      'create_now': 'Створити зараз',
      'local_backups_upper': 'ЛОКАЛЬНІ РЕЗЕРВНІ КОПІЇ',
      'no_backups_title': 'Немає резервних копій',
      'no_backups_desc': 'Створіть перший бекап,\nщоб зберегти дані.',
      'empty_budgets_title': 'Бюджетів ще немає',
      'spent_this_month': 'Витрачено цього місяця',
      'out_of_budget_template': 'з бюджету {}',
      'credit_limit_prefix': 'Ліміт',
      'credit_limit': 'Кредитний ліміт',
      'credit_limit_hint': 'Необов\'язково',
      'auto_cloud_backup': 'Резервне копіювання в хмару',
      'auto_cloud_backup_desc': 'Щоденне автозавантаження',
      'last_sync_prefix': 'Остання синхронізація:',
      'never_synced': 'Не синхронізовано',
      'cloud_restore_title': 'Відновити дані?',
      'cloud_restore_body':
          'Ви можете замінити локальні дані хмарною копією або завантажити локальні дані в хмару.',
      'cloud_restore_remote_meta':
          'Хмара: {date} · {a} рахунків · {t} операцій',
      'cloud_restore_local_meta':
          'Локально (буде замінено): {a} рахунків · {t} операцій',
      'cloud_restore_merge': "Об'єднати",
      'cloud_restore_merge_hint':
          'Дані з хмари + локальні операції, яких немає в хмарі.',
      'cloud_restore_merged_ok': "Дані об'єднано і завантажено в хмару",
      'cloud_restore_use_cloud': 'З хмари',
      'cloud_restore_keep_local': 'Залишити локальні',
      'delete_cloud_reset_local': 'Також стерти дані на цьому пристрої',
      'import_map_columns': 'Стовпці',
      'import_col_date': 'Дата',
      'import_col_amount': 'Сума',
      'import_col_type': 'Тип',
      'import_col_currency': 'Валюта',
      'import_col_note': 'Нотатка',
      'import_col_none': '—',
      'import_sample_rows': 'Перегляд',
      'budget_categories': 'Категорії',
      'budget_categories_all': 'Усі',
      'budget_rollover': 'Перенесення залишку',
      'budget_rollover_desc': 'Невитрачені кошти перераховуються на наступний період',
      'pick_date_range': 'Виберіть період',
      'date_from': 'З',
      'date_to': 'По',
      'export_pdf_date': 'Дата',
      'export_pdf_type': 'Тип',
      'export_pdf_amount': 'Сума',
      'export_pdf_note': 'Нотатка',
      'export_total_income': 'Загальний дохід',
      'export_total_expense': 'Усього витрат',
      'export_net': 'Баланс',
      'export_failed': 'Не вдалося експортувати',
      'form_incomplete': 'Перевірте назву та суму',
      'tags_label': 'Теги',
      'tags_hint': 'відпустка, робота…',
      'import_duplicates_skipped': 'Пропущені дублікати: {}',
      'pro_expires': 'Pro до {}',
      'pro_valid_until': 'Діє до {}',
      'pro_expires_loading': 'Завантаження дати поновлення…',
      'pro_days_left': 'Залишилося {} днів',
      'pro_manage_subscription': 'Керування підпискою',
      'shared_budget_title': 'Спільний бюджет',
      'shared_budget_subtitle': 'Відстежуйте витрати разом із партнером',
      'shared_budget_create': 'Створити спільний бюджет',
      'shared_budget_join': 'Приєднатися за кодом',
      'shared_budget_join_hint': 'Введіть код запрошення партнера',
      'shared_budget_invite_code': 'Код запрошення',
      'shared_budget_sign_in': 'Увійдіть, щоб поділитися бюджетом',
      'shared_budget_even': 'Ви в розрахунку',
      'shared_budget_sync': 'Синхронізувати щомісячні витрати',
      'shared_budget_leave': 'Вийти із спільного бюджету',
      'shared_budget_leave_title': 'Вийти зі спільного бюджету?',
      'shared_budget_leave_body': 'Ви перестанете бачити загальну суму витрат.',
      'shared_budget_code_copied': 'Код скопійовано',
      'shared_budget_invalid_code': 'Невірний код',
      'shared_budget_full': 'У цьому бюджеті вже є партнер',
      'shared_budget_already_joined': 'Ви вже в загальному бюджеті',
      'shared_budget_failed': 'Не вдалося оновити спільний бюджет',
      'shared_budget_waiting': 'Очікування партнера...',
      'shared_budget_synced': 'Синхронізовано {} витрат',
      'shared_budget_partner_owes': 'Партнер заборгував вам {}',
      'shared_budget_you_owe': 'Ви заборгували партнеру {}',
      'you_label': 'Ви',
      'pro_gate_shared_budget': 'Загальний бюджет з партнером та синхронізація витрат у хмарі.',
      'widget_budget_left': 'Залишилось',
      'widget_month_expense': 'Витрата',
      'smart_budget_title': 'Бюджет',
      'smart_budget_body': '{} майже вичерпано ({})',
      'select_short': 'Вибрати',
      'enter_note_hint': 'Введіть нотатку…',
      'backups_short': 'Резервні копії',
      'transfer_between': 'Між рахунками',
      'transfer_between_title': 'Переказ між рахунками',
      'transfer_between_short': 'Між рахунками',
      'transfer_between_tab': 'Між рахунками',
      'transfer_external': 'Зовнішній переказ',
      'transfer_external_tab': 'Зовнішній переказ',
      'transfer_between_hint': 'Переказ між рахунками. Це не дохід і не витрата.',
      'transfer_external_hint': 'Гроші виходять і вважаються витратою.',
      'quick_transfer': 'Між',
      'quick_external': 'Зовні',
      'month_balance': 'Баланс за місяць',
      'month_net': 'Разом',
      'sign_in': 'Увійти',
      'sign_in_apple': 'Продовжити з Apple',
      'sign_in_google': 'Продовжити з Google',
      'sign_in_email': 'Email і пароль',
      'register': 'Зареєструватися',
      'sign_out': 'Вийти',
      'signed_in_as': 'Ви увійшли як',
      'delete_cloud_account': 'Видалити хмарний акаунт',
      'delete_cloud_account_title': 'Видалити хмарний акаунт?',
      'delete_cloud_account_body': 'Логін (Apple, Google або електронна пошта), хмарна копія, участь у загальному бюджеті та ваші загальні витрати будуть видалені. Дані на цьому телефоні залишаться. Цю дію неможливо скасувати.',
      'delete_cloud_account_relogin': 'Підтвердіть вхід (Apple, Google або пароль), щоб видалити акаунт.',
      'delete_cloud_confirm_identity': 'Щоб видалити акаунт, підтвердіть доступ тим самим способом входу.',
      'delete_cloud_enter_password': 'Введіть пароль для підтвердження',
      'delete_cloud_account_failed': 'Не вдалося видалити акаунт',
      'delete_cloud_account_ok': 'Акаунт видалено',
      'auth_failed': 'Не вдалося увійти',
      'auth_invalid_email': 'Недійсна електронна адреса',
      'auth_weak_password': 'Пароль занадто короткий',
      'auth_wrong_password': 'Невірний email або пароль',
      'auth_user_disabled': 'Акаунт деактивовано',
      'auth_too_many': 'Забагато спроб. Пізніше',
      'auth_canceled': 'Вхід скасовано',
      'auth_email_in_use': 'Ця електронна адреса вже зареєстрована. Увійдіть.',
      'auth_network_error':
          'Немає звʼязку із сервером. Перевір інтернет на Mac або перезапусти симулятор.',
      'cloud_backup_ok': 'Копію завантажено до хмари',
      'cloud_restore_ok': 'Дані відновлено з хмари',
      'cloud_empty': 'Ще немає копії в хмарі',
      'sign_in_to_sync': 'Увійдіть, щоб синхронізувати',
      'email': 'Email',
      'password': 'Пароль',
      'firebase_not_ready': 'Ми увімкнемо хмару, коли клієнт дасть нам Firebase.',
      'cloud_backup': 'Хмарне копіювання',
      'cloud_restore': 'Відновити з хмари',
      'sync_devices': 'Синхронізація пристроїв',
      'security': 'Безпека',
      'pin_code': 'PIN-код',
      'pin_code_hint': 'Необов\'язково: якщо Face ID / Touch ID недоступні',
      'use_biometrics': 'Біометричний замок',
      'biometric_lock_hint': 'Запитувати Face ID або відбиток пальця при вході',
      'auto_lock': 'Автоматичне блокування',
      'auto_lock_hint': 'Заблокувати під час виходу з додатка',
      'biometrics_unavailable': 'Біометрія на цьому пристрої недоступна',
      'biometrics_failed': 'Не вдалося ввімкнути біометрію',
      'biometrics_need_pin': 'Спочатку створіть PIN — запасний вхід, якщо Face ID або відбиток не спрацюють',
      'enter_pin': 'Введіть PIN-код',
      'set_pin': 'Створити PIN-код',
      'confirm_pin': 'Повторіть PIN-код',
      'pin_mismatch': 'PIN-коди не збігаються',
      'pin_wrong': 'Невірний PIN-код',
      'unlock': 'Розблокувати',
      'unlock_biometric_hint': 'Використайте Face ID або відбиток пальця, щоб продовжити',
      'export_csv': 'Експорт даних',
      'export_excel': 'Експорт у Excel',
      'export_pdf': 'Експорт у PDF',
      'export_period': 'Період експорту',
      'period_this_month': 'Цей місяць',
      'period_last_month': 'Минулий місяць',
      'period_3m': '3 місяці',
      'period_6m': '6 місяців',
      'period_this_year': 'Цей рік',
      'period_last_year': 'Минулий рік',
      'period_custom': 'Свій період',
      'choose_period': 'Виберіть період',
      'restore_local': 'Відновити',
      'data_restored': 'Дані відновлено',
      'restore_failed': 'Не вдалося відновити',
      'import_backup_json': 'Імпортувати копію JSON',
      'cloud_backup_failed': 'Не вдалося зберегти хмарну копію',
      'fx_approximate_balance': 'Курси недоступні · орієнтовний баланс',
      'import_no_accounts': 'Спочатку створіть рахунок',
      'import_no_rows': 'У файлі не знайдено транзакцій',
      'data_load_db_error': 'Не вдалося прочитати локальну базу даних',
      'data_load_network_error': 'Помилка завантаження даних',
      'data_load_generic_error': 'Помилка під час завантаження: {}',
      'firebase_offline_banner': 'Немає з\'єднання з Firebase: вхід, хмара та ШІ недоступні',
      'data_init_failed_banner': 'Помилка локальних даних, перезапустіть програму',
      'account_section': 'Акаунт',
      'pro_title': 'Monedero Pro',
      'pro_subtitle':
          'Отримайте доступ до всіх функцій застосунку без обмежень.',
      'pro_features_heading': 'ВКЛЮЧЕНІ ФУНКЦІЇ',
      'pro_paywall_trial_footnote':
          'Безкоштовний період, потім автопродовження',
      'pro_start_free_trial': 'Почати безкоштовний період',
      'pro_trial_badge': '{} ДНІВ БЕЗКОШТОВНО',
      'pro_discount_badge': '−{}%',
      'pro_all_features': 'Усі функції',
      'pro_feature_ai_chat': 'ШІ-асистент у чаті',
      'pro_feature_ai_quality': 'Преміальна якість і швидкість ШІ',
      'pro_feature_ai_receipts': 'Сканування чеків з ШІ',
      'pro_feature_ai_voice': 'Голосовий ввід з ШІ',
      'pro_feature_accounts': 'Рахунки без обмежень',
      'pro_feature_budgets': 'Бюджети без обмежень',
      'pro_feature_goals': 'Фінансові цілі без обмежень',
      'pro_feature_debts': 'Борги без обмежень',
      'pro_feature_stats': 'Детальна статистика та звіти',
      'pro_feature_trends': 'Аналіз фінансових трендів',
      'pro_feature_cashflow': 'Грошові потоки',
      'pro_feature_shared_budget': 'Спільний бюджет з партнером',
      'pro_feature_reminder_payments': 'Нагадування про платежі',
      'pro_feature_reminder_subs': 'Нагадування про підписки',
      'pro_feature_reminder_goals': 'Нагадування про фінансові цілі',
      'pro_feature_cloud_backup': 'Хмарні резервні копії',
      'pro_feature_sync': 'Синхронізація між пристроями',
      'pro_feature_export_excel': 'Експорт у Excel',
      'pro_feature_export_pdf': 'Експорт у PDF',
      'pro_feature_import_csv': 'Імпорт даних з CSV',
      'pro_feature_no_ads': 'Без реклами',
      'pro_cta_subtitle': 'Необмежений доступ',
      'pro_go': 'Оновити до Pro',
      'pro_restore': 'Відновити покупки',
      'pro_sign_in_required': 'Увійдіть в акаунт, щоб активувати Pro',
      'pro_restore_empty': 'Активних покупок не знайдено',
      'pro_restore_ok': 'Покупки відновлено',
      'pro_legal_notice': 'Платіж буде стягнуто з вашого Apple ID. Підписка поновлюється автоматично, якщо її не скасовано принаймні за 24 години до закінчення періоду. Керування: налаштування → підписки → Apple ID. Придбання протягом пробного періоду скасує решту пробних днів. Продовжуючи, ви погоджуєтеся з Умовами використання та Політикою конфіденційності.',
      'pro_legal_notice_android':
          'Платіж буде стягнуто з вашого облікового запису Google Play. Підписка поновлюється автоматично, якщо її не скасовано принаймні за 24 години до закінчення періоду. Керування: Google Play → Платежі та підписки → Підписки. Продовжуючи, ви погоджуєтеся з Умовами використання та Політикою конфіденційності.',
      'pro_yearly': 'На рік',
      'pro_monthly': 'На місяць',
      'pro_semi_annual': '6 місяців',
      'pro_yearly_save': '−48%',
      'pro_yearly_save_pct': '−{}%',
      'pro_trial': '7 днів безкоштовно',
      'pro_trial_days': '{} днів безкоштовно',
      'pro_active': 'Monedero Pro активний',
      'pro_active_short': 'Активний',
      'pro_buy_failed': 'Не вдалося завершити покупку',
      'pro_store_empty': 'Ціни зараз недоступні. Перевірте інтернет і спробуйте ще раз.',
      'pro_debug_unlock': 'Відкрити Pro (debug)',
      'import_csv': 'Імпортувати CSV',
      'import_csv_hint': 'Імпорт CSV Monedero або банківської виписки з датою та сумою.',
      'import_pick_file': 'Вибрати файл',
      'import_preview': '{n} транзакцій готово · {s} рядків пропущено',
      'import_confirm': 'Імпортувати',
      'import_failed': 'Не вдалося імпортувати файл: {}',
      'import_done': 'Імпортовано {} транзакцій',
      'reminders_page_hint': 'Налаштуйте, коли нагадувати про витрати. Розумні сповіщення — лише в Pro.',
      'daily_reminder_section': 'Щоденне нагадування',
      'smart_reminders': 'Розумні нагадування',
      'smart_reminders_hint': 'Платежі, підписки та цілі',
      'smart_reminders_desc': 'Нагадаємо в день виникнення заборгованості, за день до списання підписки та за цілями з бюджетами.',
      'smart_debt_title': 'Сплата боргу',
      'smart_debt_body': 'До сплати сьогодні: {}',
      'smart_sub_title': 'Підписка',
      'smart_sub_body': 'Незабаром спишеться: {}',
      'smart_goal_title': 'Ціль',
      'smart_goal_body': 'Перевірте ціль: {}',
      'pro_gate_accounts': 'У безкоштовній версії — до 3 рахунків.\nПерейдіть на Pro для необмеженої кількості.',
      'pro_gate_goals': 'У безкоштовній версії доступно до 2 активних цілей.\nПерейдіть на Pro, щоб створити необмежену кількість цілей.',
      'pro_gate_budgets': 'У безкоштовній версії доступно до 3 активних бюджетів.\nПерейдіть на Pro, щоб створювати необмежені бюджети.',
      'pro_gate_debts': 'У безкоштовній версії доступно до 2 активних боргів.\nПерейдіть на Pro, щоб додати необмежену кількість боргів.',
      'pro_gate_subscriptions': 'У безкоштовній версії доступно до 3 активних підписок.\nОновіть до Pro, щоб додати необмежену кількість підписок.',
      'pro_gate_recurring': 'У безкоштовній версії доступно до 3 повторюваних операцій.\nОновіть до Pro, щоб додати необмежену кількість повторюваних операцій.',
      'pro_gate_analytics': 'Розширена аналітика доступна в Pro.\nПерейдіть на Pro, щоб проаналізувати свої фінанси за 3, 6 та 12 місяців.',
      'pro_gate_trends': 'Розширений аналіз тенденцій доступний в Pro.\nПерейдіть до Pro, щоб відстежувати зміни в доходах і витратах.',
      'pro_gate_flows': 'Розширений аналіз грошових потоків доступний в Pro.\nПерейдіть до Pro, щоб детально проаналізувати рух своїх грошей.',
      'pro_gate_currencies': 'У безкоштовній версії доступна 1 основна валюта.\nПерейдіть до Pro, щоб використовувати кілька валют і рахунків у різних валютах.',
      'pro_gate_cloud': 'Хмарні копії доступні в Pro.\nЗберігайте свої фінансові дані в хмарі та відновлюйте їх на будь-якому пристрої.',
      'pro_gate_sync': 'Синхронізація між пристроями доступна в Pro.\nПерейдіть до Pro, щоб синхронізувати фінансові дані на різних пристроях.',
      'pro_gate_excel': 'Експорт до Excel доступний у програмі Pro.\nПерейдіть на Pro, щоб експортувати фінансові дані в Excel.',
      'pro_gate_pdf': 'Експорт у PDF доступний у програмі Pro.\nПерейдіть на Pro, щоб створювати PDF-звіти про свої фінанси.',
      'pro_gate_reminders': 'Нагадування доступні в Pro.\nПерейдіть на Pro, щоб отримувати нагадування про платежі, підписки та фінансові цілі.',
      'pro_gate_import': 'Імпорт файлів CSV та виписок доступний у програмі Pro.\nПерейдіть до Pro, щоб імпортувати транзакції.',
      'pro_gate_ai': 'Асистент ШІ (голос, чеки, чат) доступний у Pro.\nУвійдіть у акаунт і перейдіть на Pro.',
      'ai_recognize_receipt': 'Розпізнати чек',
      'ai_voice_entry': 'Запис голосом',
      'ai_voice_empty_title': 'Ще немає транзакцій',
      'ai_voice_empty_hint': 'Асистент ШІ — скажіть операцію, я її збережу.',
      'ai_voice_hint': 'Скажіть: я витратив 10 на таксі та 20 на їжу',
      'ai_voice_confirm_title': 'Підтвердження',
      'ai_voice_confirm_count': '{} транзакції',
      'ai_voice_approve': 'Схвалити',
      'ai_voice_saved': 'Збережено транзакцій: {}',
      'ai_listening': 'Слухаю…',
      'ai_confirm_transcript': 'Використати цей текст?',
      'ai_use_transcript': 'Використати',
      'ai_category_suggest': 'ШІ пропонує: {}',
      'ai_apply_category': 'Застосувати',
      'ai_insight_title': 'ШІ-аналіз фінансів',
      'ai_insight_generate': 'Згенерувати',
      'ai_insight_hint': 'Доходи, витрати та ключові зміни.',
      'ai_chat_title': 'Асистент',
      'ai_chat_hint': 'Голос, фото або текст — запишу витрати та доходи.',
      'ai_chat_placeholder': 'Повідомлення',
      'ai_chat_welcome': 'Вітаю! Я ваш фінансовий помічник. Можу записати витрату чи дохід — напишіть «Кава 60» або «Зарплата 25000». Можна надіслати фото чека, сказати голосом або запитати про дані в додатку.',
      'ai_clear_chat': 'Очистити чат',
      'ai_clear_chat_title': 'Очистити чат?',
      'ai_clear_chat_body':
          'Історію цього чату буде видалено на пристрої та в хмарі. Скасувати неможливо.',
      'ai_assistant_eyebrow': 'ШІ',
      'ai_recording': 'Запис…',
      'ai_chat_receipt_sent': 'Чек надіслано',
      'ai_receipt_unreadable': 'Не вдалося прочитати чек. Спробуйте інше фото або надішліть текстом.',
      'ai_assistant_recorded': 'Записано {} операцій на {}',
      'ai_assistant_receipt_saved': 'Витрату з чека збережено: {}',
      'ai_busy': 'Думаю…',
      'ai_parsing': 'Розбираю операції…',
      'ai_failed': 'Не вдалося виконати запит до ШІ. Спробуйте ще раз.',
      'ai_blocked': 'ШІ заблокував відповідь. Переформулюйте повідомлення.',
      'ai_empty_response': 'ШІ повернув порожню відповідь. Спробуйте ще раз.',
      'ai_invalid_response': 'ШІ повернув неочікуваний формат. Спробуйте ще раз.',
      'ai_speech_unavailable': 'Мікрофон недоступний. Введіть текст або спробуйте на справжньому iPhone.',
      'ai_api_not_enabled': 'Увімкніть Gemini / Firebase AI у консолі Firebase.',
      'ai_permission_denied': 'Firebase відхилила ШІ (App Check). У debug: скопіюйте токен із логів і додайте в Firebase → App Check → Debug tokens.',
      'ai_quota_exceeded': 'Ліміт ШІ вичерпано. Спробуйте пізніше.',
      'ai_billing_depleted':
          'ШІ-асистент тимчасово недоступний. Спробуйте пізніше.',
      'ai_filled': 'Поля заповнено за допомогою ШІ',
      'ai_energy_empty': 'Енергію вичерпано. Перейдіть на Pro для необмеженого асистента.',
      'ai_energy_hint':
          'Енергія асистента: {} з 100. Pro — безліміт.',
      'pro_badge': 'PRO',
    },
  };
}
