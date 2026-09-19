import 'ai_models.dart';

/// Fast path: parse spoken/typed expense lines without calling Gemini.
/// Handles a single amount or a list of amounts in one message.
/// Returns null when the text is too ambiguous for local rules (caller uses Gemini).
List<TransactionDraftFromAi>? tryParseLocalTransactions(
  String text, {
  String? currencyHint,
  List<String> categoryNames = const [],
  List<String> accountNames = const [],
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed.length > 800) return null;
  if (trimmed.contains('?') || trimmed.contains('¿')) return null;

  final normalized = _normalizeWordAmounts(trimmed);
  final amounts = _amountMatches(normalized);
  if (amounts.isEmpty) return null;

  // Chatty multi-amount speech → Gemini (local splits make garbage notes).
  if (amounts.length >= 2 && _isChattySpeech(normalized)) {
    return null;
  }

  if (amounts.length == 1) {
    return _parseSingle(
      normalized,
      amounts.first,
      currencyHint: currencyHint,
      categoryNames: categoryNames,
      accountNames: accountNames,
    );
  }

  return _parseMulti(
    normalized,
    amounts,
    currencyHint: currencyHint,
    categoryNames: categoryNames,
    accountNames: accountNames,
  );
}

/// True when local multi-split would mangle notes — prefer Gemini.
bool _isChattySpeech(String text) {
  final lower = text.toLowerCase();
  if (_hasGreetingOrRecordCommand(lower)) return true;
  // Dictation / narrative filler (not list words like "también").
  if (RegExp(
    r'(потому\s+что|because|например|for\s+example|por\s+ejemplo|'
    r'and\s+then\s+i|сначала\s+я|я\s+(говорил|сказала|сказал)|'
    r'i\s+(said|told|spoke)|me\s+dijo)',
    caseSensitive: false,
  ).hasMatch(lower)) {
    return true;
  }
  // Very long multi-amount with lots of words per amount.
  if (text.length > 220) {
    final amounts = _amountMatches(text);
    if (amounts.length >= 2 && text.length / amounts.length > 50) {
      return true;
    }
  }
  return false;
}

bool _hasGreetingOrRecordCommand(String lower) {
  return RegExp(
    r'(^|[^\p{L}\p{N}_])('
    r'привет|здравствуй(?:те)?|хай|hello|hi|hey|hola|buenas?|'
    r'запиши|записывай|запишите|добавь|добавить|внеси|внести|'
    r'record|anota|anotar|registra|registrar|'
    r'расход(?:ы|ов)?|доход(?:ы|ов)?|expense[s]?|gasto[s]?'
    r')(?=$|[^\p{L}\p{N}_])',
    caseSensitive: false,
    unicode: true,
  ).hasMatch(lower);
}

/// Shorten/clean note or merchant from local or Gemini output.
String? sanitizeLedgerLabel(String? raw) {
  if (raw == null) return null;
  final cleaned = _cleanNote(raw);
  if (cleaned.length < 2) return null;
  return cleaned;
}

/// Apply [sanitizeLedgerLabel] to note/merchant on every draft.
List<TransactionDraftFromAi> sanitizeTransactionDrafts(
  List<TransactionDraftFromAi> drafts,
) {
  return drafts.map((d) {
    final note = sanitizeLedgerLabel(d.note);
    final merchant = sanitizeLedgerLabel(d.merchant);
    // Prefer the shorter clean label as note when both exist.
    String? bestNote = note;
    if (merchant != null) {
      if (bestNote == null || merchant.length < bestNote.length) {
        bestNote = merchant;
      }
    }
    final blob = [
      d.note,
      d.merchant,
      bestNote,
      merchant,
      d.categoryHint,
    ].whereType<String>().join(' ').toLowerCase();
    var type = d.type;
    if (type != 'transfer' && _looksLikeIncome(blob)) {
      type = 'income';
    }
    return d.copyWith(
      note: bestNote ?? d.note ?? d.merchant,
      merchant: merchant ?? d.merchant,
      type: type,
    );
  }).toList();
}

bool _looksLikeIncome(String lower) {
  return RegExp(
    r'(зарплат|заработн|аванс|преми|salary|salaries|wage|wages|paycheck|'
    r'payroll|income|earned|sueldo|n[oó]mina|ingreso|доход|дохід|'
    r'заработал|заробив|получил|cobr[eé]|gan[eé]|ganaste|выиграл)',
    caseSensitive: false,
  ).hasMatch(lower);
}

class _AmountHit {
  const _AmountHit({
    required this.amount,
    required this.start,
    required this.end,
    this.currency,
  });

  final double amount;
  final int start;
  final int end;
  final String? currency;
}

final _amountRe = RegExp(
  r'(?:(€|\$|£|₴|₽|¥)\s*)?'
  r'(\d+(?:[.,]\d{1,2})?)'
  r'(?:\s*(€|\$|£|₴|₽|¥|euros?|eur|usd|uah|pln|gbp|грн|руб|евро|доллар(?:ов|а)?))?',
  caseSensitive: false,
);

