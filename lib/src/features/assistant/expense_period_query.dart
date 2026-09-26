import '../../core/ai/ai_models.dart';
import '../../core/ai/ai_record_hint.dart';
import '../../core/l10n/tr.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';

/// Parsed “show my expenses for …” request.
class ExpensePeriodQuery {
  const ExpensePeriodQuery({
    required this.from,
    required this.to,
    required this.daySpan,
    required this.labelKey,
  });

  /// Inclusive calendar-day start (local).
  final DateTime from;

  /// Inclusive calendar-day end (local).
  final DateTime to;

  /// Approximate day count for labels (7, 14, …).
  final int daySpan;

  /// Stable key: `two_weeks` | `week` | `month` | `days` | `all`.
  final String labelKey;

  bool get isAllTime => labelKey == 'all';
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

/// True when the user asks to list / show expenses or all transactions.
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

  final mentionsExpenses = RegExp(
    r'(gastos?|expenses?|расход|трат|витрат|потрат|'
    r'movimientos?|операц|транзакц|transactions?)',
  ).hasMatch(t);

  final asksList = RegExp(
    r'(dame|escr[ií]b|mu[eé]stra|lista|list|show|write|d[aá]j|дай|'
    r'покаж|напиш|какие|що\s+я|что\s+я|cu[aá]les|tabla|таблиц|'
    r'todas?|all|все|усі|'
    r'últim|ultim|last|посл|recient|recent|'
    r'dos\s+semanas|two\s+weeks|две\s+недел|'
    r'esta\s+semana|this\s+week|эту\s+недел|цей\s+тижд|'
    r'este\s+mes|this\s+month|этот\s+месяц|цей\s+місяц)',
  ).hasMatch(t);

  if (mentionsExpenses && asksList) return true;

