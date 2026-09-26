import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/features/assistant/expense_period_query.dart';

void main() {
  test('detects Spanish last two weeks expense ask', () {
    const q = 'Escríbeme los gastos de las últimas dos semanas';
    expect(looksLikeExpenseListQuestion(q), isTrue);
    final p = parseExpensePeriodQuery(q)!;
    expect(p.labelKey, 'two_weeks');
    expect(p.daySpan, 14);
    expect(p.to.difference(p.from).inDays, 13);
  });

  test('detects Russian two weeks data ask', () {
    const q = 'дай мне данные за последние две недели';
    expect(looksLikeExpenseListQuestion(q), isTrue);
    expect(parseExpensePeriodQuery(q)!.labelKey, 'two_weeks');
  });

  test('detects all transactions ask', () {
    const q = 'покажи таблицу со всеми транзакциями';
    expect(looksLikeExpenseListQuestion(q), isTrue);
    expect(parseExpensePeriodQuery(q)!.labelKey, 'all');
  });

  test('detects transaction count ask', () {
    expect(
      looksLikeTransactionCountQuestion(
        'сколько за все использование я сделал транзакций?',
      ),
      isTrue,
    );
  });

  test('formatExpenseTableDate adds year when not current', () {
    final now = DateTime(2026, 9, 26);
    expect(formatExpenseTableDate(DateTime(2026, 9, 24), now: now), '24/09');
    expect(formatExpenseTableDate(DateTime(2025, 9, 24), now: now), '24/09/25');
  });

  test('does not treat recording spend as expense list', () {
    expect(looksLikeExpenseListQuestion('gasté 15€ en comida'), isFalse);
    expect(parseExpensePeriodQuery('gasté 15€ en comida'), isNull);
  });

  test('detects this month', () {
    final p = parseExpensePeriodQuery('muéstrame los gastos de este mes')!;
    expect(p.labelKey, 'month');
    expect(p.from.day, 1);
  });
}
