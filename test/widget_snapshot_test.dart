import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/widget_snapshot.dart';
import 'package:pulpo/src/data/db/app_database.dart';
import 'package:pulpo/src/data/db/enums.dart';

void main() {
  test('widget snapshot computes budget left', () {
    final now = DateTime(2026, 8, 15);
    final txs = [
      Transaction(
        id: 1,
        accountId: 1,
        categoryId: 1,
        amount: 200,
        currency: 'EUR',
        type: TxType.expense.index,
        date: now,
        status: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final budgets = [
      Budget(
        id: 1,
        name: 'Food',
        period: 1,
        amount: 500,
        currency: 'EUR',
        categoryIdsJson: '[]',
        rollover: false,
        startDate: DateTime(2026, 8, 1),
        color: 0,
      ),
    ];
    final snap = buildWidgetSnapshot(
      totalBalance: 1000,
      formattedBalance: '€1,000',
      formattedSpent: '€200',
      currency: 'EUR',
      txs: txs,
      budgets: budgets,
      formatMoney: (v, c) => '€${v.toStringAsFixed(0)}',
      categoryLabel: (_) => 'Food',
    );
    expect(snap.budgetPercent, greaterThan(0));
    expect(snap.dailyBars, isNotEmpty);
  });
}
