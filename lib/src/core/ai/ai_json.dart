import 'dart:convert';

import 'ai_models.dart';

/// Parse model text into JSON map. Strips markdown fences if present.
Map<String, dynamic> decodeAiJsonObject(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    final firstNl = text.indexOf('\n');
    if (firstNl != -1) text = text.substring(firstNl + 1);
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3).trim();
    }
  }
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON object in AI response');
  }
  final decoded = jsonDecode(text.substring(start, end + 1));
  if (decoded is! Map) {
    throw const FormatException('AI JSON root is not an object');
  }
  return Map<String, dynamic>.from(decoded);
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final cleaned = v.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned);
  }
  return null;
}

String? _asString(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

String _normalizeType(Object? v) {
  final s = (_asString(v) ?? 'expense').toLowerCase();
  if (s == 'income' || s == 'ingreso' || s == 'доход') return 'income';
  return 'expense';
}

ReceiptParseResult parseReceiptJson(String raw) {
  final m = decodeAiJsonObject(raw);
  return ReceiptParseResult(
    amount: _asDouble(m['amount']),
    currency: _asString(m['currency']),
    dateIso: _asString(m['date']),
    merchant: _asString(m['merchant']),
    note: _asString(m['note']),
    categoryHint: _asString(m['categoryHint'] ?? m['category']),
    type: _normalizeType(m['type']),
  );
}

TransactionDraftFromAi parseTransactionDraftJson(String raw) {
  return parseTransactionDraftBatchJson(raw).first;
}

CategorySuggestion parseCategorySuggestionJson(String raw) {
  final m = decodeAiJsonObject(raw);
  final name = _asString(m['categoryName'] ?? m['category'] ?? m['name']);
  if (name == null) {
    throw const FormatException('Missing categoryName');
  }
  return CategorySuggestion(
    categoryName: name,
    confidence: _asDouble(m['confidence']),
  );
}

PeriodInsight parsePeriodInsightJson(String raw) {
  final m = decodeAiJsonObject(raw);
  final text = _asString(m['insight'] ?? m['text']);
  if (text == null) {
    throw const FormatException('Missing insight text');
  }
  return PeriodInsight(text: text);
}

TransactionDraftFromAi _draftFromMap(Map<String, dynamic> m) {
  return TransactionDraftFromAi(
    amount: _asDouble(m['amount']),
    currency: _asString(m['currency']),
    dateIso: _asString(m['date']),
    note: _asString(m['note']),
    merchant: _asString(m['merchant']),
    categoryHint: _asString(m['categoryHint'] ?? m['category']),
    type: _normalizeType(m['type']),
  );
}

/// Parses `{"transactions":[...]}` or a single draft object.
List<TransactionDraftFromAi> parseTransactionDraftBatchJson(String raw) {
  final m = decodeAiJsonObject(raw);
  final list = m['transactions'] ?? m['items'] ?? m['drafts'];
  if (list is List) {
    final out = <TransactionDraftFromAi>[];
    for (final item in list) {
      if (item is! Map) continue;
      final draft = _draftFromMap(Map<String, dynamic>.from(item));
      if (draft.amount == null || draft.amount! <= 0) continue;
      out.add(draft);
    }
    if (out.isEmpty) {
      throw const FormatException('No valid transactions in AI response');
    }
    return out;
  }
  // Fallback: single object at root
  final single = _draftFromMap(m);
  if (single.amount == null || single.amount! <= 0) {
    throw const FormatException('Missing amount');
  }
  return [single];
}

