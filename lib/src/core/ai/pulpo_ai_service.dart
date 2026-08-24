import 'dart:async';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/error_log_repository.dart';
import 'ai_errors.dart';
import 'ai_greeting.dart';
import 'ai_json.dart';
import 'ai_models.dart';

export 'ai_errors.dart' show PulpoAiException, AiErrorCode;

typedef AiErrorLogger = Future<void> Function(
  String source,
  Object error,
  StackTrace? stackTrace,
);

class PulpoAiService {
  PulpoAiService({
    FirebaseAuth? auth,
    AiErrorLogger? onError,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _onError = onError;

  final FirebaseAuth _auth;
  final AiErrorLogger? _onError;

  FirebaseAI get _firebaseAi => FirebaseAI.googleAI(
        auth: _auth,
        appCheck: FirebaseAppCheck.instance,
      );

  static const _primaryModel = 'gemini-2.5-flash';
  static const _fallbackModel = 'gemini-2.0-flash';

  Future<void> _logError(
    String source,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    final logger = _onError;
    if (logger == null) return;
    try {
      await logger(source, error, stackTrace);
    } catch (_) {}
  }

  GenerativeModel _model({
    required String name,
    required bool json,
  }) {
    return _firebaseAi.generativeModel(
      model: name,
      generationConfig: GenerationConfig(
        temperature: json ? 0.2 : 0.35,
        responseMimeType: json ? 'application/json' : null,
      ),
    );
  }

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw const PulpoAiException(AiErrorCode.signInRequired);
    }
  }

  Future<String> _generate(
    List<Content> contents, {
    required String label,
    bool json = true,
  }) async {
    _requireSignedIn();
    await _auth.currentUser?.getIdToken(true);

    final attempts = <({String model, bool json})>[
      (model: _primaryModel, json: json),
      if (json) (model: _primaryModel, json: false),
      (model: _fallbackModel, json: json),
      if (json) (model: _fallbackModel, json: false),
    ];

    PulpoAiException? lastError;
    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      try {
        if (i > 0) {
          try {
            await FirebaseAppCheck.instance.getToken(true);
          } catch (e) {
            debugPrint('MonederoAI[$label] App Check refresh: $e');
          }
        }
        final response = await _model(
          name: attempt.model,
          json: attempt.json,
        ).generateContent(contents);
        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          throw const PulpoAiException(AiErrorCode.emptyResponse);
        }
        if (i > 0) {
          debugPrint(
            'MonederoAI[$label] ok via ${attempt.model} json=${attempt.json}',
          );
        }
        return text;
      } on PulpoAiException catch (e) {
        lastError = e;
        debugPrint(
          'MonederoAI[$label] ${attempt.model} json=${attempt.json}: $e',
        );
        if (e.isRetryable && i < attempts.length - 1) continue;
        await _logError(
          'ai.$label',
          e,
          null,
        );
        rethrow;
      } catch (e, st) {
        debugPrint(
          'MonederoAI[$label] ${attempt.model} json=${attempt.json}: $e',
        );
        debugPrint('$st');
        final mapped = PulpoAiException(
          classifyAiRawError(e.toString()),
          e.toString(),
        );
        lastError = mapped;
        if (mapped.isRetryable && i < attempts.length - 1) continue;
        if (json &&
            attempt.json &&
            i < attempts.length - 1 &&
            mapped.code == AiErrorCode.requestFailed) {
          continue;
        }
        await _logError('ai.$label', mapped, st);
        throw mapped;
      }
    }
    final failed = lastError ??
        const PulpoAiException(AiErrorCode.requestFailed, 'no attempts');
    await _logError('ai.$label', failed, null);
    throw failed;
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
    final err = PulpoAiException(AiErrorCode.invalidJson, '$lastError');
    await _logError('ai.parse', err, null);
    throw err;
  }

  String _langName(String locale) {
    switch (locale) {
      case 'uk':
        return 'Ukrainian';
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
      throw const PulpoAiException(AiErrorCode.emptyInput);
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
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      throw const PulpoAiException(AiErrorCode.emptyInput);
    }

    if (isCasualGreeting(trimmed)) {
      return AssistantTurnResult(
        intent: 'question',
        reply: greetingReplyForLocale(locale),
      );
    }

    try {
      return await _withRetryParse(() async {
        final cats = categoryNames.take(40).join(', ');
        final lang = _langName(locale);
        final hist = history
            .take(12)
            .map((h) =>
                '${h.role == 'user' ? 'User' : 'Assistant'}: ${h.text}')
            .join('\n');
        final prompt = '''
You are Monedero AI Assistant in a personal finance app. Reply in $lang with JSON only.

Two intents:
1) "record" — user wants to ADD expense(s) and/or income(s). Extract every transaction.
   Fields per item: amount (>0), currency (ISO, default $currencyHint), date (ISO or null=today), note, merchant, categoryHint (from: [$cats]), type ("expense"|"income").
   Include a short friendly "reply" confirming what will be recorded.
2) "question" — user asks about data already in the app (balances, spending, budgets, goals) OR greets / chats casually.
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
    } on PulpoAiException catch (e) {
      if (!e.allowsChatFallback) rethrow;
      debugPrint('MonederoAI assistant_turn fallback to chat: $e');
      final reply = await chatAboutApp(
        userMessage: trimmed,
        appContext: appContext,
        locale: locale,
        history: history,
      );
      return AssistantTurnResult(intent: 'question', reply: reply);
    }
  }

  /// Answers questions using only the provided app snapshot. No financial advice.
  Future<String> chatAboutApp({
    required String userMessage,
    required String appContext,
    required String locale,
    required List<({String role, String text})> history,
  }) async {
    final trimmed = userMessage.trim();
    if (isCasualGreeting(trimmed)) {
      return greetingReplyForLocale(locale);
    }

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
    // Prefer a single text prompt — more reliable than system+history roles
    // across Firebase AI Logic endpoints.
    final hist = history
        .take(12)
        .map((h) => '${h.role == 'user' ? 'User' : 'Assistant'}: ${h.text}')
        .join('\n');
    final prompt = '''
$system

Recent chat:
$hist

User message: """$trimmed"""
''';
    return _generate([Content.text(prompt)], label: 'chat', json: false);
  }
}

final pulpoAiServiceProvider = Provider<PulpoAiService>((ref) {
  final logs = ref.watch(errorLogRepositoryProvider);
  return PulpoAiService(
    onError: (source, error, stackTrace) {
      return logs.record(
        source: source,
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
});
