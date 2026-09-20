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
import 'ai_category_rules.dart';
import 'ai_errors.dart';
import 'ai_few_shot.dart';
import 'ai_greeting.dart';
import 'ai_json.dart';
import 'ai_local_parse.dart';
import 'ai_models.dart';
import 'ai_record_hint.dart';

export 'ai_errors.dart' show PulpoAiException, AiErrorCode;

typedef AiErrorLogger = Future<void> Function(
  String source,
  Object error,
  StackTrace? stackTrace,
);

typedef AiPartialCallback = void Function(String partialText);

/// Compact account lines for NL prompts: name + currency + balance.
String formatAccountsForAi(
  List<({String name, String currency, double balance})> accounts, {
  int limit = 24,
}) {
  if (accounts.isEmpty) return '';
  return accounts.take(limit).map((a) {
    final bal = a.balance.toStringAsFixed(
      a.balance.abs() >= 100 ? 0 : 2,
    );
    return '${a.name} (${a.currency}, bal $bal)';
  }).join(', ');
}

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
    'gemini-2.5-flash',
  ];

  static const _attemptTimeout = Duration(seconds: 12);
  static const _strongAttemptTimeout = Duration(seconds: 22);

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
        maxOutputTokens: json ? 2048 : 768,
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
    bool preferStrong = false,
    AiPartialCallback? onPartial,
  }) async {
    _requireSignedIn();
    await _ensureAuthWarm();

    final orderedModels = preferStrong
        ? <String>[..._fallbackModels, _primaryModel]
        : <String>[_primaryModel, ..._fallbackModels];
    final timeout =
        preferStrong ? _strongAttemptTimeout : _attemptTimeout;

    // Primary (or strong) → fallback. Retry without JSON mime only after those fail.
    final attempts = <({String model, bool json})>[
      for (final m in orderedModels) (model: m, json: json),
      if (json)
        for (final m in orderedModels) (model: m, json: false),
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
        final model = _model(
          name: attempt.model,
          json: attempt.json,
        );
        final text = onPartial != null
            ? await _streamText(
                model,
                contents,
                timeout: timeout,
                onPartial: onPartial,
              )
            : await model
                .generateContent(contents)
                .timeout(timeout)
                .then((r) => r.text);
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

  Future<String> _streamText(
    GenerativeModel model,
    List<Content> contents, {
    required Duration timeout,
    required AiPartialCallback onPartial,
  }) async {
    final buf = StringBuffer();
    await Future(() async {
      await for (final chunk in model.generateContentStream(contents)) {
        final piece = chunk.text;
        if (piece == null || piece.isEmpty) continue;
        buf.write(piece);
        final preview = _previewForUi(buf.toString());
        if (preview.isNotEmpty) onPartial(preview);
      }
    }).timeout(timeout);
    return buf.toString();
  }

  /// Soft preview for the busy bubble (strip JSON noise when present).
  static String _previewForUi(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    // Prefer streaming "reply" field from assistant JSON.
    final replyMatch = RegExp(
      r'"reply"\s*:\s*"((?:\\.|[^"\\])*)',
      dotAll: true,
    ).firstMatch(trimmed);
    if (replyMatch != null) {
      final reply = replyMatch
          .group(1)!
          .replaceAll(r'\"', '"')
          .replaceAll(r'\n', '\n');
      if (reply.trim().isNotEmpty) return reply.trim();
    }
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      // Don't flash raw JSON braces at the user.
      return '';
    }
    if (trimmed.length <= 280) return trimmed;
    return trimmed.substring(trimmed.length - 280);
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

  String _catsForPrompt(List<String> categoryNames, {int limit = 40}) {
    return categoryNames.take(limit).join(', ');
  }

  Future<ReceiptParseResult> analyzeReceipt(
    File image, {
    required String locale,
    required List<String> categoryNames,
    String? currencyHint,
    List<AiCategoryRule> categoryRules = const [],
  }) {
    return _withRetryParse(() async {
      final bytes = await image.readAsBytes();
      final mime = image.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final cats = _catsForPrompt(categoryNames, limit: 20);
      final rules = categoryRulesPromptBlock(categoryRules, limit: 20);
      final prompt = '''
You are a receipt parser for a personal finance app.
Reply with JSON only. Language for merchant/note/categoryHint: ${_langName(locale)}.
Extract: amount (number = TOTAL if present), currency (ISO 4217 if clear${currencyHint != null ? ', prefer $currencyHint' : ''}), date (ISO-8601 if found), merchant, note (short), categoryHint (best match from: [$cats] or null), type ("expense" or "income").
When the receipt lists multiple product lines with prices, also fill:
  items: [{amount, note (1–3 words product name), categoryHint from list or null}, ...]
If only a total is clear and line items are unreadable, use items: [].
Do not invent line items. Prefer splitting when ≥2 priced lines are readable.
$rules
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
        preferStrong: true,
      );
    }, parseReceiptJson);
  }

  Future<TransactionDraftFromAi> parseNaturalLanguage(
    String text, {
    required String locale,
    required List<String> categoryNames,
    List<String> accountNames = const [],
    String? accountContext,
    String? currencyHint,
    bool fromSpeech = false,
    List<AiCategoryRule> categoryRules = const [],
  }) async {
    final batch = await parseNaturalLanguageBatch(
      text,
      locale: locale,
      categoryNames: categoryNames,
      accountNames: accountNames,
      accountContext: accountContext,
      currencyHint: currencyHint,
      fromSpeech: fromSpeech,
      categoryRules: categoryRules,
    );
    return batch.first;
  }

  /// Parse one spoken/typed message into one or more transaction drafts.
  /// Always uses Gemini (no on-device local parse) — natural speech like Budget IA.
  Future<List<TransactionDraftFromAi>> parseNaturalLanguageBatch(
    String text, {
    required String locale,
    required List<String> categoryNames,
    List<String> accountNames = const [],
    String? accountContext,
    String? currencyHint,
    bool fromSpeech = false,
    List<AiCategoryRule> categoryRules = const [],
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const PulpoAiException(AiErrorCode.emptyInput);
    }

    final parsed = await _withRetryParse(() async {
      final cats = _catsForPrompt(categoryNames);
      final accountsBlob = (accountContext != null && accountContext.isNotEmpty)
          ? accountContext
          : _catsForPrompt(accountNames, limit: 24);
      final hasAccounts = accountsBlob.isNotEmpty;
      final accountRule = !hasAccounts
          ? 'accountHint/toAccountHint null.'
          : 'Accounts (name, currency, balance): [$accountsBlob]. '
              'accountHint = debit/from account exact name when user names it, else null. '
              'For transfers type=transfer and toAccountHint from the same list.';
      final rules = categoryRulesPromptBlock(categoryRules);
      final fewShot = fewShotBlockForLocale(locale);
      final prompt = '''
You are a personal finance parser (like Budget AI). User speaks or types naturally — extract ALL transactions.
JSON only: {"transactions":[{amount,currency,date,note,merchant,categoryHint,accountHint,toAccountHint,type}]}

Rules:
- amount>0; currency ISO${currencyHint != null ? ' (prefer $currencyHint)' : ''}; date ISO or null
- type expense|income|transfer; categoryHint MUST be from [$cats] or null
- $accountRule
$rules
$fewShot
- Natural speech is OK. Split multiple amounts into separate txs.
- note/merchant: 1–3 words (item or merchant), NEVER the full utterance or greetings/commands
- Salary/wage/cashback/refund → ALWAYS income (зарплата, salary, sueldo, nómina, аванс, paycheck, кешбек, возврат, ingreso de sueldo)
- Keep spoken order. Do not invent amounts. Prefer categoryHint from the list when clear.

Lang: ${_langName(locale)}.
"""$trimmed"""
''';
      return _generate(
        [Content.text(prompt)],
        label: 'nl_batch',
        preferStrong: fromSpeech || needsStrongAiModel(trimmed),
      );
    }, parseTransactionDraftBatchJson);
    return applyAiCategoryRules(
      retypeDraftsFromSource(parsed, trimmed),
      categoryRules,
    );
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
    List<String> accountNames = const [],
    String? accountContext,
    required String currencyHint,
    required List<({String role, String text})> history,
    bool fromSpeech = false,
    List<AiCategoryRule> categoryRules = const [],
    AiPartialCallback? onPartial,
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
      final turn = await _withRetryParse(() async {
        final cats = _catsForPrompt(categoryNames);
        final accountsBlob =
            (accountContext != null && accountContext.isNotEmpty)
                ? accountContext
                : _catsForPrompt(accountNames, limit: 24);
        final lang = _langName(locale);
        final recent = history.length <= 8
            ? history
            : history.sublist(history.length - 8);
        final hist = recent
            .map((h) =>
                '${h.role == 'user' ? 'User' : 'Assistant'}: ${h.text}')
            .join('\n');
        final accountRule = accountsBlob.isEmpty
            ? ''
            : ' When recording, set accountHint to an exact name from Accounts [$accountsBlob] if the user names a debit/from account; for transfers use type=transfer and toAccountHint from the same list.';
        final rules = categoryRulesPromptBlock(categoryRules);
        final fewShot = fewShotBlockForLocale(locale);
        final prompt = '''
Pulpo budget assistant (natural speech, like Budget AI). Reply in $lang, JSON only.
intent "record": extract ALL txs from casual speech; short confirm reply.$accountRule
  Each tx: {amount,currency,date,note,merchant,categoryHint from [$cats],accountHint,toAccountHint,type expense|income|transfer}
$rules
$fewShot
  Salary/wage/cashback/refund = income. NEVER mark those as expense after a spend list.
  note/merchant = 1–3 words, never full transcript or greetings.
intent "clarify": ONE short question if amount/account/transfer destination missing; transactions=[].
intent "question": answer from APP DATA only; transactions=[]. Use month totals and top categories when relevant.

Chat:
$hist

APP DATA:
$appContext

User: """$trimmed"""

{"intent":"record"|"clarify"|"question","reply":"...","transactions":[...]}
''';
        return _generate(
          [Content.text(prompt)],
          label: 'assistant_turn',
          preferStrong: fromSpeech || needsStrongAiModel(trimmed),
          onPartial: onPartial,
        );
      }, parseAssistantTurnJson);
      if (!turn.isRecord || turn.transactions.isEmpty) return turn;
      return AssistantTurnResult(
        intent: turn.intent,
        reply: turn.reply,
        transactions: applyAiCategoryRules(
          retypeDraftsFromSource(turn.transactions, trimmed),
          categoryRules,
        ),
      );
    } on PulpoAiException catch (e) {
      if (!e.allowsChatFallback) rethrow;
      // Soft JSON failure on a record-looking message → try batch, not chat.
      if (looksLikeTransactionRecord(trimmed)) {
        debugPrint('MonederoAI assistant_turn soft-fail → nl_batch: $e');
        try {
          final drafts = await parseNaturalLanguageBatch(
            trimmed,
            locale: locale,
            categoryNames: categoryNames,
            accountNames: accountNames,
            accountContext: accountContext,
            currencyHint: currencyHint,
            fromSpeech: fromSpeech,
            categoryRules: categoryRules,
          );
          if (drafts.isNotEmpty) {
            return AssistantTurnResult(
              intent: 'record',
              reply: '',
              transactions: drafts,
            );
          }
        } catch (batchErr) {
          debugPrint('MonederoAI assistant_turn batch retry failed: $batchErr');
        }
      }
      debugPrint('MonederoAI assistant_turn fallback to chat: $e');
      final reply = await chatAboutApp(
        userMessage: trimmed,
        appContext: appContext,
        locale: locale,
        history: history,
        onPartial: onPartial,
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
    AiPartialCallback? onPartial,
  }) async {
    final trimmed = userMessage.trim();
    if (isCasualGreeting(trimmed)) {
      return greetingReplyForLocale(locale);
    }

    final system = '''
You are Pulpo Assistant inside a personal budget app.
Reply in ${_langName(locale)}. Be concise and clear.

Hard rules:
- Use ONLY facts from APP DATA below. Do not invent numbers, accounts, or transactions.
- Do NOT give financial, investment, tax, credit, or budgeting advice. Do not recommend what to buy, cut, save, invest, or borrow.
- You may restate, filter, compare, and explain what is already in APP DATA (balances, month totals, top categories, recent txs, budgets, goals, debts).
- If the user asks for advice or anything outside APP DATA, politely refuse and say you can only talk about data already in the app.
- If APP DATA does not contain the answer, say you don't have that information in the app.

APP DATA:
$appContext
''';
    final recent = history.length <= 8
        ? history
        : history.sublist(history.length - 8);
    final hist = recent
        .map((h) => '${h.role == 'user' ? 'User' : 'Assistant'}: ${h.text}')
        .join('\n');
    final prompt = '''
$system

Recent chat:
$hist

User message: """$trimmed"""
''';
    return _generate(
      [Content.text(prompt)],
      label: 'chat',
      json: false,
      onPartial: onPartial,
    );
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
