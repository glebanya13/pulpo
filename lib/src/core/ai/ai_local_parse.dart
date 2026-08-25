import 'ai_models.dart';

/// Ultra-fast path: parse simple single-amount messages without calling Gemini.
/// Returns null when the text is too complex / ambiguous.
List<TransactionDraftFromAi>? tryParseLocalTransactions(
  String text, {
  String? currencyHint,
  List<String> categoryNames = const [],
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.length > 80) return null;

  // Multiple amounts → AI.
  final amountMatches = RegExp(
    r'(\d+(?:[.,]\d{1,2})?)',
  ).allMatches(trimmed);
  if (amountMatches.length != 1) return null;

  final amountRaw = amountMatches.first.group(1)!;
  final amount = double.tryParse(amountRaw.replaceAll(',', '.'));
  if (amount == null || amount <= 0) return null;

  final lower = trimmed.toLowerCase();

  // Skip questions and multi-clause sentences.
  if (lower.contains('?') || lower.contains('¿')) return null;
  if (RegExp(r'\b(и|and|y|та)\b').hasMatch(lower) &&
      lower.split(RegExp(r'\s+')).length > 6) {
    return null;
  }

  var currency = _detectCurrency(lower) ?? currencyHint;
  var type = 'expense';
  if (RegExp(
    r'(earned|earn|income|зарплат|заработал|заробив|получил|доход|дохід|ingreso|cobré)',
  ).hasMatch(lower)) {
    type = 'income';
  }

  // Strip amount + currency tokens to leave a note.
  var note = trimmed
      .replaceAll(RegExp(r'\d+(?:[.,]\d{1,2})?'), ' ')
      .replaceAll(
        RegExp(
          r'(€|\$|£|₴|₽|¥)|(eur|usd|uah|pln|gbp|euro|euros|доллар|евро|грн|руб)',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(
        RegExp(
          r'(spent|spend|paid|pay|bought|buy|cost|earned|earn|received|'
          r'потратил|потратила|купил|купила|заплатил|заработал|'
          r'витратив|купив|заплатив|заробив|gast[eé]|pagué|compré|ingreso)',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (note.length < 2) return null;

  final categoryHint = _matchCategory(note, categoryNames);

  return [
    TransactionDraftFromAi(
      amount: amount,
      currency: currency?.toUpperCase(),
      note: note,
      categoryHint: categoryHint,
      type: type,
    ),
  ];
}

String? _detectCurrency(String lower) {
  if (lower.contains('€') ||
      RegExp(r'(eur|euro|euros|евро)').hasMatch(lower)) {
    return 'EUR';
  }
  if (lower.contains('\$') ||
      RegExp(r'(usd|dollar|доллар)').hasMatch(lower)) {
    return 'USD';
  }
  if (lower.contains('₴') || RegExp(r'(uah|грн)').hasMatch(lower)) {
    return 'UAH';
  }
  if (lower.contains('£') || RegExp(r'gbp').hasMatch(lower)) {
    return 'GBP';
  }
  if (lower.contains('₽') || RegExp(r'руб').hasMatch(lower)) {
    return 'RUB';
  }
  return null;
}

String? _matchCategory(String note, List<String> categoryNames) {
  if (categoryNames.isEmpty) return null;
  final n = note.toLowerCase();
  for (final c in categoryNames) {
    final cn = c.toLowerCase();
    if (cn == n || n.contains(cn) || cn.contains(n)) return c;
  }
  // Light keyword map → first matching localized category name containing key.
  const keys = <String, List<String>>{
    'food': ['еда', 'їжа', 'comida', 'food', 'кофе', 'кава', 'cafe', 'coffee'],
    'transport': [
      'транспорт',
      'transport',
      'такси',
      'taxi',
      'автобус',
      'bus',
      'metro',
    ],
  };
  for (final entry in keys.entries) {
    if (!entry.value.any(n.contains)) continue;
    for (final c in categoryNames) {
      final cn = c.toLowerCase();
      if (entry.value.any(cn.contains) || cn.contains(entry.key)) return c;
    }
  }
  return null;
}
