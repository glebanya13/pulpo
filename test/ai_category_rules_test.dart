import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_category_rules.dart';
import 'package:pulpo/src/core/ai/ai_few_shot.dart';
import 'package:pulpo/src/core/ai/ai_models.dart';
import 'package:pulpo/src/core/ai/pulpo_ai_service.dart';

void main() {
  test('applyAiCategoryRules overrides matching note/merchant', () {
    const rules = [
      AiCategoryRule(pattern: 'Uber', categoryName: 'Transport'),
      AiCategoryRule(pattern: 'Mercadona', categoryName: 'Comida'),
    ];
    final drafts = applyAiCategoryRules(
      const [
        TransactionDraftFromAi(
          amount: 12,
          note: 'uber downtown',
          categoryHint: 'Other',
        ),
        TransactionDraftFromAi(
          amount: 40,
          merchant: 'Mercadona Centro',
        ),
        TransactionDraftFromAi(
          amount: 5,
          note: 'coffee',
          categoryHint: 'Cafe',
        ),
      ],
      rules,
    );
    expect(drafts[0].categoryHint, 'Transport');
    expect(drafts[1].categoryHint, 'Comida');
    expect(drafts[2].categoryHint, 'Cafe');
  });

  test('upsertAiCategoryRule updates same pattern case-insensitively', () {
    var rules = const <AiCategoryRule>[];
    rules = upsertAiCategoryRule(
      rules,
      pattern: 'taxi',
      categoryName: 'Transport',
    );
    rules = upsertAiCategoryRule(
      rules,
      pattern: 'Taxi',
      categoryName: 'Viajes',
    );
    expect(rules, hasLength(1));
    expect(rules.first.pattern, 'Taxi');
    expect(rules.first.categoryName, 'Viajes');
  });

  test('patternForCategoryLearn keeps short token', () {
    expect(patternForCategoryLearn('Uber Eats lunch', null), 'Uber Eats lunch');
    expect(patternForCategoryLearn(null, 'Mercadona'), 'Mercadona');
    expect(patternForCategoryLearn('  ', null), isNull);
  });

  test('encode/decode category rules round-trip', () {
    const rules = [
      AiCategoryRule(pattern: 'uber', categoryName: 'Transport'),
    ];
    final raw = encodeAiCategoryRules(rules);
    final back = decodeAiCategoryRules(raw);
    expect(back, hasLength(1));
    expect(back.first.pattern, 'uber');
    expect(back.first.categoryName, 'Transport');
  });

  test('fewShotBlockForLocale returns locale-specific examples', () {
    expect(fewShotBlockForLocale('ru'), contains('зарплата'));
    expect(fewShotBlockForLocale('es'), contains('sueldo'));
    expect(fewShotBlockForLocale('en'), contains('salary'));
  });

  test('formatAccountsForAi includes currency and balance', () {
    final s = formatAccountsForAi(const [
      (name: 'Cash', currency: 'EUR', balance: 120.5),
      (name: 'Card', currency: 'USD', balance: -10),
    ]);
    expect(s, contains('Cash (EUR, bal 121)'));
    expect(s, contains('Card (USD, bal -10.00)'));
  });
}
