import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
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

  static const _modelName = 'gemini-2.5-flash';

  GenerativeModel get _jsonModel {
    return _model ??= FirebaseAI.googleAI(auth: _auth).generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
      ),
    );
  }

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw const PulpoAiException('sign_in_required');
    }
  }

  Future<String> _generate(List<Content> contents, {required String label}) async {
    _requireSignedIn();
    try {
      final response = await _jsonModel.generateContent(contents);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const PulpoAiException('empty_response');
      }
      return text;
    } on PulpoAiException {
      rethrow;
    } catch (e, st) {
      debugPrint('PulpoAI[$label]: $e');
      debugPrint('$st');
      throw const PulpoAiException('request_failed');
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
        debugPrint('PulpoAI parse retry: $e');
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
}

final pulpoAiServiceProvider = Provider<PulpoAiService>((ref) {
  return PulpoAiService();
});
