import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/pro/pro_limits.dart';
import 'package:pulpo/src/data/db/enums.dart';
import 'package:pulpo/src/features/import/csv_import.dart';

void main() {
  test('free limits match the Pro spec', () {
    expect(ProLimits.accounts, 3);
    expect(ProLimits.goals, 2);
    expect(ProLimits.budgets, 3);
    expect(ProLimits.debts, 2);
    expect(ProLimits.subscriptions, 3);
    expect(ProLimits.recurring, 3);
    expect(ProLimits.freeLimit(ProGate.accounts), 3);
    expect(ProLimits.freeLimit(ProGate.excel), isNull);
  });

  test('active helpers skip completed, paid and paused items', () {
    expect(isActiveGoal(isCompleted: false), isTrue);
    expect(isActiveGoal(isCompleted: true), isFalse);
    expect(
      isActiveBudget(endDate: null, now: DateTime(2026, 8, 18)),
      isTrue,
    );
    expect(
      isActiveBudget(
        endDate: DateTime(2026, 8, 1),
        now: DateTime(2026, 8, 18),
      ),
      isFalse,
    );
    expect(
      isActiveDebt(status: 0, amount: 100, paidAmount: 20),
      isTrue,
    );
    expect(
      isActiveDebt(status: 0, amount: 100, paidAmount: 100),
      isFalse,
    );
    expect(isActiveSubscription(isPaused: true), isFalse);
    expect(isActiveRecurring(isPaused: false), isTrue);
  });

  test('parses Pulpo CSV export', () {
    const csv = 'date,type,amount,currency,note\n'
        '2026-08-01T12:00:00.000,expense,12.5,EUR,"Cafe"\n'
        '2026-08-02,income,100,USD,Salary\n';
    final result = parseTransactionCsv(csv, fallbackCurrency: 'EUR');
    expect(result.skipped, 0);
    expect(result.rows.length, 2);
    expect(result.rows.first.type, TxType.expense);
    expect(result.rows.first.amount, 12.5);
    expect(result.rows.first.note, 'Cafe');
    expect(result.rows[1].type, TxType.income);
    expect(result.rows[1].currency, 'USD');
  });

  test('parses bank-style semicolon CSV with comma decimals', () {
    const csv = 'Fecha;Importe;Concepto\n'
        '18/08/2026;-12,40;Mercadona\n'
        '17/08/2026;1.200,00;Nómina\n';
    final result = parseTransactionCsv(csv, fallbackCurrency: 'EUR');
    expect(result.rows.length, 2);
    expect(result.rows.first.type, TxType.expense);
    expect(result.rows.first.amount, closeTo(12.40, 0.001));
    expect(result.rows[1].type, TxType.income);
    expect(result.rows[1].amount, closeTo(1200, 0.001));
  });

  test('parses Russian CSV headers', () {
    const csv = 'дата,тип,сумма,валюта,заметка\n'
        '2026-08-01,expense,50,RUB,Кофе\n';
    final result = parseTransactionCsv(csv, fallbackCurrency: 'RUB');
    expect(result.rows.length, 1);
    expect(result.rows.first.amount, 50);
    expect(result.rows.first.note, 'Кофе');
  });
}
