import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/features/assistant/assistant_ai_history.dart';
import 'package:pulpo/src/features/assistant/assistant_chat_format.dart';

void main() {
  test('compressChatMessageForAi collapses markdown tables', () {
    const body = '''
Aquí tienes el resumen.

| Categoría | Fecha | Importe |
| --- | --- | --- |
| Café | 01/10 | 3,50 € |
| TOTAL |  | 3,50 € |
''';
    final compressed = compressChatMessageForAi(body);
    expect(compressed, contains('Aquí tienes'));
    expect(compressed, contains('[table:'));
    expect(compressed, contains('total'));
    expect(compressed.contains('| Café |'), isFalse);
  });

  test('buildSessionMemory includes account and recent asks', () {
    final memory = buildSessionMemory(
      history: const [
        (role: 'user', text: '¿cuál es mi saldo?'),
        (role: 'model', text: 'Tienes 120 €'),
        (role: 'user', text: '¿puedo gastar 50?'),
      ],
      accountName: 'Efectivo',
      currency: 'EUR',
    );
    expect(memory, contains('Efectivo'));
    expect(memory, contains('EUR'));
    expect(memory, contains('puedo gastar'));
  });

  test('composeReplyWithTable still round-trips', () {
    final md = composeReplyWithTable(
      'Intro',
      null,
    );
    expect(md, 'Intro');
  });
}