List<_AmountHit> _amountMatches(String text) {
  final out = <_AmountHit>[];
  for (final m in _amountRe.allMatches(text)) {
    final raw = m.group(2);
    if (raw == null) continue;
    final amount = double.tryParse(raw.replaceAll(',', '.'));
    if (amount == null || amount <= 0) continue;
    final sym = m.group(1) ?? m.group(3);
    out.add(
      _AmountHit(
        amount: amount,
        start: m.start,
        end: m.end,
        currency: _currencyFromToken(sym),
      ),
    );
  }
  return out;
}

String? _currencyFromToken(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final t = raw.toLowerCase();
  if (t == '€' || t.startsWith('eur') || t == 'евро') return 'EUR';
  if (t == r'$' || t.startsWith('usd') || t.startsWith('доллар')) return 'USD';
  if (t == '₴' || t == 'uah' || t == 'грн') return 'UAH';
  if (t == '£' || t == 'gbp') return 'GBP';
  if (t == '₽' || t.startsWith('руб')) return 'RUB';
  if (t == '¥') return 'JPY';
  if (t == 'pln') return 'PLN';
  return null;
}

/// "un euro" / "cinco euros" / "два евро" → digit+symbol so multi-split works.
String _normalizeWordAmounts(String text) {
  var t = text;
  const pairs = <(String, String)>[
    (r'\bun\s+euro\b', '1€'),
    (r'\buna\s+euro\b', '1€'),
    (r'\bun\s+euros?\b', '1€'),
    (r'\bdos\s+euros?\b', '2€'),
    (r'\btres\s+euros?\b', '3€'),
    (r'\bcuatro\s+euros?\b', '4€'),
    (r'\bcinco\s+euros?\b', '5€'),
    (r'\bseis\s+euros?\b', '6€'),
    (r'\bsiete\s+euros?\b', '7€'),
    (r'\bocho\s+euros?\b', '8€'),
    (r'\bnueve\s+euros?\b', '9€'),
    (r'\bdiez\s+euros?\b', '10€'),
    (r'\bодин\s+евро\b', '1€'),
    (r'\bодна\s+евро\b', '1€'),
    (r'\bдва\s+евро\b', '2€'),
    (r'\bдве\s+евро\b', '2€'),
    (r'\bтри\s+евро\b', '3€'),
    (r'\bпять\s+евро\b', '5€'),
    (r'\bдесять\s+евро\b', '10€'),
    (r'\bодин\s+долар\b', r'$1'),
    (r'\bun\s+d[oó]lar\b', r'$1'),
  ];
  for (final (pattern, repl) in pairs) {
    t = t.replaceAll(RegExp(pattern, caseSensitive: false), repl);
  }
  return t;
}

List<TransactionDraftFromAi>? _parseSingle(
  String text,
  _AmountHit hit, {
  String? currencyHint,
  List<String> categoryNames = const [],
  List<String> accountNames = const [],
}) {
  // Keep old guard: very chatty single-amount prose → AI.
  if (text.length > 120) return null;

  final lower = text.toLowerCase();
  final type = _detectType(lower);
  final currency =
      hit.currency ?? _detectCurrency(lower) ?? currencyHint?.toUpperCase();
  final accountHint = _matchAccount(lower, accountNames);
  final toAccountHint = _matchTransferTo(lower, accountNames, accountHint);
  var resolvedType = type;
  if (toAccountHint != null &&
      accountHint != null &&
      toAccountHint.toLowerCase() != accountHint.toLowerCase() &&
      RegExp(
        r'(перевод|перевёл|перевел|переказ|transfer|traspaso)',
      ).hasMatch(lower)) {
    resolvedType = 'transfer';
  }

  var note = _cleanNote(
    text.replaceRange(hit.start, hit.end, ' '),
    accountHint: accountHint,
    toAccountHint: toAccountHint,
  );
  if (note.length < 2 && resolvedType != 'transfer') return null;

  return [
    TransactionDraftFromAi(
      amount: hit.amount,
      currency: currency,
      note: note.isEmpty ? null : note,
      categoryHint: resolvedType == 'transfer'
          ? null
          : _matchCategory(note, categoryNames),
      accountHint: accountHint,
      toAccountHint: resolvedType == 'transfer' ? toAccountHint : null,
      type: resolvedType,
    ),
  ];
}

