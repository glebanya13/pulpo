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

  test('compactChatTableDate formats ISO to DD/MM for current year', () {
    final now = DateTime(2026, 9, 26);
    expect(compactChatTableDate('2026-09-24', now: now), '24/09');
    expect(compactChatTableDate('2026-09-24T12:00:00', now: now), '24/09');
    expect(compactChatTableDate('24/09/2026', now: now), '24/09');
    expect(compactChatTableDate('24/09/26', now: now), '24/09');
    expect(compactChatTableDate('24/09', now: now), '24/09');
  });

  test('compactChatTableDate keeps year when not current', () {
    final now = DateTime(2026, 9, 26);
    expect(compactChatTableDate('2025-09-24', now: now), '24/09/25');
    expect(compactChatTableDate('24/09/2025', now: now), '24/09/25');
  });

  test('chatTableToMarkdown compactifies date column', () {
    final md = chatTableToMarkdown(
      const AiChatTable(
        headers: ['Categoría', 'Fecha', 'Importe'],
        rows: [
          ['Comida', '2026-09-24', '60'],
        ],
      ),
    );
    expect(md, contains('24/09'));
    expect(md, isNot(contains('2026-09-24')));
  });
}
