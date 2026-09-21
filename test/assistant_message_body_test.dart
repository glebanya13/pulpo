import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/ai/ai_models.dart';
import 'package:pulpo/src/features/assistant/assistant_chat_format.dart';

void main() {
  test('parses GFM table between prose', () {
    const raw = '''
En enero gastaste en Transporte:

| Categoría | Fecha | Gasto |
| --- | --- | --- |
| Transporte | 04 de Enero | \$41,789 |
| Transporte | 09 de Enero | \$27,156 |
| TOTAL |  | \$68,945 |

Eso es el resumen.
''';
    final blocks = parseChatBody(raw);
    expect(blocks.length, 3);
    expect(blocks[0], isA<ChatProseBlock>());
    final table = blocks[1] as ChatTableBlock;
    expect(table.table.headers, ['Categoría', 'Fecha', 'Gasto']);
    expect(table.table.rows.length, 3);
    expect(table.table.rows.last.first, 'TOTAL');
    expect(isChatTableTotalLabel('TOTAL'), isTrue);
    expect(blocks[2], isA<ChatProseBlock>());
  });

  test('plain prose stays one block', () {
    final blocks = parseChatBody('Saldo total: 100 EUR');
    expect(blocks, hasLength(1));
    expect(blocks.single, isA<ChatProseBlock>());
  });

  test('composeReplyWithTable merges structured table', () {
    final body = composeReplyWithTable(
      'Resumen:',
      const AiChatTable(
        headers: ['Cat', 'Amt'],
        rows: [
          ['Food', '10'],
        ],
        total: '10',
      ),
    );
    expect(body, startsWith('Resumen:'));
    expect(body, contains('| Cat | Amt |'));
    expect(body, contains('| TOTAL | 10 |'));
  });

  test('composeReplyWithTable is idempotent when markdown already present', () {
    const raw = '''
Intro

| A | B |
| --- | --- |
| 1 | 2 |
''';
    final composed = composeReplyWithTable(
      raw,
      const AiChatTable(headers: ['X', 'Y'], rows: [
        ['3', '4'],
      ]),
    );
    expect(composed.trim(), raw.trim());
  });
}
