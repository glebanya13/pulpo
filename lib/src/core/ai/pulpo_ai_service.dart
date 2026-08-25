import 'dart:async';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
// ThinkingConfig is not re-exported in firebase_ai 2.3.x.
// ignore: implementation_imports
import 'package:firebase_ai/src/api.dart' show ThinkingConfig;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/error_log_repository.dart';
import 'ai_errors.dart';
import 'ai_greeting.dart';
import 'ai_json.dart';
import 'ai_local_parse.dart';
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

  /// Primary: Flash-Lite (minimal thinking by default). One fast fallback.
  static const _primaryModel = 'gemini-3.5-flash-lite';
  static const _fallbackModels = <String>[
    'gemini-2.5-flash-lite',
  ];

  static const _attemptTimeout = Duration(seconds: 12);

  FirebaseAI? _firebaseAi;
  final _modelCache = <String, GenerativeModel>{};
  DateTime? _lastTokenWarm;

  FirebaseAI get _ai {
    return _firebaseAi ??= FirebaseAI.googleAI(
      auth: _auth,
      appCheck: FirebaseAppCheck.instance,
    );
  }

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

  /// Warm auth + App Check when the assistant screen opens.
  Future<void> prefetch() async {
    try {
      await _auth.currentUser?.getIdToken();
      _lastTokenWarm = DateTime.now();
    } catch (_) {}
    try {
      await FirebaseAppCheck.instance.getToken();
    } catch (_) {}
    // Touch primary model so the first user message is warmer.
    _model(name: _primaryModel, json: true);
  }

  GenerativeModel _model({
    required String name,
    required bool json,
  }) {
    final key = '$name|json=$json';
    final cached = _modelCache[key];
    if (cached != null) return cached;

    // Gemini 2.5 Flash*: thinkingBudget 0 disables thinking.
    // Gemini 3.5 Flash-Lite already defaults to minimal thinking.
    final disableThinking = name.contains('2.5-flash');
    final created = _ai.generativeModel(
      model: name,
      generationConfig: GenerationConfig(
        temperature: json ? 0.1 : 0.3,
        responseMimeType: json ? 'application/json' : null,
        maxOutputTokens: json ? 1536 : 768,
        thinkingConfig:
            disableThinking ? ThinkingConfig(thinkingBudget: 0) : null,
      ),
    );
    _modelCache[key] = created;
    return created;
  }

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw const PulpoAiException(AiErrorCode.signInRequired);
    }
  }

  Future<void> _ensureAuthWarm() async {
    final last = _lastTokenWarm;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 45)) {
      return;
    }
    await _auth.currentUser?.getIdToken();
    _lastTokenWarm = DateTime.now();
  }

  Future<String> _generate(
    List<Content> contents, {
    required String label,
    bool json = true,
  }) async {
    _requireSignedIn();
    await _ensureAuthWarm();

    // Primary → one fallback. Retry without JSON mime only after those fail.
    final attempts = <({String model, bool json})>[
      (model: _primaryModel, json: json),
      for (final m in _fallbackModels) (model: m, json: json),
      if (json) ...[
        (model: _primaryModel, json: false),
        for (final m in _fallbackModels) (model: m, json: false),
      ],
    ];

    PulpoAiException? lastError;
    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      try {
        if (i > 0) {
          try {
            await FirebaseAppCheck.instance.getToken();
          } catch (e) {
            debugPrint('MonederoAI[$label] App Check refresh: $e');
          }
        }
        final response = await _model(
          name: attempt.model,
          json: attempt.json,
        ).generateContent(contents).timeout(_attemptTimeout);
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
      } on TimeoutException {
        debugPrint(
          'MonederoAI[$label] ${attempt.model} json=${attempt.json}: timeout',
        );
        lastError = const PulpoAiException(AiErrorCode.requestFailed, 'timeout');
        if (i < attempts.length - 1) continue;
        await _logError('ai.$label', lastError, null);
        throw lastError;
      } on PulpoAiException catch (e) {
        lastError = e;
        debugPrint(
          'MonederoAI[$label] ${attempt.model} json=${attempt.json}: $e',
        );
        if (e.isRetryable && i < attempts.length - 1) continue;
        await _logError('ai.$label', e, null);
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

  String _catsForPrompt(List<String> categoryNames, {int limit = 12}) {
    return categoryNames.take(limit).join(', ');
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
      final cats = _catsForPrompt(categoryNames, limit: 20);
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
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const PulpoAiException(AiErrorCode.emptyInput);
    }

    final local = tryParseLocalTransactions(
      trimmed,
      currencyHint: currencyHint,
      categoryNames: categoryNames,
    );
    if (local != null && local.isNotEmpty) {
      debugPrint('MonederoAI[nl_batch] local parse (${local.length})');
      return local;
    }

    return _withRetryParse(() async {
      final cats = _catsForPrompt(categoryNames);
      final prompt = '''
Parse into finance transactions. JSON only: {"transactions":[{amount,currency,date,note,merchant,categoryHint,type}]}
amount>0; currency ISO${currencyHint != null ? ' (prefer $currencyHint)' : ''}; date ISO or null; type expense|income; categoryHint from [$cats] or null.
Lang: ${_langName(locale)}.
"""$trimmed"""
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
        final cats = _catsForPrompt(categoryNames, limit: 20);
        final prompt = '''
Pick best category from list. JSON: {"categoryName":"<exact>","confidence":0-1}
List: [$cats]
Locale: ${_langName(locale)}
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
        final cats = _catsForPrompt(categoryNames);
        final lang = _langName(locale);
        final hist = history
            .take(4)
            .map((h) =>
                '${h.role == 'user' ? 'User' : 'Assistant'}: ${h.text}')
            .join('\n');
        final prompt = '''
Monedero AI. Reply in $lang, JSON only.
intent "record": extract txs {amount,currency,date,note,merchant,categoryHint from [$cats],type}; short reply.
intent "question": answer from APP DATA only; transactions=[].
Prefer "question" if unsure.

Chat:
$hist

APP DATA:
$appContext

User: """$trimmed"""

{"intent":"record"|"question","reply":"...","transactions":[...]}
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
    final hist = history
        .take(4)
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
