import '../../core/ai/ai_models.dart';
import '../../core/ai/ai_record_hint.dart';
import '../../core/l10n/tr.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';

/// Expense vs income list for a period query.
enum PeriodListKind { expense, income }

/// Parsed “show my expenses/income for …” request.
class ExpensePeriodQuery {
  const ExpensePeriodQuery({
    required this.from,
    required this.to,
    required this.daySpan,
    required this.labelKey,
    this.kind = PeriodListKind.expense,
    this.confident = true,
  });

  /// Inclusive calendar-day start (local).
  final DateTime from;

  /// Inclusive calendar-day end (local).
  final DateTime to;

  /// Approximate day count for labels (7, 14, …).
  final int daySpan;

  /// Stable key: `two_weeks` | `week` | `weeks` | `month` | `days` | `all`.
  final String labelKey;

  /// Whether the user asked for expenses or income.
  final PeriodListKind kind;

  /// False when we only guessed the default 14-day window — prefer AI refine.
  final bool confident;

  bool get isAllTime => labelKey == 'all';
  bool get isIncome => kind == PeriodListKind.income;
}

/// Format a date for chat expense tables.
/// Same calendar year as [now] → `DD/MM`; otherwise `DD/MM/YY` (so 2025 ≠ 2026).
String formatExpenseTableDate(DateTime date, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  if (date.year == n.year) return '$d/$m';
  final yy = (date.year % 100).toString().padLeft(2, '0');
  return '$d/$m/$yy';
}

bool _mentionsIncome(String t) => RegExp(
      r'(ganancias?|ingresos?|income|earnings?|revenue|'
      r'доход|доходи|приход|зарплат|заробіт|заработ)',
    ).hasMatch(t);

bool _mentionsExpenses(String t) => RegExp(
      r'(gastos?|expenses?|расход|трат|витрат|потрат|'
      r'movimientos?|операц|транзакц|transactions?|данн|дані|datos?)',
    ).hasMatch(t);

bool _asksList(String t) => RegExp(
      r'(dame|escr[ií]b|mu[eé]stra|lista|list|show|write|d[aá]j|дай|'
      r'покаж|напиш|какие|що\s+я|что\s+я|cu[aá]les|tabla|таблиц|'
      r'ver|see|look|посмотр|'
      r'todas?|all|все|усі|'
      r'últim|ultim|last|посл|recient|recent|'
      r'dos\s+semanas|two\s+weeks|две\s+недел|'
      r'esta\s+semana|this\s+week|эту\s+недел|цей\s+тижд|'
      r'este\s+mes|this\s+month|этот\s+месяц|цей\s+місяц)',
    ).hasMatch(t);

PeriodListKind? _detectListKind(String t) {
  final income = _mentionsIncome(t);
  final expense = _mentionsExpenses(t);
  if (income && !expense) return PeriodListKind.income;
  if (expense && !income) return PeriodListKind.expense;
  if (income) return PeriodListKind.income;
  if (expense) return PeriodListKind.expense;
  return null;
}

/// True when the user asks to list / show expenses, income, or transactions.
bool looksLikeExpenseListQuestion(String text) {
  final t = text.trim().toLowerCase();
  if (t.length < 4 || t.length > 240) return false;
  // Recording with an amount should not become a list query.
  if (looksLikeTransactionRecord(t) && RegExp(r'\d').hasMatch(t)) {
    if (RegExp(
      r'(€|\$|£|₴|₽)|(\d+[.,]?\d*\s*(eur|usd|€))',
    ).hasMatch(t)) {
      return false;
    }
  }
  if (looksLikeAffordabilityQuestion(t)) return false;

  final kind = _detectListKind(t);
  // Require an explicit type word — bare “últimos N días” used to hijack
  // income asks into expense tables with a default 2-week window.
  if (kind != null && _asksList(t)) return true;
  return false;
}

