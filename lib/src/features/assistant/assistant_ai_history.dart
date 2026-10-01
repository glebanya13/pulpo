import '../../data/db/app_database.dart' as db;
import 'assistant_chat_format.dart';

/// Compress one chat bubble for Gemini context (tables → one-line fact).
String compressChatMessageForAi(String body, {int maxProse = 160}) {
  final blocks = parseChatBody(body);
  if (blocks.isEmpty) {
    return _clip(body.trim(), maxProse);
  }
  final parts = <String>[];
  for (final b in blocks) {
    switch (b) {
      case ChatProseBlock(:final text):
        final t = text.trim();
        if (t.isNotEmpty) parts.add(_clip(t, maxProse));
      case ChatTableBlock(:final table):
        final n = table.rows
            .where((r) => r.isEmpty || !isChatTableTotalLabel(r.first))
            .length;
        String? total;
        for (final r in table.rows) {
          if (r.isNotEmpty && isChatTableTotalLabel(r.first)) {
            total = r.last.trim();
            break;
          }
        }
        parts.add(
          total == null || total.isEmpty
              ? '[table: $n rows]'
              : '[table: $n rows, total $total]',
        );
    }
  }
  return parts.join(' ').trim();
}

/// Last N turns, welcome skipped, assistant tables compressed.
List<({String role, String text})> buildCompressedChatHistory(
  List<db.AssistantMessage> messages,
  String welcome, {
  int maxTurns = 10,
}) {
  final prior = <({String role, String text})>[];
  for (var i = 0; i < messages.length - 1; i++) {
    final m = messages[i];
    if (!m.isFromUser && m.body == welcome) continue;
    // Skip long error dumps.
    if (!m.isFromUser && m.body.length > 1200 && !m.body.contains('|')) {
      continue;
    }
    final text = m.isFromUser
        ? _clip(m.body.trim(), 220)
        : compressChatMessageForAi(m.body);
    if (text.isEmpty) continue;
    prior.add((role: m.isFromUser ? 'user' : 'model', text: text));
  }
  if (prior.length <= maxTurns) return prior;
  return prior.sublist(prior.length - maxTurns);
}

/// Short session facts so Gemini remembers account / currency / last topic.
String buildSessionMemory({
  required List<({String role, String text})> history,
  String? accountName,
  String? currency,
}) {
  final buf = StringBuffer();
  if (accountName != null && accountName.trim().isNotEmpty) {
    buf.writeln('Default account: ${accountName.trim()}');
  }
  if (currency != null && currency.trim().isNotEmpty) {
    buf.writeln('Preferred currency: ${currency.trim()}');
  }
  final lastUser = history.reversed.where((h) => h.role == 'user').take(2);
  final lastModel = history.reversed.where((h) => h.role == 'model').take(1);
  if (lastUser.isNotEmpty) {
    buf.writeln(
      'Recent user asks: ${lastUser.map((h) => h.text).toList().reversed.join(' | ')}',
    );
  }
  if (lastModel.isNotEmpty) {
    buf.writeln('Last assistant note: ${lastModel.first.text}');
  }
  return buf.toString().trim();
}

String _clip(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max - 1)}…';
}
