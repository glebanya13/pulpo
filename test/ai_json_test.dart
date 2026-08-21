import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_json.dart';

void main() {
  test('parses receipt JSON with fence and commas', () {
    const raw = '''```json
{"amount":"12,50","currency":"EUR","date":"2026-08-18","merchant":"Cafe","categoryHint":"Comida","type":"expense"}
```''';
    final r = parseReceiptJson(raw);
    expect(r.amount, closeTo(12.5, 0.001));
    expect(r.currency, 'EUR');
    expect(r.merchant, 'Cafe');
    expect(r.categoryHint, 'Comida');
    expect(r.type, 'expense');
    expect(r.date?.day, 18);
  });

  test('parses NL draft and category suggestion', () {
    final draft = parseTransactionDraftJson(
      '{"amount":40,"note":"Taxi","category":"Transport","type":"income"}',
    );
    expect(draft.amount, 40);
    expect(draft.categoryHint, 'Transport');
    expect(draft.type, 'income');

    final cat = parseCategorySuggestionJson(
      '{"categoryName":"Еда","confidence":0.9}',
    );
    expect(cat.categoryName, 'Еда');
    expect(cat.confidence, closeTo(0.9, 0.001));
  });

  test('parses period insight', () {
    final insight = parsePeriodInsightJson(
      '{"insight":"You spent more on food this month."}',
    );
    expect(insight.text, contains('food'));
  });

  test('parses batch voice drafts', () {
    final batch = parseTransactionDraftBatchJson('''
{"transactions":[
  {"amount":10,"note":"Taxi","categoryHint":"Transport","type":"expense"},
  {"amount":20,"note":"Food","category":"Comida","type":"expense"},
  {"amount":15,"note":"Loan","type":"income"}
]}''');
    expect(batch.length, 3);
    expect(batch[0].amount, 10);
    expect(batch[1].categoryHint, 'Comida');
    expect(batch[2].type, 'income');
  });
}