List<TransactionDraftFromAi>? _parseMulti(
  String text,
  List<_AmountHit> amounts, {
  String? currencyHint,
  List<String> categoryNames = const [],
  List<String> accountNames = const [],
}) {
  if (amounts.length > 25) return null;

  final globalCurrency =
      _detectCurrency(text.toLowerCase()) ?? currencyHint?.toUpperCase();
  final drafts = <TransactionDraftFromAi>[];

  for (var i = 0; i < amounts.length; i++) {
    final hit = amounts[i];
    final prevEnd = i == 0 ? 0 : amounts[i - 1].end;
    final nextStart = i + 1 < amounts.length ? amounts[i + 1].start : text.length;

    final before = text.substring(prevEnd, hit.start).trim();
    final after = text.substring(hit.end, nextStart).trim();
    final slice = '$before $after'.trim();
    if (slice.isEmpty && before.isEmpty && after.isEmpty) continue;

    final lower = slice.toLowerCase();
    final type = _detectType(lower);
    var note = _cleanNote(slice);
    // Drop leading connectors left from splitting.
    note = note
        .replaceFirst(
          RegExp(
            r'^(y\s+tambi[eé]n|и\s+ещё|и\s+также|and\s+also|tambi[eé]n|también|y|и|and)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (note.length < 2) {
      // Still keep amount-only scraps from spoken lists.
      note = type == 'income' ? 'income' : 'expense';
    }

    drafts.add(
      TransactionDraftFromAi(
        amount: hit.amount,
        currency: hit.currency ?? globalCurrency,
        note: note,
        categoryHint: _matchCategory(note, categoryNames),
        accountHint: _matchAccount(lower, accountNames),
        type: type,
      ),
    );
  }

  return drafts.length >= 2 ? drafts : null;
}

String _detectType(String lower) {
  if (_looksLikeIncome(lower)) {
    return 'income';
  }
  return 'expense';
}

/// Strip commands/filler and keep a short merchant/item label for the ledger.
String _cleanNote(
  String raw, {
  String? accountHint,
  String? toAccountHint,
}) {
  // Dart `\b` is ASCII-only — use explicit edges for ru/uk/es words.
  var note = raw
      .replaceAll(
        RegExp(
          r'(€|\$|£|₴|₽|¥)|(eur|usd|uah|pln|gbp|euro|euros|доллар|евро|грн|руб)',
          caseSensitive: false,
        ),
        ' ',
      )
      // Greetings + “record this” commands — never part of the note.
      .replaceAllMapped(
        RegExp(
          r'(^|[^\p{L}\p{N}_])('
          r'привет|здравствуй(?:те)?|хай|hello|hi|hey|hola|buenas?|'
          r'запиши|записывай|запишите|добавь|добавить|внеси|внести|'
          r'record|add|log|save|anota|anotar|registra|registrar|'
          r'расход(?:ы|ов)?|доход(?:ы|ов)?|трат[аыу]|expense[s]?|income|'
          r'gasto[s]?|ingreso[s]?|операци[юя]|transaction[s]?'
          r')(?=$|[^\p{L}\p{N}_])',
          caseSensitive: false,
          unicode: true,
        ),
        (m) => '${m[1]} ',
      )
      .replaceAll(
        RegExp(
          r'(spent|spend|paid|pay|bought|buy|cost|earned|earn|received|'
          r'потратил|потратила|купил|купила|заплатил|заработал|'
          r'витратив|купив|заплатив|заробив|gast[eé]|pagué|compré|ingreso|'
          r'gan[eé]|también|tambien|'
          r'перевод|перевёл|перевел|переказ|transfer|с\s+карт|с\s+карты|'
          r'с\s+карточки|с\s+счета|со\s+счета|с\s+счёта|'
          r'на\s+карт|на\s+карту|на\s+счет|на\s+счёт|'
          r'\bpor\b|\ben\s+unas?\b|\bunos?\b|\bunas?\b|\bpara\b|'
          r'porque|потому\s+что|так\s+как|because|'
          r'вчера|сегодня|завтра|ayer|hoy|yesterday|today)',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'(?:^|[^\p{L}])en(?=$|[^\p{L}])', caseSensitive: false, unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (accountHint != null) {
    note = note
        .replaceAll(
          RegExp(RegExp.escape(accountHint), caseSensitive: false),
          ' ',
        )
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

  return _compactNote(note);
}

/// Prefer a short item/merchant label (last meaningful words).
String _compactNote(String note) {
  if (note.isEmpty) return note;
  final words = note
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1)
      .where((w) => !RegExp(r'^[\d.,]+$').hasMatch(w))
      .toList();
  if (words.isEmpty) return note;
  if (words.length <= 3 && note.length <= 40) {
    return words.join(' ');
  }
  // Spoken prose: keep the last 1–3 content words near the amount.
  final take = words.length >= 3 ? 3 : words.length;
  return words.sublist(words.length - take).join(' ');
}

String? _detectCurrency(String lower) {
  if (lower.contains('€') ||
      RegExp(r'(eur|euro|euros|евро)').hasMatch(lower)) {
    return 'EUR';
  }
  if (lower.contains(r'$') ||
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
  const keys = <String, List<String>>{
    'food': [
      'еда',
      'їжа',
      'comida',
      'food',
      'кофе',
      'кава',
      'cafe',
      'café',
      'coffee',
      'хлеб',
      'pan',
      'leche',
      'молоко',
      'chuches',
      'flores',
      'цветы',
      'patatas',
      'sneakers',
    ],
    'transport': [
      'транспорт',
      'transport',
      'такси',
      'taxi',
      'автобус',
      'autobús',
      'autobus',
      'bus',
      'metro',
      'billete',
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
    final last = tokens.last;
    if (RegExp(
      r'(?:на|to|hacia)\s+[^\d]{0,24}' +
          RegExp.escape(
            last.substring(0, last.length > 1 ? last.length - 1 : last.length),
          ),
    ).hasMatch(lower)) {
      return name;
    }
  }
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
