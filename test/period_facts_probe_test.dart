import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_record_hint.dart';
import 'package:pulpo/src/core/l10n/tr.dart';
import 'package:pulpo/src/data/db/app_database.dart';
import 'package:pulpo/src/data/db/enums.dart';
import 'package:pulpo/src/features/assistant/expense_period_query.dart';

Transaction _tx({
  required int id,
  required double amount,
  required TxType type,
  required DateTime date,
  int? categoryId,
}) {
  return Transaction(
    id: id,
    accountId: 1,
    categoryId: categoryId,
    amount: amount,
    currency: 'EUR',
    type: type.index,
    date: date,
    status: 0,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  final tr = Tr.fromLang('es');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  group('period parse (bug regressions)', () {
    test('income tres días → income + 3 days (not two weeks)', () {
      for (final q in [
        'Quiero ver las ganancias de los últimos tres días',
        'ganancias de los últimos tres días',
        'dame las ganancias de los últimos tres días',
        'ingresos de los últimos 3 días',
      ]) {
        expect(looksLikeExpenseListQuestion(q), isTrue, reason: q);
        final p = parseExpensePeriodQuery(q)!;
        expect(p.kind, PeriodListKind.income, reason: q);
        expect(p.labelKey, 'days', reason: q);
        expect(p.daySpan, 3, reason: q);
        expect(p.confident, isTrue, reason: q);
        expect(looksLikeTransactionRecord(q), isFalse, reason: q);
      }
    });

    test('expense dos semanas stays expense + 14', () {
      const q = 'Escríbeme los gastos de las últimas dos semanas';
      final p = parseExpensePeriodQuery(q)!;
      expect(p.kind, PeriodListKind.expense);
      expect(p.daySpan, 14);
      expect(p.labelKey, 'two_weeks');
    });

    test('affordability never hijacks period or record', () {
      for (final q in [
        '¿Puedo permitirme comprar neumáticos por 500€?',
        'Puedo permitirme 500€ de neumáticos',
        'puedo permitirme 500 euros en ruedas',
      ]) {
        expect(looksLikeExpenseListQuestion(q), isFalse, reason: q);
        expect(parseExpensePeriodQuery(q), isNull, reason: q);
        expect(looksLikeAffordabilityQuestion(q), isTrue, reason: q);
        expect(looksLikeTransactionRecord(q), isFalse, reason: q);
      }
    });
  });

  group('local period table facts', () {
    late List<Transaction> txs;
    late List<Category> cats;

    setUp(() {
      cats = [
        Category(
          id: 1,
          name: 'food',
          icon: 'food',
          color: 0,
          type: TxType.expense.index,
          isHidden: false,
          sortOrder: 0,
        ),
        Category(
          id: 2,
          name: 'salary',
          icon: 'salary',
          color: 0,
          type: TxType.income.index,
          isHidden: false,
          sortOrder: 0,
        ),
      ];
      txs = [
        _tx(
          id: 1,
          amount: 100,
          type: TxType.expense,
          date: today.subtract(const Duration(days: 1)),
          categoryId: 1,
        ),
        _tx(
          id: 2,
          amount: 50,
          type: TxType.expense,
          date: today.subtract(const Duration(days: 10)),
          categoryId: 1,
        ),
        _tx(
          id: 3,
          amount: 2000,
          type: TxType.income,
          date: today.subtract(const Duration(days: 1)),
          categoryId: 2,
        ),
        _tx(
          id: 4,
          amount: 500,
          type: TxType.income,
          date: today.subtract(const Duration(days: 20)),
          categoryId: 2,
        ),
      ];
    });

    test('3-day income lists only recent income, correct total', () {
      final q = parseExpensePeriodQuery(
        'ganancias de los últimos tres días',
      )!;
      final built = buildLocalExpensePeriodAnswer(
        allTransactions: txs,
        categories: cats,
        query: q,
        tr: tr,
        baseCurrency: 'EUR',
      );
      expect(built.table, isNotNull);
      expect(built.table!.rows, hasLength(1));
      expect(built.table!.total, contains('2'));
      // Local intro is template — chat screen replaces via narrate when table≠null.
      expect(built.reply, tr.aiIncomePeriodIntro(periodLabelFor(tr, q)));
    });

    test('3-day income ignores older income and all expenses', () {
      final q = parseExpensePeriodQuery(
        'ingresos de los últimos 3 días',
      )!;
      final built = buildLocalExpensePeriodAnswer(
        allTransactions: txs,
        categories: cats,
        query: q,
        tr: tr,
        baseCurrency: 'EUR',
      );
      expect(built.table!.rows.length, 1);
      // Only id=3 (2000). id=4 is 20 days ago.
      expect(built.table!.total!.contains('2.000') ||
          built.table!.total!.contains('2,000') ||
          built.table!.total!.contains('2000'), isTrue);
    });

    test('two-week expenses exclude income and older spend', () {
      final q = parseExpensePeriodQuery(
        'gastos de las últimas dos semanas',
      )!;
      final built = buildLocalExpensePeriodAnswer(
        allTransactions: txs,
        categories: cats,
        query: q,
        tr: tr,
        baseCurrency: 'EUR',
      );
      expect(built.table!.rows, hasLength(2)); // both expenses within 14d
      expect(built.reply, tr.aiExpensePeriodIntro(periodLabelFor(tr, q)));
    });

    test('empty income period uses empty template (no fake rows)', () {
      final q = parseExpensePeriodQuery(
        'ganancias de los últimos tres días',
      )!;
      final built = buildLocalExpensePeriodAnswer(
        allTransactions: [
          _tx(
            id: 9,
            amount: 10,
            type: TxType.expense,
            date: today,
            categoryId: 1,
          ),
        ],
        categories: cats,
        query: q,
        tr: tr,
        baseCurrency: 'EUR',
      );
      expect(built.table, isNull);
      expect(built.reply, tr.aiIncomePeriodEmpty(periodLabelFor(tr, q)));
    });
  });
}