/// “How many transactions have I made?” — count, not a table.
bool looksLikeTransactionCountQuestion(String text) {
  final t = text.trim().toLowerCase();
  if (t.length < 5 || t.length > 200) return false;
  if (looksLikeTransactionRecord(t)) return false;
  final asksCount = RegExp(
    r'(сколько|скільки|how\s+many|cu[aá]nt[ao]s?|количество|кількість)',
  ).hasMatch(t);
  final mentionsTx = RegExp(
    r'(транзакц|операц|transactions?|movimientos?|gastos?\s+registr|записей)',
  ).hasMatch(t);
  return asksCount && mentionsTx;
}

/// Parse a relative expense/income period from natural language.
ExpensePeriodQuery? parseExpensePeriodQuery(String text) {
  if (!looksLikeExpenseListQuestion(text)) return null;

  final t = text.trim().toLowerCase();
  final kind = _detectListKind(t) ?? PeriodListKind.expense;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime startDaysAgo(int daysInclusive) {
    final n = daysInclusive.clamp(1, 3660);
    return today.subtract(Duration(days: n - 1));
  }

  ExpensePeriodQuery make({
    required DateTime from,
    required DateTime to,
    required int daySpan,
    required String labelKey,
    bool confident = true,
  }) {
    return ExpensePeriodQuery(
      from: from,
      to: to,
      daySpan: daySpan,
      labelKey: labelKey,
      kind: kind,
      confident: confident,
    );
  }

  if (RegExp(
    r'(todas?\s+(las\s+)?(transacciones|operaciones|gastos|ganancias|ingresos)|'
    r'all\s+(my\s+)?(transactions|expenses|income|earnings)|'
    r'(все|всем[а-яёії]*)\s+(мои\s+)?(транзакц|операц|расход|доход)|'
    r'усі\s+(мої\s+)?(транзакц|операц|витрат|доход)|'
    r'sin\s+l[ií]mite|за\s+вс[её]\s+время|за\s+весь\s+период)',
  ).hasMatch(t)) {
    return make(
      from: DateTime(2000, 1, 1),
      to: today,
      daySpan: 9999,
      labelKey: 'all',
    );
  }

  // N days (digits or words) — before weeks so "tres días" ≠ weeks.
  final days = _parseDayCount(t);
  if (days != null) {
    return make(
      from: startDaysAgo(days),
      to: today,
      daySpan: days.clamp(1, 366),
      labelKey: 'days',
    );
  }

  final weeks = _parseWeekCount(t);
  if (weeks != null) {
    final weekDays = (weeks * 7).clamp(7, 366);
    return make(
      from: startDaysAgo(weekDays),
      to: today,
      daySpan: weekDays,
      labelKey: weeks == 1
          ? 'week'
          : (weeks == 2 ? 'two_weeks' : 'weeks'),
    );
  }

  if (RegExp(
    r'(esta\s+semana|this\s+week|эту\s+недел|этой\s+недел|цей\s+тижд|'
    r'última\s+semana|ultima\s+semana|last\s+week|прошл\w*\s+недел|'
    r'минул\w*\s+тижд)',
  ).hasMatch(t)) {
    return make(
      from: startDaysAgo(7),
      to: today,
      daySpan: 7,
      labelKey: 'week',
    );
  }

  if (RegExp(
    r'(este\s+mes|this\s+month|этот\s+месяц|этом\s+месяц|цей\s+місяц|'
    r'último\s+mes|ultimo\s+mes|last\s+month|прошл\w*\s+месяц)',
  ).hasMatch(t)) {
    final monthStart = DateTime(today.year, today.month, 1);
    final span = today.difference(monthStart).inDays + 1;
    return make(
      from: monthStart,
      to: today,
      daySpan: span,
      labelKey: 'month',
    );
  }

  return make(
    from: startDaysAgo(14),
    to: today,
    daySpan: 14,
    labelKey: 'two_weeks',
    confident: false,
  );
}

