import 'ai_models.dart';

/// Ultra-fast path: parse simple single-amount messages without calling Gemini.
/// Returns null when the text is too complex / ambiguous.
List<TransactionDraftFromAi>? tryParseLocalTransactions(
  String text, {
  String? currencyHint,
  List<String> categoryNames = const [],
  List<String> accountNames = const [],
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

  final accountHint = _matchAccount(lower, accountNames);
  final toAccountHint = _matchTransferTo(lower, accountNames, accountHint);

  if (toAccountHint != null &&
      accountHint != null &&
      toAccountHint.toLowerCase() != accountHint.toLowerCase() &&
      RegExp(
        r'(перевод|перевёл|перевел|переказ|transfer|traspaso)',
      ).hasMatch(lower)) {
    type = 'transfer';
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
          r'витратив|купив|заплатив|заробив|gast[eé]|pagué|compré|ingreso|'
          r'перевод|перевёл|перевел|переказ|transfer|с\s+карт|с\s+карты|'
          r'с\s+карты|с\s+карточки|с\s+счета|со\s+счета|с\s+счёта|'
          r'на\s+карт|на\s+карту|на\s+счет|на\s+счёт)',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Drop matched account names from the leftover note.
  if (accountHint != null) {
    note = note
        .replaceAll(RegExp(RegExp.escape(accountHint), caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  if (toAccountHint != null) {
    note = note
        .replaceAll(
          RegExp(RegExp.escape(toAccountHint), caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  if (note.length < 2 && type != 'transfer') return null;

  final categoryHint =
      type == 'transfer' ? null : _matchCategory(note, categoryNames);

  return [
    TransactionDraftFromAi(
      amount: amount,
      currency: currency?.toUpperCase(),
      note: note.isEmpty ? null : note,
      categoryHint: categoryHint,
      accountHint: accountHint,
      toAccountHint: type == 'transfer' ? toAccountHint : null,
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

/// Longest account name whose tokens appear in [lower] (handles RU case endings
/// like «карты» ≈ «карта»).
String? _matchAccount(String lower, List<String> accountNames) {
  if (accountNames.isEmpty) return null;
  final sorted = [...accountNames]
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final name in sorted) {
    final tokens = name
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2);
    if (tokens.isEmpty) continue;
    if (tokens.every((t) => _tokenIn(lower, t))) return name;
  }
  return null;
}

bool _tokenIn(String hay, String token) {
  if (hay.contains(token)) return true;
  // Soft stem: drop 1–2 trailing letters for Slavic case endings.
  if (token.length >= 4 && hay.contains(token.substring(0, token.length - 1))) {
    return true;
  }
  if (token.length >= 5 && hay.contains(token.substring(0, token.length - 2))) {
    return true;
  }
  return false;
}

String? _matchTransferTo(
  String lower,
  List<String> accountNames,
  String? fromHint,
) {
  if (accountNames.isEmpty) return null;
  final sorted = [...accountNames]
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final name in sorted) {
    if (fromHint != null && name.toLowerCase() == fromHint.toLowerCase()) {
      continue;
    }
    final tokens = name
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
    if (tokens.isEmpty) continue;
    if (!tokens.every((t) => _tokenIn(lower, t))) continue;
    // Prefer names after "на …" / "to …".
    final last = tokens.last;
    if (RegExp(
      r'(?:на|to|hacia)\s+[^\d]{0,24}' + RegExp.escape(last.substring(0, last.length > 1 ? last.length - 1 : last.length)),
    ).hasMatch(lower)) {
      return name;
    }
  }
  // Second distinct account mentioned anywhere.
  final found = <String>[];
  for (final name in sorted) {
    final tokens = name
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2);
    if (tokens.isEmpty) continue;
    if (tokens.every((t) => _tokenIn(lower, t))) found.add(name);
  }
  if (found.length >= 2) {
    return found.firstWhere(
      (a) => fromHint == null || a.toLowerCase() != fromHint.toLowerCase(),
      orElse: () => found.last,
    );
  }
  return null;
}
