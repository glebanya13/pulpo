import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_record_hint.dart';
import 'package:pulpo/src/features/assistant/expense_period_query.dart';

void main() {
  test('detects Spanish last two weeks expense ask', () {
    const q = 'Escríbeme los gastos de las últimas dos semanas';
    expect(looksLikeExpenseListQuestion(q), isTrue);
    final p = parseExpensePeriodQuery(q)!;
    expect(p.labelKey, 'two_weeks');
    expect(p.daySpan, 14);
    expect(p.kind, PeriodListKind.expense);
    expect(p.to.difference(p.from).inDays, 13);
  });

  test('income last three days (word) is income + 3 days', () {
    const q = 'Quiero ver las ganancias de los últimos tres días';
    expect(looksLikeExpenseListQuestion(q), isTrue);
    final p = parseExpensePeriodQuery(q)!;
    expect(p.kind, PeriodListKind.income);
    expect(p.labelKey, 'days');
    expect(p.daySpan, 3);
    expect(p.confident, isTrue);
  });

  test('income last 3 days with digit', () {
    final p = parseExpensePeriodQuery('ingresos de los últimos 3 días')!;
    expect(p.kind, PeriodListKind.income);
    expect(p.daySpan, 3);
  });

  test('bare period without type is not a list question', () {
    expect(
      looksLikeExpenseListQuestion('últimos tres días'),
      isFalse,
    );
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

  test('affordability is not a transaction record', () {
    expect(
      looksLikeAffordabilityQuestion(
        'Puedo permitirme 500€ de neumáticos',
      ),
      isTrue,
    );
    expect(
      looksLikeTransactionRecord('Puedo permitirme 500€ de neumáticos'),
      isFalse,
    );
    expect(
      looksLikeTransactionRecord(
        'Quiero comprar unos neumáticos valorados en €500 puedo permitírmelo',
      ),
      isFalse,
    );
  });

  test('detects four weeks in Russian', () {
    const q = 'Отправь мне данные за последние четыре недели';
    expect(looksLikeExpenseListQuestion(q), isTrue);
    final p = parseExpensePeriodQuery(q)!;
    expect(p.labelKey, 'weeks');
    expect(p.daySpan, 28);
  });

  test('detects 3 semanas in Spanish', () {
    final p = parseExpensePeriodQuery('gastos de las últimas 3 semanas')!;
    expect(p.daySpan, 21);
    expect(p.labelKey, 'weeks');
  });

  test('expensePeriodFromAiJson maps weeks and income type', () {
    final now = DateTime(2026, 9, 27);
    final p = expensePeriodFromAiJson(
      {'weeks': 4, 'type': 'income'},
      now: now,
    )!;
    expect(p.daySpan, 28);
    expect(p.labelKey, 'weeks');
    expect(p.kind, PeriodListKind.income);
    expect(p.confident, isTrue);
  });

  test('default recent expenses is not confident', () {
    final p = parseExpensePeriodQuery('muéstrame mis gastos')!;
    expect(p.confident, isFalse);
    expect(p.daySpan, 14);
  });
}