/// Build [ExpensePeriodQuery] from a tiny AI JSON period resolution.
ExpensePeriodQuery? expensePeriodFromAiJson(
  Map<String, dynamic> m, {
  DateTime? now,
  PeriodListKind fallbackKind = PeriodListKind.expense,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);

  DateTime startDaysAgo(int daysInclusive) {
    final d = daysInclusive.clamp(1, 3660);
    return today.subtract(Duration(days: d - 1));
  }

  final typeRaw = (m['type'] ?? '').toString().toLowerCase();
  final kind = typeRaw.contains('income') ||
          typeRaw.contains('earning') ||
          typeRaw.contains('ganancia') ||
          typeRaw.contains('ingreso')
      ? PeriodListKind.income
      : (typeRaw.contains('expense') || typeRaw.contains('gasto')
          ? PeriodListKind.expense
          : fallbackKind);

  final kindKey =
      (m['kind'] ?? m['labelKey'] ?? '').toString().toLowerCase().trim();
  final weeksRaw = m['weeks'];
  final daysRaw = m['days'] ?? m['daySpan'];

  ExpensePeriodQuery make({
    required DateTime from,
    required DateTime to,
    required int daySpan,
    required String labelKey,
  }) {
    return ExpensePeriodQuery(
      from: from,
      to: to,
      daySpan: daySpan,
      labelKey: labelKey,
      kind: kind,
    );
  }

  if (kindKey == 'all' || kindKey == 'all_time') {
    return make(
      from: DateTime(2000, 1, 1),
      to: today,
      daySpan: 9999,
      labelKey: 'all',
    );
  }
  if (kindKey == 'month' || kindKey == 'this_month') {
    final monthStart = DateTime(today.year, today.month, 1);
    return make(
      from: monthStart,
      to: today,
      daySpan: today.difference(monthStart).inDays + 1,
      labelKey: 'month',
    );
  }

  int? weeks;
  if (weeksRaw is num) {
    weeks = weeksRaw.round();
  } else if (weeksRaw is String) {
    weeks = int.tryParse(weeksRaw);
  }
  if (weeks == null && kindKey.startsWith('week')) {
    weeks = kindKey.contains('two') || kindKey.contains('2') ? 2 : 1;
  }
  if (weeks != null && weeks >= 1 && weeks <= 52) {
    final d = weeks * 7;
    return make(
      from: startDaysAgo(d),
      to: today,
      daySpan: d,
      labelKey: weeks == 1
          ? 'week'
          : (weeks == 2 ? 'two_weeks' : 'weeks'),
    );
  }

  int? days;
  if (daysRaw is num) {
    days = daysRaw.round();
  } else if (daysRaw is String) {
    days = int.tryParse(daysRaw);
  }
  if (days != null && days >= 1 && days <= 3660) {
    return make(
      from: startDaysAgo(days),
      to: today,
      daySpan: days,
      labelKey: days % 7 == 0 && days >= 7
          ? (days == 7
              ? 'week'
              : (days == 14 ? 'two_weeks' : 'weeks'))
          : 'days',
    );
  }
  return null;
}

