import 'dart:math';

/// Local fast-path: casual greetings should not hit Gemini.
bool isCasualGreeting(String text) {
  var t = text.trim().toLowerCase();
  if (t.isEmpty || t.length > 48) return false;
  t = t.replaceAll(RegExp(r'[!?.…,¡¿]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty) return false;

  const exact = {
    'hi',
    'hello',
    'hey',
    'yo',
    'sup',
    'hola',
    'buenas',
    'buen dia',
    'buen día',
    'buenos dias',
    'buenos días',
    'buenas tardes',
    'buenas noches',
    'привет',
    'приветик',
    'здравствуй',
    'здравствуйте',
    'здарова',
    'добрый день',
    'добрый вечер',
    'доброе утро',
    'привіт',
    'вітаю',
    'добрий день',
    'доброго ранку',
    'добрий вечір',
    'хай',
    'хелло',
    'хеллоу',
  };
  if (exact.contains(t)) return true;

  // Greeting + optional filler only ("hola amigo", "hi there") — never amounts.
  final parts = t.split(' ');
  if (parts.length == 2 && exact.contains(parts.first)) {
    const fillers = {
      'there',
      'amigo',
      'amigos',
      'all',
      'всем',
      'друзі',
      'друзья',
    };
    return fillers.contains(parts[1]);
  }
  return false;
}

String greetingReplyForLocale(String locale) {
  final variants = switch (locale) {
    'uk' => const [
        'Привіт! Можу записати витрату чи дохід — наприклад «Кава 60». '
            'Також підкажу по балансу чи витратах за період.',
        'Йо! Пиши витрату текстом або питай про дані в додатку — я на місці.',
        'Привіт. Що перевіримо: витрати, доходи чи баланс?',
      ],
    'ru' => const [
        'Привет! Могу записать расход или доход — например «Кофе 60». '
            'Также отвечу по балансу или тратам за период.',
        'Привет. Пиши трату текстом или спрашивай по данным в приложении.',
        'Здравствуй! Чем помочь — запись, баланс или расходы за период?',
      ],
    'en' => const [
        'Hi! I can log an expense or income — try “Coffee 60”. '
            'I can also answer about your balances and spending.',
        'Hey — send a spend in plain text, or ask about your numbers in the app.',
        'Hi. Want to log something, or check balances / period spend?',
      ],
    _ => const [
        '¡Hola! Puedo registrar un gasto o ingreso — prueba “Café 60”. '
            'También te respondo sobre saldo o gastos del periodo.',
        'Hola. Escribe un gasto en texto o pregunta por tus datos en la app.',
        '¡Hey! ¿Registramos algo o miramos saldo / gastos del periodo?',
      ],
  };
  return variants[Random().nextInt(variants.length)];
}
