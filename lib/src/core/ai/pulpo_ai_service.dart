import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_json.dart';
import 'ai_models.dart';

class PulpoAiException implements Exception {
  const PulpoAiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PulpoAiService {
  PulpoAiService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  GenerativeModel? _model;
  GenerativeModel? _chatModel;

  FirebaseAI get _firebaseAi => FirebaseAI.googleAI(
        auth: _auth,
        appCheck: FirebaseAppCheck.instance,
      );

  static const _modelName = 'gemini-2.5-flash';

  GenerativeModel get _jsonModel {
    return _model ??= _firebaseAi.generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
      ),
    );
  }

  GenerativeModel get _textModel {
    return _chatModel ??= _firebaseAi.generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(temperature: 0.35),
    );
  }

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw const PulpoAiException('sign_in_required');
    }
  }

  Future<String> _generate(
    List<Content> contents, {
    required String label,
    bool json = true,
  }) async {
    _requireSignedIn();
    try {
      // Fresh Auth ID token for Firebase AI.
      await _auth.currentUser?.getIdToken(true);
      // Do NOT call App Check getToken() here: the SDK attaches one token per
      // request. A preflight getToken() can burn/reuse tokens when App Check
      // (or replay protection) is enforced and cause permission_denied.
      final model = json ? _jsonModel : _textModel;
      final response = await model.generateContent(contents);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const PulpoAiException('empty_response');
      }
      return text;
    } on PulpoAiException {
      rethrow;
    } catch (e, st) {
      debugPrint('MonederoAI[$label]: $e');
      debugPrint('$st');
      final msg = e.toString();
      if (msg.contains('API key') || msg.contains('InvalidApiKey')) {
        throw const PulpoAiException('api_key');
      }
      if (msg.contains('not enabled') || msg.contains('ServiceApiNotEnabled')) {
        throw const PulpoAiException('api_not_enabled');
      }
      if (msg.contains('PERMISSION') ||
          msg.contains('permission') ||
          msg.contains('App Check') ||
          msg.contains('app-check') ||
          msg.contains('FirebaseAppCheck') ||
          msg.contains('403') ||
          msg.contains('UNAUTHENTICATED') ||
          msg.contains('unauthenticated') ||
          msg.contains('appCheck')) {
        throw const PulpoAiException('permission_denied');
      }
      if (msg.contains('Quota') || msg.contains('RESOURCE_EXHAUSTED')) {
        throw const PulpoAiException('quota');
      }
      throw PulpoAiException('request_failed: $e');
    }
  }

  Future<T> _withRetryParse<T>(
    Future<String> Function() call,
    T Function(String) parse,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final text = await call();
        return parse(text);
      } on FormatException catch (e) {
        lastError = e;
        debugPrint('MonederoAI parse retry: $e');
      }
    }
    throw PulpoAiException('invalid_json: $lastError');
  }

  String _langName(String locale) {
    switch (locale) {
      case 'ru':
        return 'Russian';
      case 'en':
        return 'English';
      default:
        return 'Spanish';
    }
  }

  Future<ReceiptParseResult> analyzeReceipt(
    File image, {
    required String locale,
    required List<String> categoryNames,
    String? currencyHint,
  }) {
    return _withRetryParse(() async {
      final bytes = await image.readAsBytes();
      final mime = image.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final cats = categoryNames.take(40).join(', ');
      final prompt = '''
You are a receipt parser for a personal finance app.
Reply with JSON only. Language for merchant/note/categoryHint: ${_langName(locale)}.
Extract: amount (number), currency (ISO 4217 if clear${currencyHint != null ? ', prefer $currencyHint' : ''}), date (ISO-8601 if found), merchant, note (short), categoryHint (best match from: [$cats] or null), type ("expense" or "income").
If unsure about a field, use null.
''';
      return _generate(
        [
          Content.multi([
            TextPart(prompt),
            InlineDataPart(mime, bytes),
          ]),
        ],
        label: 'receipt',
      );
    }, parseReceiptJson);
  }

  Future<TransactionDraftFromAi> parseNaturalLanguage(
    String text, {
    required String locale,
    required List<String> categoryNames,
    String? currencyHint,
  }) async {
    final batch = await parseNaturalLanguageBatch(
      text,
      locale: locale,
      categoryNames: categoryNames,
      currencyHint: currencyHint,
    );
    return batch.first;
  }

  /// Parse one spoken/typed message into one or more transaction drafts.
  Future<List<TransactionDraftFromAi>> parseNaturalLanguageBatch(
    String text, {
    required String locale,
    required List<String> categoryNames,
    String? currencyHint,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const PulpoAiException('empty_input');
    }
    return _withRetryParse(() async {
      final cats = categoryNames.take(40).join(', ');
      final prompt = '''
Parse this user message into one or more personal finance transactions.
The user may mention several expenses/incomes in one sentence.
Reply with JSON only: {"transactions":[{...}, ...]}
Each item fields: amount (number > 0), currency (ISO if mentioned${currencyHint != null ? ', else prefer $currencyHint' : ''}), date (ISO-8601 or null for today), note (short), merchant, categoryHint (best match from: [$cats] or null), type ("expense" or "income").
Language for note/categoryHint: ${_langName(locale)}.
User message: """$trimmed"""
''';
      return _generate([Content.text(prompt)], label: 'nl_batch');
    }, parseTransactionDraftBatchJson);
  }

  Future<CategorySuggestion?> suggestCategory({
    required String noteOrMerchant,
    required List<String> categoryNames,
    required String locale,
  }) async {
    final text = noteOrMerchant.trim();
    if (text.isEmpty || categoryNames.isEmpty) return null;
    try {
      return await _withRetryParse(() async {
        final cats = categoryNames.take(40).join(', ');
        final prompt = '''
Pick the best matching category name from the list for this note/merchant.
Reply JSON: {"categoryName":"<exact name from list>","confidence":0.0-1.0}
List: [$cats]
Locale hint: ${_langName(locale)}
Text: """$text"""
''';
        return _generate([Content.text(prompt)], label: 'category');
      }, parseCategorySuggestionJson);
    } catch (_) {
      return null;
    }
  }

  Future<PeriodInsight> generatePeriodInsight(
    PeriodInsightInput input, {
    required String locale,
  }) {
    return _withRetryParse(() async {
      final tops = input.topCategories
          .take(8)
          .map((e) => '${e.name}: ${e.amount.toStringAsFixed(2)}')
          .join('; ');
      final prompt = '''
Write a short personal finance insight (2-3 sentences) from this aggregate summary only.
Do not invent specific merchants or transactions.
Reply JSON: {"insight":"..."} in ${_langName(locale)}.
Period: ${input.periodLabel}
Currency: ${input.currency}
Total expense: ${input.totalExpense.toStringAsFixed(2)}
Total income: ${input.totalIncome.toStringAsFixed(2)}
Top categories: $tops
''';
      return _generate([Content.text(prompt)], label: 'insight');
    }, parsePeriodInsightJson);
  }

  /// Record transactions or answer from app data — one assistant turn.
  Future<AssistantTurnResult> assistantTurn({
    required String userMessage,
    required String appContext,
    required String locale,
    required List<String> categoryNames,
    required String currencyHint,
    required List<({String role, String text})> history,
  }) {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      throw const PulpoAiException('empty_input');
    }
    return _withRetryParse(() async {
      final cats = categoryNames.take(40).join(', ');
      final lang = _langName(locale);
      final hist = history
          .take(12)
          .map((h) => '${h.role == 'user' ? 'User' : 'Assistant'}: ${h.text}')
          .join('\n');
      final prompt = '''
You are Monedero AI Assistant in a personal finance app. Reply in $lang with JSON only.

Two intents:
1) "record" — user wants to ADD expense(s) and/or income(s). Extract every transaction.
   Fields per item: amount (>0), currency (ISO, default $currencyHint), date (ISO or null=today), note, merchant, categoryHint (from: [$cats]), type ("expense"|"income").
   Include a short friendly "reply" confirming what will be recorded.
2) "question" — user asks about data already in the app (balances, spending, budgets, goals). Use ONLY APP DATA. No financial/investment/tax advice.
   Include "reply" with the answer. "transactions" must be [].

If unsure, prefer "question" and ask to clarify in "reply".

Recent chat:
$hist

APP DATA:
$appContext

User message: """$trimmed"""

Reply JSON: {"intent":"record"|"question","reply":"...","transactions":[...]}
''';
      return _generate([Content.text(prompt)], label: 'assistant_turn');
    }, parseAssistantTurnJson);
  }

  /// Answers questions using only the provided app snapshot. No financial advice.
  Future<String> chatAboutApp({
    required String userMessage,
    required String appContext,
    required String locale,
    required List<({String role, String text})> history,
  }) async {
    final system = '''
You are Monedero Assistant inside a personal budget app.
Reply in ${_langName(locale)}. Be concise and clear.

Hard rules:
- Use ONLY facts from APP DATA below. Do not invent numbers, accounts, or transactions.
- Do NOT give financial, investment, tax, credit, or budgeting advice. Do not recommend what to buy, cut, save, invest, or borrow.
- You may restate, filter, compare, and explain what is already in APP DATA (balances, recent txs, budgets, goals, debts).
- If the user asks for advice or anything outside APP DATA, politely refuse and say you can only talk about data already in the app.
- If APP DATA does not contain the answer, say you don't have that information in the app.

APP DATA:
$appContext
''';
    final contents = <Content>[
      Content.system(system),
    ];
    for (final turn in history.take(16)) {
      contents.add(
        Content(turn.role == 'user' ? 'user' : 'model', [TextPart(turn.text)]),
      );
    }
    contents.add(Content.text(userMessage));
    return _generate(contents, label: 'chat', json: false);
  }
}

final pulpoAiServiceProvider = Provider<PulpoAiService>((ref) {
  return PulpoAiService();
});