/// Local deterministic expense/income table for [query] (no Gemini).
({String reply, AiChatTable? table}) buildLocalExpensePeriodAnswer({
  required List<db.Transaction> allTransactions,
  required List<db.Category> categories,
  required ExpensePeriodQuery query,
  required Tr tr,
  required String baseCurrency,
  int? accountId,
  int maxRows = 120,
}) {
  final catById = {for (final c in categories) c.id: c};
  final from = query.from;
  final toEnd =
      DateTime(query.to.year, query.to.month, query.to.day, 23, 59, 59);
  final wantType = query.isIncome ? TxType.income : TxType.expense;

  final rowsTx = allTransactions.where((t) {
    if (TxType.values[t.type] != wantType) return false;
    if (accountId != null && t.accountId != accountId) return false;
    if (!query.isAllTime &&
        (t.date.isBefore(from) || t.date.isAfter(toEnd))) {
      return false;
    }
    if (query.isAllTime && t.date.isAfter(toEnd)) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final label = _periodLabel(tr, query);
  if (rowsTx.isEmpty) {
    return (
      reply: query.isIncome
          ? tr.aiIncomePeriodEmpty(label)
          : tr.aiExpensePeriodEmpty(label),
      table: null,
    );
  }

  final shown = rowsTx.take(maxRows).toList();
  final rows = <List<String>>[];
  for (final t in shown) {
    final cat = t.categoryId == null ? null : catById[t.categoryId];
    final catName = cat == null ? tr.other : tr.categoryName(cat.name);
    final date = formatExpenseTableDate(t.date);
    final currency = t.currency.isNotEmpty ? t.currency : baseCurrency;
    rows.add([catName, date, formatMoney(t.amount, currency)]);
  }

  final fullTotal = rowsTx.fold<double>(0, (s, t) => s + t.amount);
  final totalCurrency =
      shown.first.currency.isNotEmpty ? shown.first.currency : baseCurrency;

  final reply = rowsTx.length > shown.length
      ? (query.isIncome
          ? tr.aiIncomePeriodPartial(label, shown.length, rowsTx.length)
          : tr.aiExpensePeriodPartial(label, shown.length, rowsTx.length))
      : (query.isIncome
          ? tr.aiIncomePeriodIntro(label)
          : tr.aiExpensePeriodIntro(label));

  return (
    reply: reply,
    table: AiChatTable(
      headers: [tr.category, tr.date, tr.amount],
      rows: rows,
      total: formatMoney(fullTotal, totalCurrency),
    ),
  );
}

String buildLocalTransactionCountReply({
  required List<db.Transaction> allTransactions,
  required Tr tr,
}) {
  final n = allTransactions.length;
  return tr.aiTransactionCount(n);
}

/// Factual “can I afford X?” from balance — never records a transaction.
String? buildLocalAffordabilityReply({
  required String text,
  required double balance,
  required String currency,
  required Tr tr,
}) {
  final amount = _extractMoneyAmount(text);
  if (amount == null || amount <= 0) return null;
  final balLabel = formatMoney(balance, currency);
  final amtLabel = formatMoney(amount, currency);
  if (balance + 1e-9 >= amount) {
    return tr.aiAffordYes(amtLabel, balLabel);
  }
  return tr.aiAffordNo(amtLabel, balLabel);
}

double? _extractMoneyAmount(String text) {
  final m = RegExp(
    r'(\d+(?:[.,]\d{1,2})?)\s*(€|\$|£|uah|eur|usd|euro|euros)?',
    caseSensitive: false,
  ).firstMatch(text.replaceAll('\u00a0', ' '));
  if (m == null) return null;
  final raw = m.group(1)!.replaceAll(',', '.');
  return double.tryParse(raw);
}

String periodLabelFor(Tr tr, ExpensePeriodQuery query) => _periodLabel(tr, query);

String _periodLabel(Tr tr, ExpensePeriodQuery query) {
  switch (query.labelKey) {
    case 'week':
      return tr.aiPeriodLastWeek;
    case 'month':
      return tr.aiPeriodThisMonth;
    case 'days':
      return tr.aiPeriodLastDays(query.daySpan);
    case 'weeks':
      return tr.aiPeriodLastWeeks((query.daySpan / 7).round().clamp(1, 52));
    case 'all':
      return tr.aiPeriodAllTime;
    case 'two_weeks':
      return tr.aiPeriodLastTwoWeeks;
    default:
      return tr.aiPeriodLastTwoWeeks;
  }
}

const _numberWords = <String, int>{
  'una': 1,
  'one': 1,
  'одна': 1,
  'одну': 1,
  'один': 1,
  'dos': 2,
  'two': 2,
  'две': 2,
  'два': 2,
  'tres': 3,
  'three': 3,
  'три': 3,
  'cuatro': 4,
  'four': 4,
  'четыре': 4,
  'чотири': 4,
  'cinco': 5,
  'five': 5,
  'пять': 5,
  'пʼять': 5,
  'seis': 6,
  'six': 6,
  'шесть': 6,
  'шість': 6,
  'siete': 7,
  'seven': 7,
  'семь': 7,
  'сім': 7,
  'ocho': 8,
  'eight': 8,
  'восемь': 8,
  'вісім': 8,
  'nueve': 9,
  'nine': 9,
  'девять': 9,
  'девʼять': 9,
  'diez': 10,
  'ten': 10,
  'десять': 10,
};

/// "3 días" / "tres días" / "three days" → day count, or null.
int? _parseDayCount(String t) {
  final digit = RegExp(
    r'(últim|ultim|last|посл)\w*\s+(\d{1,3})\s*(d[ií]as?|days?|дн[яейів]*)',
  ).firstMatch(t);
  if (digit != null) {
    final n = int.tryParse(digit.group(2)!);
    if (n != null && n >= 1 && n <= 366) return n;
  }
  final digitLoose = RegExp(
    r'(\d{1,3})\s*(d[ií]as?|days?|дн[яейів]*)',
  ).firstMatch(t);
  if (digitLoose != null &&
      RegExp(r'(últim|ultim|last|посл|pasad|recent)').hasMatch(t)) {
    final n = int.tryParse(digitLoose.group(1)!);
    if (n != null && n >= 1 && n <= 366) return n;
  }

  for (final e in _numberWords.entries) {
    if (RegExp(
      '(últim|ultim|last|посл)\\w*\\s+${RegExp.escape(e.key)}\\s*'
      '(d[ií]as?|days?|дн[яейів]*)',
    ).hasMatch(t)) {
      return e.value;
    }
    if (RegExp(
          '${RegExp.escape(e.key)}\\s*(d[ií]as?|days?|дн[яейів]*)',
        ).hasMatch(t) &&
        RegExp(
          r'(últim|ultim|last|посл|pasad|recent|gananc|ingreso|gasto|'
          r'income|expense|доход|расход)',
        ).hasMatch(t)) {
      return e.value;
    }
  }
  return null;
}

/// "4 weeks" / "cuatro semanas" / "четыре недели" → week count, or null.
int? _parseWeekCount(String t) {
  final digit = RegExp(
    r'(\d{1,2})\s*(semanas?|weeks?|недел|тижн)',
  ).firstMatch(t);
  if (digit != null) {
    final n = int.tryParse(digit.group(1)!);
    if (n != null && n >= 1 && n <= 52) return n;
  }

  for (final e in _numberWords.entries) {
    if (RegExp(
      '${RegExp.escape(e.key)}\\s*(semanas?|weeks?|недел|тижн)',
    ).hasMatch(t)) {
      return e.value;
    }
  }
  return null;
}

/// Extra APP DATA block so Gemini can answer period questions without inventing.
String buildExpensePeriodContextBlock({
  required List<db.Transaction> allTransactions,
  required List<db.Category> categories,
  required ExpensePeriodQuery query,
  required String baseCurrency,
  int maxRows = 80,
}) {
  final catById = {for (final c in categories) c.id: c.name};
  final from = query.from;
  final toEnd =
      DateTime(query.to.year, query.to.month, query.to.day, 23, 59, 59);
  final wantType = query.isIncome ? TxType.income : TxType.expense;
  final rows = allTransactions.where((t) {
    if (TxType.values[t.type] != wantType) return false;
    if (!query.isAllTime &&
        (t.date.isBefore(from) || t.date.isAfter(toEnd))) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final label = query.isIncome ? 'INCOME' : 'EXPENSES';
  final buf = StringBuffer()
    ..writeln(
      '$label in requested period '
      '(${from.toIso8601String().substring(0, 10)} … '
      '${query.to.toIso8601String().substring(0, 10)}), '
      '${rows.length} rows — list EVERY row in the table; '
      'TOTAL must equal the sum of listed amounts; do not invent or drop days. '
      'Date cells: DD/MM if year=${DateTime.now().year}, else DD/MM/YY:',
    );
  if (rows.isEmpty) {
    buf.writeln('- (none)');
    return buf.toString();
  }
  for (final t in rows.take(maxRows)) {
    final cat = t.categoryId == null ? 'Other' : (catById[t.categoryId] ?? '?');
    final note = (t.note ?? '').trim();
    buf.writeln(
      '- ${t.date.toIso8601String().substring(0, 10)} | $cat | '
      '${t.amount.toStringAsFixed(2)} ${t.currency}'
      '${note.isEmpty ? '' : ' | $note'}',
    );
  }
  if (rows.length > maxRows) {
    buf.writeln('- … +${rows.length - maxRows} more');
  }
  final fullTotal = rows.fold<double>(0, (s, t) => s + t.amount);
  buf.writeln(
    'Period ${query.isIncome ? 'income' : 'expense'} TOTAL: '
    '${fullTotal.toStringAsFixed(2)} $baseCurrency',
  );
  return buf.toString();
}
