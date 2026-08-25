/// Local fast-path: messages that clearly add expense/income — skip full chat turn.
bool looksLikeTransactionRecord(String text) {
  final t = text.trim().toLowerCase();
  if (t.length < 2 || t.length > 800) return false;
  if (!RegExp(r'\d').hasMatch(t)) return false;

  // Questions about existing data — not recording.
  if (t.contains('?') || t.contains('¿')) return false;
  if (RegExp(
    r'^(сколько|скільки|how\s+much|what|cuál|cual|cuánto|cuanto|donde|где|де)\b',
  ).hasMatch(t)) {
    return false;
  }
  if (RegExp(
    r'\b(сколько|скільки|how\s+much)\b.+\b(потрат|витрат|spent|gast)',
  ).hasMatch(t)) {
    return false;
  }

  final hasCurrency = RegExp(
    r'(€|\$|£|₴|₽|¥)|'
    r'(eur|usd|uah|pln|gbp|euro|euros|доллар|евро|грн|руб)',
  ).hasMatch(t);

  // "чай 20 евро" / "taxi 15€" — amount + currency is enough.
  if (hasCurrency) return true;

  const markers = [
    'spent',
    'spend',
    'paid',
    'pay',
    'bought',
    'buy',
    'cost',
    'earned',
    'earn',
    'received',
    'income',
    'expense',
    'потрат',
    'купил',
    'заплат',
    'заработал',
    'получил',
    'расход',
    'доход',
    'витрат',
    'купив',
    'заплатив',
    'заробив',
    'gast',
    'pagué',
    'compré',
    'ingreso',
    'cobré',
  ];
  return markers.any(t.contains);
}

/// Balance / accounts questions — only need a slim APP DATA snapshot.
bool looksLikeBalanceQuestion(String text) {
  final t = text.trim().toLowerCase();
  if (t.isEmpty || t.length > 120) return false;
  if (looksLikeTransactionRecord(t)) return false;
  // Avoid \b with Cyrillic — Dart word boundaries are ASCII-only.
  return RegExp(
    r'(баланс|balance|остаток|скільки\s+грошей|сколько\s+(денег|осталось)|'
    r'how\s+much\s+(money|do\s+i\s+have)|cu[aá]nto\s+(tengo|dinero)|'
    r'счета|рахунки|accounts?|кошел[её]к|wallet)',
  ).hasMatch(t);
}
