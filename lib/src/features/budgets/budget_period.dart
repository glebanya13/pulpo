import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';

class BudgetPeriodRange {
  const BudgetPeriodRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

BudgetPeriodRange currentBudgetRange(db.Budget budget, DateTime now) {
  final today = _day(now);
  final anchor = _day(budget.startDate);

  switch (budget.period) {
    case 0:
      final days = today.difference(anchor).inDays;
      final offset = days >= 0 ? days ~/ 7 : (days - 6) ~/ 7;
      final start = anchor.add(Duration(days: offset * 7));
      return BudgetPeriodRange(
        start: start,
        end: start.add(const Duration(days: 7)),
      );
    case 3:
      var year = today.year;
      var month = budget.startDate.month;
      var day = budget.startDate.day;
      var start = _safeDate(year, month, day);
      if (start.isAfter(today)) {
        start = _safeDate(year - 1, month, day);
      }
      final endYear = start.month == 12 ? start.year + 1 : start.year;
      final endMonth = start.month == 12 ? 1 : start.month + 12;
      return BudgetPeriodRange(
        start: start,
        end: _safeDate(endYear, endMonth, day),
      );
    case 1:
    default:
      var year = today.year;
      var month = today.month;
      var start = _safeDate(year, month, budget.startDate.day);
      if (start.isAfter(today)) {
        final prev = DateTime(year, month - 1, 1);
        start = _safeDate(prev.year, prev.month, budget.startDate.day);
      }
      final next = DateTime(start.year, start.month + 1, 1);
      return BudgetPeriodRange(
        start: start,
        end: _safeDate(next.year, next.month, budget.startDate.day),
      );
  }
}

BudgetPeriodRange previousBudgetRange(db.Budget budget, DateTime now) {
  final current = currentBudgetRange(budget, now);
  final len = current.end.difference(current.start);
  return BudgetPeriodRange(
    start: current.start.subtract(len),
    end: current.start,
  );
}

DateTime _safeDate(int year, int month, int day) {
  while (month < 1) {
    month += 12;
    year--;
  }
  while (month > 12) {
    month -= 12;
    year++;
  }
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > last ? last : day);
}

double budgetSpentInRange(
  List<dynamic> txs,
  BudgetPeriodRange range, {
  required List<int> categoryIds,
}) {
  var spent = 0.0;
  for (final t in txs) {
    if (TxType.values[t.type] != TxType.expense) continue;
    if (t.date.isBefore(range.start) || !t.date.isBefore(range.end)) continue;
    if (categoryIds.isNotEmpty && !categoryIds.contains(t.categoryId)) continue;
    spent += t.amount;
  }
  return spent;
}

double effectiveBudgetLimit({
  required db.Budget budget,
  required double previousSpent,
}) {
  if (!budget.rollover) return budget.amount;
  final leftover = (budget.amount - previousSpent).clamp(0, double.infinity);
  return budget.amount + leftover;
}
