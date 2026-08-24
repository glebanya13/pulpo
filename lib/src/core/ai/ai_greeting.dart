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
  switch (locale) {
    case 'uk':
      return 'Привіт! Можу записати витрату чи дохід — наприклад «Кава 60». '
          'Також можу відповісти про дані в додатку.';
    case 'ru':
      return 'Привет! Могу записать расход или доход — например «Кофе 60». '
          'Также могу ответить про данные в приложении.';
    case 'en':
      return 'Hi! I can log an expense or income — try “Coffee 60”. '
          'I can also answer questions about your data in the app.';
    default:
      return '¡Hola! Puedo registrar un gasto o ingreso — prueba “Café 60”. '
          'También puedo responder sobre tus datos en la app.';
  }
}
