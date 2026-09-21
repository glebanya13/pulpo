import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_errors.dart';
import 'package:pulpo/src/core/ai/ai_greeting.dart';
import 'package:pulpo/src/core/ai/ai_json.dart';
import 'package:pulpo/src/core/ai/ai_local_parse.dart';
import 'package:pulpo/src/core/ai/ai_models.dart';
import 'package:pulpo/src/core/ai/ai_record_hint.dart';
import 'package:pulpo/src/core/ai/assistant_energy.dart';
import 'package:pulpo/src/core/l10n/tr.dart';
import 'package:pulpo/src/features/assistant/assistant_chat_format.dart';

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
    expect(turn.table, isNull);
  });

  test('parses assistant turn question with structured table', () {
    final turn = parseAssistantTurnJson('''
{"intent":"question","reply":"En enero gastaste en Transporte:","transactions":[],
 "table":{"headers":["Categoría","Fecha","Gasto"],
  "rows":[["Transporte","04 de Enero","\$41,789"],["Transporte","09 de Enero","\$27,156"]],
  "total":"\$68,945"}}''');
    expect(turn.intent, 'question');
    expect(turn.table, isNotNull);
    expect(turn.table!.headers, ['Categoría', 'Fecha', 'Gasto']);
    expect(turn.table!.rows, hasLength(2));
    expect(turn.table!.total, r'$68,945');
    final body = composeReplyWithTable(turn.reply, turn.table);
    expect(body, contains('| Categoría | Fecha | Gasto |'));
    expect(body, contains('TOTAL'));
    expect(parseChatBody(body).whereType<ChatTableBlock>(), hasLength(1));
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
      tr.aiNetworkError,
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

  test('parses accountHint and transfer type', () {
    final batch = parseTransactionDraftBatchJson('''
{"transactions":[
  {"amount":500,"note":"Такси","accountHint":"Карта","type":"expense"},
  {"amount":1000,"fromAccount":"Карта","toAccount":"Наличные","type":"перевод"}
]}''');
    expect(batch.length, 2);
    expect(batch[0].accountHint, 'Карта');
    expect(batch[1].type, 'transfer');
    expect(batch[1].accountHint, 'Карта');
    expect(batch[1].toAccountHint, 'Наличные');
    expect(batch[1].isTransfer, isTrue);
  });

  test('local parse picks account from spoken name', () {
    final one = tryParseLocalTransactions(
      'кофе 60 с карты тинькофф',
      currencyHint: 'EUR',
      categoryNames: const ['Еда'],
      accountNames: const ['Наличные', 'Карта Тинькофф'],
    );
    expect(one, isNotNull);
    expect(one!.first.accountHint, 'Карта Тинькофф');
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
  });

  test('local parse handles multi-amount spoken list', () {
    final batch = tryParseLocalTransactions(
      'чай 20 евро ставки 10 евро',
      currencyHint: 'EUR',
    );
    expect(batch, isNotNull);
    expect(batch!, hasLength(2));
    expect(batch[0].amount, 20);
    expect(batch[1].amount, 10);
  });

  test('local parse handles long Spanish expense list offline', () {
    const text =
        'Gasté €20 en café 31 billete del autobús 40 en el taxi '
        'un euro para unos chuches y también compré leche por cinco euros '
        'unos sneakers por dos euros y unas patatas fritas por €20 '
        'un euro para comprar unas flores y también gané €50 en unas apuestas.';
    final batch = tryParseLocalTransactions(
      text,
      currencyHint: 'EUR',
      categoryNames: const ['Comida', 'Transporte'],
    );
    expect(batch, isNotNull);
    expect(batch!.length, greaterThanOrEqualTo(6));
    expect(batch.any((d) => d.amount == 20 && d.type == 'expense'), isTrue);
    expect(batch.any((d) => d.amount == 50 && d.type == 'income'), isTrue);
    expect(batch.any((d) => d.amount == 5), isTrue);
  });

  test('local parse strips greetings and record commands from note', () {
    final one = tryParseLocalTransactions(
      'привет запиши расходы хлеб 10 евро',
      currencyHint: 'EUR',
    );
    expect(one, isNotNull);
    expect(one!.first.amount, 10);
    expect(one.first.currency, 'EUR');
    final note = one.first.note!.toLowerCase();
    expect(note, contains('хлеб'));
    expect(note, isNot(contains('привет')));
    expect(note, isNot(contains('запиши')));
    expect(note, isNot(contains('расход')));
  });

  test('local parse shortens English record command to item', () {
    final one = tryParseLocalTransactions(
      'hello record expenses bread 10 euros',
      currencyHint: 'EUR',
    );
    expect(one, isNotNull);
    expect(one!.first.amount, 10);
    final note = one.first.note!.toLowerCase();
    expect(note, contains('bread'));
    expect(note, isNot(contains('hello')));
    expect(note, isNot(contains('record')));
  });

  test('chatty multi with greetings defers to Gemini (null local)', () {
    final batch = tryParseLocalTransactions(
      'привет запиши расходы хлеб 10 евро и такси 8 евро потому что ездил',
      currencyHint: 'EUR',
    );
    expect(batch, isNull);
  });

  test('sanitizeLedgerLabel strips commands from long AI notes', () {
    final cleaned = sanitizeLedgerLabel(
      'привет запиши расходы на хлеб пожалуйста',
    );
    expect(cleaned, isNotNull);
    expect(cleaned!.toLowerCase(), contains('хлеб'));
    expect(cleaned.toLowerCase(), isNot(contains('привет')));
  });

  test('salary is income locally and when Gemini mislabels expense', () {
    final one = tryParseLocalTransactions(
      'зарплата 2000 евро',
      currencyHint: 'EUR',
    );
    expect(one, isNotNull);
    expect(one!.first.type, 'income');
    expect(one.first.amount, 2000);

    final fixed = sanitizeTransactionDrafts([
      const TransactionDraftFromAi(
        amount: 2000,
        currency: 'EUR',
        note: 'зарплата',
        type: 'expense',
      ),
    ]);
    expect(fixed.first.type, 'income');
  });

  test('mixed spends then salary retyped from source when AI drops keyword', () {
    const source =
        'потратил 10 евро на это, 20 евро на это, 5 евро на другое. '
        'и также мне пришла зарплата в размере 3000 евро';
    final fixed = retypeDraftsFromSource(
      const [
        TransactionDraftFromAi(
          amount: 10,
          currency: 'EUR',
          note: 'это',
          type: 'expense',
        ),
        TransactionDraftFromAi(
          amount: 20,
          currency: 'EUR',
          note: 'это',
          type: 'expense',
        ),
        TransactionDraftFromAi(
          amount: 5,
          currency: 'EUR',
          note: 'другое',
          type: 'expense',
        ),
        TransactionDraftFromAi(
          amount: 3000,
          currency: 'EUR',
          note: 'также',
          type: 'expense',
        ),
      ],
      source,
    );
    expect(fixed.map((d) => d.type).toList(), [
      'expense',
      'expense',
      'expense',
      'income',
    ]);
  });

  test('parses receipt with line items', () {
    final r = parseReceiptJson('''
{"amount":57,"currency":"EUR","merchant":"Mercadona","type":"expense",
 "items":[
   {"amount":12.5,"note":"leche","categoryHint":"Comida"},
   {"amount":44.5,"note":"fruta","category":"Comida"}
 ]}''');
    expect(r.amount, 57);
    expect(r.hasLineItems, isTrue);
    expect(r.items, hasLength(2));
    expect(r.items.first.note, 'leche');
    expect(r.items.last.amount, closeTo(44.5, 0.001));
  });

  test('sums receipt amount from items when total missing', () {
    final r = parseReceiptJson('''
{"merchant":"Cafe","items":[
  {"amount":3,"note":"espresso"},
  {"amount":2.5,"note":"croissant"}
]}''');
    expect(r.amount, closeTo(5.5, 0.001));
    expect(r.hasLineItems, isTrue);
  });
}


