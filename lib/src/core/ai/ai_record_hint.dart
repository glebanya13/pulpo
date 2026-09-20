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
    r'(сколько|скільки|how\s+much).+(потрат|витрат|spent|gast|еду|comida|food)',
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
    'transfer',
    'salary',
    'paycheck',
    'cashback',
    'refund',
    'потрат',
    'купил',
    'заплат',
    'заработал',
    'получил',
    'пришла',
    'расход',
    'доход',
    'зарплат',
    'аванс',
    'кешбек',
    'кэшбек',
    'возврат',
    'перевод',
    'перевёл',
    'перевел',
    'переказ',
    'витрат',
    'купив',
    'заплатив',
    'заробив',
    'gast',
    'pagué',
    'compré',
    'ingreso',
    'sueldo',
    'nómina',
    'nomina',
    'cobré',
    'traspaso',
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

/// Budgets / goals / debts / category spend — needs a fuller snapshot.
bool looksLikeDeepFinanceQuestion(String text) {
  final t = text.trim().toLowerCase();
  if (t.isEmpty || t.length > 240) return false;
  if (looksLikeTransactionRecord(t)) return false;
  return RegExp(
    r'(бюджет|budget|цел[ьи]|goal|долг|debt|подписк|subscription|'
    r'категор|category|потратил.*(месяц|month|еду|food|транспорт)|'
    r'сколько.*(на|по)|топ\s+трат|overview|обзор)',
  ).hasMatch(t);
}

/// Multi-amount / mixed income / long narrative → prefer stronger model.
bool needsStrongAiModel(String text) {
  final t = text.trim();
  if (t.length > 160) return true;
  final amounts = RegExp(r'\d+(?:[.,]\d{1,2})?').allMatches(t).length;
  if (amounts >= 3) return true;
  final lower = t.toLowerCase();
  final hasIncome = RegExp(
    r'(зарплат|аванс|преми|salary|sueldo|n[oó]mina|paycheck|кешбек|'
    r'кэшбек|доход|ingreso|пришл|получ)',
  ).hasMatch(lower);
  final hasSpend = RegExp(
    r'(потрат|купил|расход|spent|bought|gast|taxi|хлеб|еда)',
  ).hasMatch(lower);
  if (hasIncome && hasSpend) return true;
  if (RegExp(r'(перевод|перевёл|перевел|transfer|traspaso)').hasMatch(lower) &&
      amounts >= 1) {
    return true;
  }
  return false;
}
