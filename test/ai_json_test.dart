import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_errors.dart';
import 'package:pulpo/src/core/ai/ai_greeting.dart';
import 'package:pulpo/src/core/ai/ai_json.dart';
import 'package:pulpo/src/core/ai/ai_local_parse.dart';
import 'package:pulpo/src/core/ai/ai_record_hint.dart';
import 'package:pulpo/src/core/ai/assistant_energy.dart';
import 'package:pulpo/src/core/l10n/tr.dart';

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

  test('parses assistant turn record with Ukrainian income type', () {
    final turn = parseAssistantTurnJson('''
{"intent":"record","reply":"Записав каву","transactions":[
  {"amount":60,"note":"Кава","categoryHint":"Їжа","type":"дохід"}
]}''');
    expect(turn.intent, 'record');
    expect(turn.reply, contains('каву'));
    expect(turn.transactions, hasLength(1));
    expect(turn.transactions.first.type, 'income');
    expect(turn.isRecord, isTrue);
  });

  test('parses assistant turn question without transactions', () {
    final turn = parseAssistantTurnJson(
      '{"intent":"question","reply":"На рахунку 100 EUR","transactions":[]}',
    );
    expect(turn.intent, 'question');
    expect(turn.isRecord, isFalse);
    expect(turn.transactions, isEmpty);
    expect(turn.reply, contains('100'));
  });

  test('energy units map full quota to 100', () {
    expect(
      AssistantEnergy.unitsFromMs(AssistantEnergy.freeQuota.inMilliseconds),
      100,
    );
    expect(AssistantEnergy.unitsFromMs(0), 0);
    expect(
      AssistantEnergy.unitsFromMs(
        AssistantEnergy.freeQuota.inMilliseconds ~/ 2,
      ),
      inInclusiveRange(50, 51),
    );
  });

  test('classifyAiRawError maps known Firebase failures', () {
    expect(
      classifyAiRawError('PERMISSION_DENIED: App Check token'),
      AiErrorCode.permissionDenied,
    );
    expect(
      classifyAiRawError('RESOURCE_EXHAUSTED Quota exceeded'),
      AiErrorCode.quota,
    );
    expect(
      classifyAiRawError(
        'Your prepayment credits are depleted. Please go to AI Studio',
      ),
      AiErrorCode.quota,
    );
    expect(
      classifyAiRawError('FinishReason.safety blocked'),
      AiErrorCode.blocked,
    );
    expect(
      classifyAiRawError('NOT_FOUND model not found'),
      AiErrorCode.missingModel,
    );
    expect(
      classifyAiRawError('Server Error [500]: boom'),
      AiErrorCode.network,
    );
    expect(
      classifyAiRawError('weird upstream glitch'),
      AiErrorCode.requestFailed,
    );
  });

  test('describeAiError maps typed codes', () {
    final tr = Tr.fromLang('ru');
    expect(
      describeAiError(
        tr,
        const PulpoAiException(AiErrorCode.permissionDenied),
      ),
      tr.aiPermissionDenied,
    );
    expect(
      describeAiError(
        tr,
        const PulpoAiException(AiErrorCode.signInRequired),
      ),
      tr.proSignInRequired,
    );
    expect(
      describeAiError(tr, const PulpoAiException(AiErrorCode.blocked)),
      tr.aiBlocked,
    );
    expect(
      describeAiError(
        tr,
        const PulpoAiException(
          AiErrorCode.quota,
          'Your prepayment credits are depleted',
        ),
      ),
      tr.aiBillingDepleted,
    );
    expect(
      describeAiError(
        tr,
        const PulpoAiException(
          AiErrorCode.network,
          'Server Error [500]: boom',
        ),
      ),
      contains('boom'),
    );
    expect(
      const PulpoAiException(AiErrorCode.invalidJson).allowsChatFallback,
      isTrue,
    );
    expect(
      const PulpoAiException(AiErrorCode.quota).allowsChatFallback,
      isFalse,
    );
    expect(
      const PulpoAiException(AiErrorCode.permissionDenied).isRetryable,
      isTrue,
    );
    expect(
      const PulpoAiException(AiErrorCode.quota).isRetryable,
      isFalse,
    );
  });

  test('isCasualGreeting catches hellos but not expenses', () {
    expect(isCasualGreeting('привет'), isTrue);
    expect(isCasualGreeting('Привет!'), isTrue);
    expect(isCasualGreeting('hola'), isTrue);
    expect(isCasualGreeting('hi there'), isTrue);
    expect(isCasualGreeting('привіт'), isTrue);
    expect(isCasualGreeting('кофе 60'), isFalse);
    expect(isCasualGreeting('hi coffee 60'), isFalse);
    expect(isCasualGreeting('сколько я потратил'), isFalse);
    expect(greetingReplyForLocale('ru'), contains('Привет'));
    expect(greetingReplyForLocale('uk'), contains('Привіт'));
  });

  test('looksLikeTransactionRecord and balance hints', () {
    expect(looksLikeTransactionRecord('кофе 60 евро'), isTrue);
    expect(looksLikeTransactionRecord('потратил 20 на еду'), isTrue);
    expect(looksLikeTransactionRecord('сколько я потратил?'), isFalse);
    expect(looksLikeBalanceQuestion('какой у меня баланс?'), isTrue);
    expect(looksLikeBalanceQuestion('кофе 60'), isFalse);
  });

  test('local parse handles simple single amount', () {
    final one = tryParseLocalTransactions(
      'кофе 60€',
      currencyHint: 'EUR',
      categoryNames: const ['Еда', 'Транспорт'],
    );
    expect(one, isNotNull);
    expect(one!, hasLength(1));
    expect(one.first.amount, 60);
    expect(one.first.currency, 'EUR');
    expect(one.first.note?.toLowerCase(), contains('кофе'));

    expect(
      tryParseLocalTransactions(
        'чай 20 евро ставки 10 евро',
        currencyHint: 'EUR',
      ),
      isNull,
    );
  });
}