  return RegExp(
    r'(últim|ultim|last|посл).{0,20}(semanas?|weeks?|недел|тижн|d[ií]as|days)',
  ).hasMatch(t);
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

/// Parse a relative expense period from natural language.
ExpensePeriodQuery? parseExpensePeriodQuery(String text) {
  if (!looksLikeExpenseListQuestion(text)) return null;

  final t = text.trim().toLowerCase();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime startDaysAgo(int daysInclusive) {
    final n = daysInclusive.clamp(1, 3660);
    return today.subtract(Duration(days: n - 1));
  }

  // All transactions / complete history.
  if (RegExp(
    r'(todas?\s+(las\s+)?(transacciones|operaciones|gastos)|'
    r'all\s+(my\s+)?(transactions|expenses)|'
    r'(все|всем[а-яёії]*)\s+(мои\s+)?(транзакц|операц|расход)|'
    r'усі\s+(мої\s+)?(транзакц|операц|витрат)|'
    r'sin\s+l[ií]mite|за\s+вс[её]\s+время|за\s+весь\s+период)',
  ).hasMatch(t)) {
    // Far past → today; builder treats labelKey all specially.
    return ExpensePeriodQuery(
      from: DateTime(2000, 1, 1),
      to: today,
      daySpan: 9999,
      labelKey: 'all',
    );
  }

  if (RegExp(
    r'(dos\s+semanas|2\s+semanas|two\s+weeks|2\s+weeks|'
    r'две\s+недел|2\s+недел|два\s+тижн)',
  ).hasMatch(t)) {
    return ExpensePeriodQuery(
      from: startDaysAgo(14),
      to: today,
      daySpan: 14,
      labelKey: 'two_weeks',
    );
  }

  if (RegExp(
    r'(esta\s+semana|this\s+week|эту\s+недел|этой\s+недел|цей\s+тижд|'
    r'última\s+semana|ultima\s+semana|last\s+week|прошл\w*\s+недел|'
    r'минул\w*\s+тижд)',
  ).hasMatch(t)) {
    return ExpensePeriodQuery(
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
    return ExpensePeriodQuery(
      from: monthStart,
      to: today,
      daySpan: span,
      labelKey: 'month',
    );
  }

  final daysMatch = RegExp(
    r'(últim|ultim|last|посл)\w*\s+(\d{1,3})\s*(d[ií]as?|days?|дн)',
  ).firstMatch(t);
  if (daysMatch != null) {
    final n = int.tryParse(daysMatch.group(2)!) ?? 14;
    return ExpensePeriodQuery(
      from: startDaysAgo(n),
      to: today,
      daySpan: n.clamp(1, 366),
      labelKey: 'days',
    );
  }

  // Generic “mis gastos / recent expenses” → last 14 days.
  return ExpensePeriodQuery(
    from: startDaysAgo(14),
    to: today,
    daySpan: 14,
    labelKey: 'two_weeks',
  );
}

/// Local deterministic expense table for [query] (no Gemini).
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

  final expenses = allTransactions.where((t) {
    if (TxType.values[t.type] != TxType.expense) return false;
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
  if (expenses.isEmpty) {
    return (
      reply: tr.aiExpensePeriodEmpty(label),
      table: null,
    );
  }

  final shown = expenses.take(maxRows).toList();
  final rows = <List<String>>[];
  for (final t in shown) {
    final cat = t.categoryId == null ? null : catById[t.categoryId];
    final catName = cat == null ? tr.other : tr.categoryName(cat.name);
    final date = formatExpenseTableDate(t.date);
    final currency = t.currency.isNotEmpty ? t.currency : baseCurrency;
    rows.add([catName, date, formatMoney(t.amount, currency)]);
  }

  final fullTotal = expenses.fold<double>(0, (s, t) => s + t.amount);
  final totalCurrency =
      shown.first.currency.isNotEmpty ? shown.first.currency : baseCurrency;

  final reply = expenses.length > shown.length
      ? tr.aiExpensePeriodPartial(label, shown.length, expenses.length)
      : tr.aiExpensePeriodIntro(label);

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

String _periodLabel(Tr tr, ExpensePeriodQuery query) {
  switch (query.labelKey) {
    case 'week':
      return tr.aiPeriodLastWeek;
    case 'month':
      return tr.aiPeriodThisMonth;
    case 'days':
      return tr.aiPeriodLastDays(query.daySpan);
    case 'all':
      return tr.aiPeriodAllTime;
    case 'two_weeks':
    default:
      return tr.aiPeriodLastTwoWeeks;
  }
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
  final expenses = allTransactions.where((t) {
    if (TxType.values[t.type] != TxType.expense) return false;
    if (!query.isAllTime &&
        (t.date.isBefore(from) || t.date.isAfter(toEnd))) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final buf = StringBuffer()
    ..writeln(
      'EXPENSES in requested period '
      '(${from.toIso8601String().substring(0, 10)} … '
      '${query.to.toIso8601String().substring(0, 10)}), '
      '${expenses.length} rows — list EVERY row in the table; '
      'TOTAL must equal the sum of listed amounts; do not invent or drop days. '
      'Date cells: DD/MM if year=${DateTime.now().year}, else DD/MM/YY:',
    );
  if (expenses.isEmpty) {
    buf.writeln('- (none)');
    return buf.toString();
  }
  for (final t in expenses.take(maxRows)) {
    final cat = t.categoryId == null ? 'Other' : (catById[t.categoryId] ?? '?');
    final note = (t.note ?? '').trim();
    buf.writeln(
      '- ${t.date.toIso8601String().substring(0, 10)} | $cat | '
      '${t.amount.toStringAsFixed(2)} ${t.currency}'
      '${note.isEmpty ? '' : ' | $note'}',
    );
  }
  if (expenses.length > maxRows) {
    buf.writeln('- … +${expenses.length - maxRows} more');
  }
  final fullTotal = expenses.fold<double>(0, (s, t) => s + t.amount);
  buf.writeln(
    'Period expense TOTAL: ${fullTotal.toStringAsFixed(2)} $baseCurrency',
  );
  return buf.toString();
}
