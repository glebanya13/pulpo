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
      _dict[_lang]?[key] ?? _dict['es']![key] ?? key;

  /// Возвращает переведённое название категории по slug ('food', 'transport'...).
  /// Старые записи с именем «Comida» / «Еда» тоже находятся.
  String categoryName(String slugOrName) {
    final slug = _resolveCategorySlug(slugOrName);
    final key = 'cat_$slug';
    return _dict[_lang]?[key] ?? _dict['es']?[key] ?? slugOrName;
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
  String get authFailed => _get('auth_failed');
  String get authInvalidEmail => _get('auth_invalid_email');
  String get authWeakPassword => _get('auth_weak_password');
  String get authWrongPassword => _get('auth_wrong_password');
  String get authUserDisabled => _get('auth_user_disabled');
  String get authTooMany => _get('auth_too_many');
  String get authCanceled => _get('auth_canceled');
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
  String get enterPin => _get('enter_pin');
  String get setPin => _get('set_pin');
  String get confirmPin => _get('confirm_pin');
  String get pinMismatch => _get('pin_mismatch');
  String get pinWrong => _get('pin_wrong');
  String get unlock => _get('unlock');
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
  String get restoreLocal => _get('restore_local');
  String get dataRestored => _get('data_restored');
  String get restoreFailed => _get('restore_failed');
  String get accountSection => _get('account_section');

  // ─────────────────────── BOTTOM NAV / SECTIONS ───────────────────────
  String get home => _get('home');
  String get transactions => _get('transactions');
  String get analytics => _get('analytics');
  String get profile => _get('profile');

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
  String get noTxThisDay => _get('no_tx_this_day');

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
  String get pleaseEnterName => _get('please_enter_name');
  String get setupTitle => _get('setup_title');
  String get setupSubtitle => _get('setup_subtitle');
  String get initialBalance => _get('initial_balance');
  String get currency => _get('currency');

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
  String incomeVsForPeriod(String period) =>
      _get('income_vs_expenses').replaceAll('{}', period);
  String get byCategoriesTitle => _get('by_categories');
  String get totalWord => _get('total_word');
  String get expensesByCategories => _get('expenses_by_categories');
  String get noExpensesThisMonth => _get('no_expenses_this_month');
  String noExpensesForPeriod(String period) =>
      _get('no_expenses_period').replaceAll('{}', period);
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
  String get netWorth => _get('net_worth');
  String get inRealtime => _get('in_realtime');
  String get history12Weeks => _get('history_12_weeks');
  String get offlineFirstTag => _get('offline_first_tag');
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
  String get cashFlowMonthPrefix => _get('cash_flow_month_prefix');

  // ─────────────────────── CURRENCY PICKER ───────────────────────
  String get searchCurrency => _get('search_currency');
  String get popularUpper => _get('popular_upper');
  String get cryptoUpper => _get('crypto_upper');

  // ─────────────────────── COMMON / ERROR ───────────────────────
  String get errorTitle => _get('error_title');
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
  String get tagsLabel => _get('tags_label');
  String get tagsHint => _get('tags_hint');
  String proExpires(String date) => _get('pro_expires').replaceAll('{}', date);
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
  String get proGo => _get('pro_go');
  String get proRestore => _get('pro_restore');
  String get proSignInRequired => _get('pro_sign_in_required');
  String get proRestoreEmpty => _get('pro_restore_empty');
  String get proLegalNotice => _get('pro_legal_notice');
  String get proYearly => _get('pro_yearly');
  String get proMonthly => _get('pro_monthly');
  String get proSemiAnnual => _get('pro_semi_annual');
  String get proYearlySave => _get('pro_yearly_save');
  String get proTrial => _get('pro_trial');
  String get proActive => _get('pro_active');
  String get proActiveShort => _get('pro_active_short');
  String get proBuyFailed => _get('pro_buy_failed');
  String get proStoreEmpty => _get('pro_store_empty');
  String get proDebugUnlock => _get('pro_debug_unlock');
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
  String get smartReminders => _get('smart_reminders');
  String get smartRemindersHint => _get('smart_reminders_hint');
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
      'no_tx_this_day': 'Sin transacciones este día',
      'weekday_mon': 'L',
      'weekday_tue': 'M',
      'weekday_wed': 'X',
      'weekday_thu': 'J',
      'weekday_fri': 'V',
      'weekday_sat': 'S',
      'weekday_sun': 'D',
      // profile
      'management': 'GESTIÓN',
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
      'try_demo': 'Probar sin cuenta',
      'continue_without_account': 'Continuar sin iniciar sesión',
      'please_enter_name': 'Por favor, introduce tu nombre',
      'setup_title': 'Un poco sobre ti',
      'setup_subtitle':
          'Rellena los datos — se guardarán solo en tu dispositivo',
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
      'by_categories': 'Por categoría',
      'total_word': 'total',
      'expenses_by_categories': 'Gastos por categoría',
      'no_expenses_this_month': 'Sin gastos este mes',
      'no_expenses_period': 'Sin gastos · {}',
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
      'net_worth': 'PATRIMONIO NETO',
      'in_realtime': '↑ en tiempo real',
      'history_12_weeks': '12 semanas',
      'offline_first_tag': 'Pulpo · offline-first',
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
      'rules_empty_title': 'Sin reglas',
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
      'cash_flow_month_prefix': 'Flujo de caja · ',
      // currency picker
      'search_currency': 'Buscar moneda',
      'popular_upper': 'POPULARES',
      'crypto_upper': 'CRIPTO',
      // common error
      'error_title': 'Algo salió mal',
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
      'auto_cloud_backup_desc': 'Subida diaria automática (Pro)',
      'last_sync_prefix': 'Última sync: ',
      'never_synced': 'Aún no sincronizado',
      'cloud_restore_title': '¿Restaurar datos?',
      'cloud_restore_body':
          'Puedes reemplazar los datos locales con la copia en la nube o subir los datos locales a la nube.',
      'cloud_restore_use_cloud': 'Usar nube',
      'cloud_restore_keep_local': 'Mantener local',
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
      'tags_label': 'Etiquetas',
      'tags_hint': 'viaje, trabajo…',
      'import_duplicates_skipped': 'Duplicados omitidos: {}',
      'pro_expires': 'Pro activo hasta {}',
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
          'Por seguridad, inicia sesión otra vez y vuelve a intentar. Apple y Google piden una sesión reciente.',
      'delete_cloud_account_failed': 'No se pudo eliminar la cuenta',
      'auth_failed': 'No se pudo iniciar sesión',
      'auth_invalid_email': 'Email no válido',
      'auth_weak_password': 'La contraseña es demasiado corta',
      'auth_wrong_password': 'Email o contraseña incorrectos',
      'auth_user_disabled': 'Esta cuenta está desactivada',
      'auth_too_many': 'Demasiados intentos. Prueba más tarde',
      'auth_canceled': 'Inicio de sesión cancelado',
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
      'enter_pin': 'Introduce el PIN',
      'set_pin': 'Crear PIN',
      'confirm_pin': 'Confirma el PIN',
      'pin_mismatch': 'Los PIN no coinciden',
      'pin_wrong': 'PIN incorrecto',
      'unlock': 'Desbloquear',
      'export_csv': 'Exportar CSV',
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
      'restore_local': 'Restaurar',
      'data_restored': 'Datos restaurados',
      'restore_failed': 'No se pudo restaurar',
      'account_section': 'Cuenta',
      'pro_title': 'Pulpo Pro',
      'pro_subtitle':
          'Sin límites en cuentas, metas, informes, importación y copias en la nube.',
      'pro_go': 'Pasar a Pro',
      'pro_restore': 'Restaurar compras',
      'pro_sign_in_required': 'Inicia sesión para activar Pro',
      'pro_restore_empty': 'No se encontraron compras activas',
      'pro_legal_notice':
          'El pago se carga a tu Apple ID. La suscripción se renueva automáticamente salvo que la canceles al menos 24 h antes del final del periodo. Gestiona o cancela en Ajustes → Apple ID → Suscripciones. Si compras durante la prueba, pierdes el resto de días gratis. Al continuar aceptas los Términos y la Política de privacidad.',
      'pro_yearly': 'Anual',
      'pro_monthly': 'Mensual',
      'pro_semi_annual': '6 meses',
      'pro_yearly_save': 'Ahorra 44%',
      'pro_trial': '7 días de prueba gratis',
      'pro_active': 'Pulpo Pro está activo',
      'pro_active_short': 'Activo',
      'pro_buy_failed': 'No se pudo completar la compra',
      'pro_store_empty':
          'Los precios no están disponibles ahora. Comprueba la conexión e inténtalo de nuevo.',
      'pro_debug_unlock': 'Desbloquear Pro (debug)',
      'import_csv': 'Importar CSV',
      'import_csv_hint':
          'Importa un CSV de Pulpo o un extracto bancario con fecha e importe.',
      'import_pick_file': 'Elegir archivo',
      'import_preview': '{n} movimientos listos · {s} filas omitidas',
      'import_confirm': 'Importar',
      'import_failed': 'No se pudo importar el archivo',
      'import_done': 'Importadas {} transacciones',
      'smart_reminders': 'Recordatorios inteligentes',
      'smart_reminders_hint':
          'Avisos de deudas, suscripciones y metas (Pro)',
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
    },
    'ru': {
      // common
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'delete_tx_title': 'Удалить транзакцию?',
      'delete_tx_body': 'Это действие нельзя отменить.',
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
      'no_tx_this_day': 'Транзакций за этот день нет',
      'weekday_mon': 'Пн',
      'weekday_tue': 'Вт',
      'weekday_wed': 'Ср',
      'weekday_thu': 'Чт',
      'weekday_fri': 'Пт',
      'weekday_sat': 'Сб',
      'weekday_sun': 'Вс',
      // profile
      'management': 'УПРАВЛЕНИЕ',
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
      'try_demo': 'Открыть без аккаунта',
      'continue_without_account': 'Продолжить без входа',
      'please_enter_name': 'Пожалуйста, введите имя',
      'setup_title': 'Немного о вас',
      'setup_subtitle':
          'Заполните данные — это сохранится только на вашем устройстве',
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
      'by_categories': 'По категориям',
      'total_word': 'всего',
      'expenses_by_categories': 'Расходы по категориям',
      'no_expenses_this_month': 'Нет расходов за этот месяц',
      'no_expenses_period': 'Нет расходов · {}',
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
      'net_worth': 'ЧИСТЫЙ КАПИТАЛ',
      'in_realtime': '↑ в реальном времени',
      'history_12_weeks': '12 недель',
      'offline_first_tag': 'Pulpo · офлайн',
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
      'rules_empty_title': 'Правил нет',
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
      'cash_flow_month_prefix': 'Денежный поток · ',
      // currency picker
      'search_currency': 'Поиск валюты',
      'popular_upper': 'ПОПУЛЯРНЫЕ',
      'crypto_upper': 'КРИПТО',
      // common error
      'error_title': 'Что-то пошло не так',
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
      'auto_cloud_backup_desc': 'Ежедневная автозагрузка (Pro)',
      'last_sync_prefix': 'Последняя sync: ',
      'never_synced': 'Ещё не синхронизировано',
      'cloud_restore_title': 'Восстановить данные?',
      'cloud_restore_body':
          'Можно заменить локальные данные облачной копией или загрузить локальные данные в облако.',
      'cloud_restore_use_cloud': 'Из облака',
      'cloud_restore_keep_local': 'Оставить локальные',
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
      'tags_label': 'Теги',
      'tags_hint': 'отпуск, работа…',
      'import_duplicates_skipped': 'Пропущено дубликатов: {}',
      'pro_expires': 'Pro до {}',
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
          'Из соображений безопасности войдите ещё раз и повторите. Apple и Google требуют недавний вход.',
      'delete_cloud_account_failed': 'Не удалось удалить аккаунт',
      'auth_failed': 'Не удалось войти',
      'auth_invalid_email': 'Некорректный email',
      'auth_weak_password': 'Пароль слишком короткий',
      'auth_wrong_password': 'Неверный email или пароль',
      'auth_user_disabled': 'Аккаунт отключён',
      'auth_too_many': 'Слишком много попыток. Позже',
      'auth_canceled': 'Вход отменён',
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
      'enter_pin': 'Введите PIN',
      'set_pin': 'Создать PIN',
      'confirm_pin': 'Повторите PIN',
      'pin_mismatch': 'PIN не совпадает',
      'pin_wrong': 'Неверный PIN',
      'unlock': 'Разблокировать',
      'export_csv': 'Экспорт CSV',
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
      'restore_local': 'Восстановить',
      'data_restored': 'Данные восстановлены',
      'restore_failed': 'Не удалось восстановить',
      'account_section': 'Аккаунт',
      'pro_title': 'Pulpo Pro',
      'pro_subtitle':
          'Без лимитов на счета, цели, отчёты, импорт и облачные копии.',
      'pro_go': 'Перейти на Pro',
      'pro_restore': 'Восстановить покупки',
      'pro_sign_in_required': 'Войдите в аккаунт, чтобы активировать Pro',
      'pro_restore_empty': 'Активных покупок не найдено',
      'pro_legal_notice':
          'Оплата списывается с Apple ID. Подписка продлевается автоматически, если не отменить её минимум за 24 часа до конца периода. Управление: Настройки → Apple ID → Подписки. Покупка во время пробного периода отменяет оставшиеся дни триала. Продолжая, вы принимаете Условия использования и Политику конфиденциальности.',
      'pro_yearly': 'На год',
      'pro_monthly': 'На месяц',
      'pro_semi_annual': '6 месяцев',
      'pro_yearly_save': '−44%',
      'pro_trial': '7 дней бесплатно',
      'pro_active': 'Pulpo Pro активен',
      'pro_active_short': 'Активен',
      'pro_buy_failed': 'Не удалось завершить покупку',
      'pro_store_empty':
          'Цены сейчас недоступны. Проверьте интернет и попробуйте снова.',
      'pro_debug_unlock': 'Открыть Pro (debug)',
      'import_csv': 'Импорт CSV',
      'import_csv_hint':
          'Импортируйте CSV Pulpo или банковскую выписку с датой и суммой.',
      'import_pick_file': 'Выбрать файл',
      'import_preview': '{n} операций готово · {s} строк пропущено',
      'import_confirm': 'Импортировать',
      'import_failed': 'Не удалось импортировать файл',
      'import_done': 'Импортировано {} операций',
      'smart_reminders': 'Умные напоминания',
      'smart_reminders_hint':
          'Платежи, подписки и цели (Pro)',
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
    },
    'en': {
      // common
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'delete_tx_title': 'Delete transaction?',
      'delete_tx_body': 'This action cannot be undone.',
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
      'no_tx_this_day': 'No transactions on this day',
      'weekday_mon': 'Mo',
      'weekday_tue': 'Tu',
      'weekday_wed': 'We',
      'weekday_thu': 'Th',
      'weekday_fri': 'Fr',
      'weekday_sat': 'Sa',
      'weekday_sun': 'Su',
      // profile
      'management': 'MANAGEMENT',
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
      'try_demo': 'Try without an account',
      'continue_without_account': 'Continue without signing in',
      'please_enter_name': 'Please enter your name',
      'setup_title': 'A bit about you',
      'setup_subtitle':
          "Fill in the details — it's saved only on your device",
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
      'by_categories': 'By category',
      'total_word': 'total',
      'expenses_by_categories': 'Expenses by category',
      'no_expenses_this_month': 'No expenses this month',
      'no_expenses_period': 'No expenses · {}',
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
      'net_worth': 'NET WORTH',
      'in_realtime': '↑ live',
      'history_12_weeks': '12 weeks',
      'offline_first_tag': 'Pulpo · offline-first',
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
      'rules_empty_title': 'No rules',
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
      'cash_flow_month_prefix': 'Cash flow · ',
      // currency picker
      'search_currency': 'Search currency',
      'popular_upper': 'POPULAR',
      'crypto_upper': 'CRYPTO',
      // common error
      'error_title': 'Something went wrong',
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
      'auto_cloud_backup_desc': 'Daily automatic upload (Pro)',
      'last_sync_prefix': 'Last sync: ',
      'never_synced': 'Not synced yet',
      'cloud_restore_title': 'Restore data?',
      'cloud_restore_body':
          'Replace local data with the cloud copy, or upload local data to the cloud.',
      'cloud_restore_use_cloud': 'Use cloud',
      'cloud_restore_keep_local': 'Keep local',
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
      'tags_label': 'Tags',
      'tags_hint': 'trip, work…',
      'import_duplicates_skipped': 'Duplicates skipped: {}',
      'pro_expires': 'Pro until {}',
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
          'For security, sign in again and retry. Apple and Google require a recent login.',
      'delete_cloud_account_failed': 'Could not delete account',
      'auth_failed': 'Could not sign in',
      'auth_invalid_email': 'Invalid email',
      'auth_weak_password': 'Password is too short',
      'auth_wrong_password': 'Wrong email or password',
      'auth_user_disabled': 'This account is disabled',
      'auth_too_many': 'Too many attempts. Try later',
      'auth_canceled': 'Sign-in cancelled',
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
      'enter_pin': 'Enter PIN',
      'set_pin': 'Create PIN',
      'confirm_pin': 'Confirm PIN',
      'pin_mismatch': 'PINs do not match',
      'pin_wrong': 'Wrong PIN',
      'unlock': 'Unlock',
      'export_csv': 'Export CSV',
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
      'restore_local': 'Restore',
      'data_restored': 'Data restored',
      'restore_failed': 'Could not restore',
      'account_section': 'Account',
      'pro_title': 'Pulpo Pro',
      'pro_subtitle':
          'Unlimited accounts, goals, reports, import and cloud backups.',
      'pro_go': 'Go Pro',
      'pro_restore': 'Restore purchases',
      'pro_sign_in_required': 'Sign in to activate Pro',
      'pro_restore_empty': 'No active purchases found',
      'pro_legal_notice':
          'Payment will be charged to your Apple ID. Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple ID → Subscriptions. Any unused free trial is forfeited when you purchase. By continuing you agree to the Terms of Use and Privacy Policy.',
      'pro_yearly': 'Yearly',
      'pro_monthly': 'Monthly',
      'pro_semi_annual': '6 months',
      'pro_yearly_save': 'Save 44%',
      'pro_trial': '7-day free trial',
      'pro_active': 'Pulpo Pro is active',
      'pro_active_short': 'Active',
      'pro_buy_failed': 'Could not complete the purchase',
      'pro_store_empty':
          'Prices are unavailable right now. Check your connection and try again.',
      'pro_debug_unlock': 'Unlock Pro (debug)',
      'import_csv': 'Import CSV',
      'import_csv_hint':
          'Import a Pulpo CSV or a bank statement with date and amount.',
      'import_pick_file': 'Choose file',
      'import_preview': '{n} transactions ready · {s} rows skipped',
      'import_confirm': 'Import',
      'import_failed': 'Could not import the file',
      'import_done': 'Imported {} transactions',
      'smart_reminders': 'Smart reminders',
      'smart_reminders_hint':
          'Debts, subscriptions and goals (Pro)',
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
    },
  };
}
