/// Real-world few-shot examples for NL / assistant prompts (STT noise included).
String fewShotBlockForLocale(String locale) {
  switch (locale) {
    case 'ru':
    case 'uk':
      return '''
Examples (follow this style; ignore greetings/commands in notes):
- "привет запиши хлеб 10 евро" → [{"amount":10,"note":"хлеб","type":"expense"}]
- "потратил пятнадцать на такси и восемь на кофе" → [{"amount":15,"note":"такси","type":"expense"},{"amount":8,"note":"кофе","type":"expense"}]
- "зарплата 3000 евро" / "пришла зарплата три тысячи" → [{"amount":3000,"note":"зарплата","type":"income"}]
- "купил в меркадоне на 45 и убер 12" → [{"amount":45,"note":"Mercadona","type":"expense"},{"amount":12,"note":"Uber","type":"expense"}]
- "перевёл 50 с карты на наличные" → [{"amount":50,"note":"перевод","type":"transfer","accountHint":"карта","toAccountHint":"наличные"}]
- "кешбек 12 евро" → [{"amount":12,"note":"кешбек","type":"income"}]
''';
    case 'en':
      return '''
Examples (follow this style; ignore greetings/commands in notes):
- "hey log bread 10 euros" → [{"amount":10,"note":"bread","type":"expense"}]
- "spent fifteen on taxi and eight on coffee" → [{"amount":15,"note":"taxi","type":"expense"},{"amount":8,"note":"coffee","type":"expense"}]
- "salary 3000 euros" → [{"amount":3000,"note":"salary","type":"income"}]
- "bought at mercadona for 45 and uber 12" → [{"amount":45,"note":"Mercadona","type":"expense"},{"amount":12,"note":"Uber","type":"expense"}]
- "transferred 50 from card to cash" → [{"amount":50,"note":"transfer","type":"transfer","accountHint":"card","toAccountHint":"cash"}]
- "cashback 12 euros" → [{"amount":12,"note":"cashback","type":"income"}]
''';
    default: // es
      return '''
Examples (follow this style; ignore greetings/commands in notes):
- "hola apunta pan 10 euros" → [{"amount":10,"note":"pan","type":"expense"}]
- "gasté quince en taxi y ocho en café" → [{"amount":15,"note":"taxi","type":"expense"},{"amount":8,"note":"café","type":"expense"}]
- "sueldo 3000 euros" / "me llegó la nómina de tres mil" → [{"amount":3000,"note":"sueldo","type":"income"}]
- "compré en mercadona por 45 y uber 12" → [{"amount":45,"note":"Mercadona","type":"expense"},{"amount":12,"note":"Uber","type":"expense"}]
- "pasé 50 de la tarjeta al efectivo" → [{"amount":50,"note":"traspaso","type":"transfer","accountHint":"tarjeta","toAccountHint":"efectivo"}]
- "cashback 12 euros" → [{"amount":12,"note":"cashback","type":"income"}]
''';
  }
}
