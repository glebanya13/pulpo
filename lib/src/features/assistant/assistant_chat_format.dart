// Parses assistant prose + optional GFM markdown tables into rich chat UI.
// Also serializes structured [AiChatTable] into markdown for storage.

import '../../core/ai/ai_models.dart';

List<ChatBodyBlock> parseChatBody(String raw) {
  final text = raw.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty) return const [];

  final lines = text.split('\n');
  final blocks = <ChatBodyBlock>[];
  final prose = StringBuffer();

  void flushProse() {
    final p = prose.toString().trim();
    if (p.isNotEmpty) blocks.add(ChatBodyBlock.prose(p));
    prose.clear();
  }

  var i = 0;
  while (i < lines.length) {
    final table = _tryParseMarkdownTable(lines, i);
    if (table != null) {
      flushProse();
      blocks.add(ChatBodyBlock.table(table.$1));
      i = table.$2;
      continue;
    }
    prose.writeln(lines[i]);
    i++;
  }
  flushProse();
  return blocks;
}

/// Merge structured [table] into [reply] as GFM markdown (idempotent).
String composeReplyWithTable(String reply, AiChatTable? table) {
  final prose = reply.trim();
  if (table == null) return prose;
  if (parseChatBody(prose).any((b) => b is ChatTableBlock)) return prose;

  final md = chatTableToMarkdown(table);
  if (prose.isEmpty) return md;
  return '$prose\n\n$md';
}

String chatTableToMarkdown(AiChatTable table) {
  final headers = table.headers;
  final buf = StringBuffer()
    ..writeln('| ${headers.join(' | ')} |')
    ..writeln('| ${headers.map((_) => '---').join(' | ')} |');
  for (final row in table.rows) {
    final cells = List<String>.generate(
      headers.length,
      (i) {
        final raw = i < row.length ? row[i] : '';
        return formatChatTableCell(
          header: headers[i],
          cell: raw,
          isLastColumn: i == headers.length - 1,
        );
      },
    );
    buf.writeln('| ${cells.join(' | ')} |');
  }
  final total = table.total?.trim();
  if (total != null && total.isNotEmpty) {
    final cells = List<String>.filled(headers.length, '');
    cells[0] = 'TOTAL';
    cells[headers.length - 1] = total;
    buf.writeln('| ${cells.join(' | ')} |');
  }
  return buf.toString().trimRight();
}

/// Returns `(table, nextLineIndex)` or null.
(ChatMarkdownTable, int)? _tryParseMarkdownTable(List<String> lines, int start) {
  if (start + 1 >= lines.length) return null;
  final headerLine = lines[start].trim();
  final sepLine = lines[start + 1].trim();
  if (!_looksLikeTableRow(headerLine) || !_looksLikeSeparator(sepLine)) {
    return null;
  }

  final headers = _splitRow(headerLine);
  if (headers.length < 2) return null;

  final rows = <List<String>>[];
  var i = start + 2;
  while (i < lines.length) {
    final line = lines[i].trim();
    if (!_looksLikeTableRow(line)) break;
    final cells = _splitRow(line);
    if (cells.isEmpty) break;
    final row = List<String>.generate(
      headers.length,
      (c) => c < cells.length ? cells[c] : '',
    );
    rows.add(row);
    i++;
  }
  if (rows.isEmpty) return null;
  return (ChatMarkdownTable(headers: headers, rows: rows), i);
}

bool _looksLikeTableRow(String line) {
  if (!line.contains('|')) return false;
  final t = line.trim();
  return t.split('|').where((c) => c.trim().isNotEmpty).length >= 2;
}

bool _looksLikeSeparator(String line) {
  final t = line.trim();
  if (!t.contains('|') && !t.contains('-')) return false;
  final cells = t.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty);
  if (cells.isEmpty) return false;
  return cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c));
}

List<String> _splitRow(String line) {
  var t = line.trim();
  if (t.startsWith('|')) t = t.substring(1);
  if (t.endsWith('|')) t = t.substring(0, t.length - 1);
  return t.split('|').map((c) => c.trim()).toList();
}

bool isChatTableTotalLabel(String cell) {
  final n = cell.trim().toLowerCase();
  return n == 'total' ||
      n == 'totales' ||
      n == 'итого' ||
      n == 'всего' ||
      n == 'усього' ||
      n == 'suma' ||
      n.startsWith('total ');
}

/// True for localized Date / Fecha / Дата column headers.
bool isChatTableDateHeader(String header) {
  final n = header.trim().toLowerCase();
  return n == 'date' ||
      n == 'fecha' ||
      n == 'дата' ||
      n == 'день' ||
      n.startsWith('date ') ||
      n.startsWith('fecha ');
}

/// Compact ISO / long dates to `DD/MM/YY` for chat tables.
String compactChatTableDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return s;

  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
  final m = iso.firstMatch(s);
  if (m != null) {
    final yy = m.group(1)!.substring(2);
    return '${m.group(3)}/${m.group(2)}/$yy';
  }

  // Already DD/MM/YY or DD/MM/YYYY
  final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2}|\d{4})$');
  final sm = slash.firstMatch(s);
  if (sm != null) {
    final d = sm.group(1)!.padLeft(2, '0');
    final mo = sm.group(2)!.padLeft(2, '0');
    var y = sm.group(3)!;
    if (y.length == 4) y = y.substring(2);
    return '$d/$mo/$y';
  }

  return s;
}

/// Format a table cell for display (compact dates in date columns).
String formatChatTableCell({
  required String header,
  required String cell,
  required bool isLastColumn,
}) {
  if (isChatTableDateHeader(header) || (!isLastColumn && _looksLikeIsoDate(cell))) {
    return compactChatTableDate(cell);
  }
  return cell;
}

bool _looksLikeIsoDate(String cell) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(cell.trim());

class ChatMarkdownTable {
  const ChatMarkdownTable({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;
}

sealed class ChatBodyBlock {
  const ChatBodyBlock();
  factory ChatBodyBlock.prose(String text) = ChatProseBlock;
  factory ChatBodyBlock.table(ChatMarkdownTable table) = ChatTableBlock;
}

class ChatProseBlock extends ChatBodyBlock {
  const ChatProseBlock(this.text);
  final String text;
}

class ChatTableBlock extends ChatBodyBlock {
  const ChatTableBlock(this.table);
  final ChatMarkdownTable table;
}
