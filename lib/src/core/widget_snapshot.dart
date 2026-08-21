import 'dart:convert';
import 'dart:math' as math;

import '../data/db/app_database.dart' as db;
import '../data/db/enums.dart';
import '../features/budgets/budget_period.dart';

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.balance,
    required this.spent,
    required this.budgetLeft,
    required this.budgetTotal,
    required this.budgetPercent,
    required this.monthLabel,
    required this.dailyBars,
    required this.categoryShortcuts,
  });

  final String balance;
  final String spent;
  final String budgetLeft;
  final double budgetTotal;
  final int budgetPercent;
  final String monthLabel;
  final List<int> dailyBars;
  final List<({String label, String amount})> categoryShortcuts;
}

WidgetSnapshot buildWidgetSnapshot({
  required double totalBalance,
  required String formattedBalance,
  required String formattedSpent,
  required String currency,
  required List<db.Transaction> txs,
  required List<db.Budget> budgets,
  required String Function(double, String) formatMoney,
  required String Function(int? categoryId) categoryLabel,
}) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 1);
  final monthLabel =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  var totalBudget = 0.0;
  var totalSpent = 0.0;
  for (final b in budgets) {
    if (b.endDate != null && b.endDate!.isBefore(now)) continue;
    final range = currentBudgetRange(b, now);
    final catIds = (jsonDecode(b.categoryIdsJson) as List).cast<int>();
    final prev = previousBudgetRange(b, now);
    final prevSpent =
        budgetSpentInRange(txs, prev, categoryIds: catIds);
    final limit =
        effectiveBudgetLimit(budget: b, previousSpent: prevSpent);
    totalBudget += limit;
    totalSpent += budgetSpentInRange(txs, range, categoryIds: catIds);
  }
  if (totalBudget <= 0) {
    for (final t in txs) {
      if (t.date.isBefore(monthStart) || !t.date.isBefore(monthEnd)) continue;
      if (TxType.values[t.type] == TxType.expense) totalSpent += t.amount;
    }
    totalBudget = math.max(totalSpent, 1);
  }

  final left = (totalBudget - totalSpent).clamp(0, double.infinity);
  final pct = totalBudget > 0 ? ((left / totalBudget) * 100).round() : 0;

  final dayCount = now.day;
  final daily = List<double>.filled(dayCount, 0);
  for (final t in txs) {
    if (t.date.isBefore(monthStart) || !t.date.isBefore(monthEnd)) continue;
    if (TxType.values[t.type] != TxType.expense) continue;
    final idx = t.date.day - 1;
    if (idx >= 0 && idx < dayCount) daily[idx] += t.amount;
  }
  final maxDaily = daily.isEmpty ? 1.0 : daily.reduce(math.max);
  final safeMax = (maxDaily.isFinite && maxDaily > 0) ? maxDaily : 1.0;
  final bars = [
    for (final v in daily)
      (((v.isFinite ? v : 0) / safeMax) * 100).round().clamp(0, 100),
  ];
  final last7 = bars.length <= 7 ? bars : bars.sublist(bars.length - 7);

  final byCat = <int, double>{};
  for (final t in txs) {
    if (t.date.isBefore(monthStart) || !t.date.isBefore(monthEnd)) continue;
    if (TxType.values[t.type] != TxType.expense) continue;
    byCat.update(t.categoryId ?? -1, (v) => v + t.amount, ifAbsent: () => t.amount);
  }
  final sorted = byCat.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final shortcuts = <({String label, String amount})>[];
  for (final e in sorted.take(6)) {
    shortcuts.add((
      label: categoryLabel(e.key == -1 ? null : e.key),
      amount: formatMoney(e.value, currency),
    ));
  }

  return WidgetSnapshot(
    balance: formattedBalance,
    spent: formattedSpent,
    budgetLeft: formatMoney(left.toDouble(), currency),
    budgetTotal: totalBudget,
    budgetPercent: pct,
    monthLabel: monthLabel,
    dailyBars: last7,
    categoryShortcuts: shortcuts,
  );
}

String encodeCategoryShortcuts(List<({String label, String amount})> items) {
  return jsonEncode([
    for (final i in items) {'l': i.label, 'a': i.amount},
  ]);
}

List<({String label, String amount})> decodeCategoryShortcuts(String raw) {
  try {
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        if (item is Map)
          (
            label: '${item['l'] ?? ''}',
            amount: '${item['a'] ?? ''}',
          ),
    ];
  } catch (_) {
    return const [];
  }
}
