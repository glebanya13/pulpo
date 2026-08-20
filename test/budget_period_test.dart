import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/data/db/app_database.dart';
import 'package:pulpo/src/features/budgets/budget_period.dart';

void main() {
  test('monthly budget range respects start day', () {
    final budget = Budget(
      id: 1,
      name: 'Food',
      period: 1,
      amount: 500,
      currency: 'EUR',
      categoryIdsJson: '[]',
      rollover: false,
      startDate: DateTime(2026, 1, 15),
      color: 0,
    );
    final range = currentBudgetRange(budget, DateTime(2026, 8, 20));
    expect(range.start, DateTime(2026, 8, 15));
    expect(range.end, DateTime(2026, 9, 15));
  });

  test('rollover adds leftover to limit', () {
    expect(
      effectiveBudgetLimit(budget: _budget(rollover: true), previousSpent: 420),
      580,
    );
    expect(
      effectiveBudgetLimit(budget: _budget(rollover: false), previousSpent: 420),
      500,
    );
  });
}

Budget _budget({required bool rollover}) {
  return Budget(
    id: 1,
    name: 'Food',
    period: 1,
    amount: 500,
    currency: 'EUR',
    categoryIdsJson: '[]',
    rollover: rollover,
    startDate: DateTime(2026, 1, 1),
    color: 0,
  );
}
