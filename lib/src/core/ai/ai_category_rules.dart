import 'dart:convert';

import 'ai_models.dart';

/// User-taught merchant/note → category mappings (Budget IA-style).
class AiCategoryRule {
  const AiCategoryRule({
    required this.pattern,
    required this.categoryName,
  });

  final String pattern;
  final String categoryName;

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        'categoryName': categoryName,
      };

  static AiCategoryRule? fromJson(Map<String, dynamic> m) {
    final p = (m['pattern'] ?? m['p'] ?? '').toString().trim();
    final c = (m['categoryName'] ?? m['c'] ?? '').toString().trim();
    if (p.isEmpty || c.isEmpty) return null;
    return AiCategoryRule(pattern: p, categoryName: c);
  }
}

List<AiCategoryRule> decodeAiCategoryRules(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final out = <AiCategoryRule>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final rule = AiCategoryRule.fromJson(Map<String, dynamic>.from(item));
      if (rule != null) out.add(rule);
    }
    return out;
  } catch (_) {
    return const [];
  }
}

String encodeAiCategoryRules(List<AiCategoryRule> rules) {
  return jsonEncode([for (final r in rules) r.toJson()]);
}

/// Prompt block: model must obey these mappings.
String categoryRulesPromptBlock(List<AiCategoryRule> rules, {int limit = 40}) {
  if (rules.isEmpty) return '';
  final lines = rules
      .take(limit)
      .map((r) => '- "${r.pattern}" → ${r.categoryName}')
      .join('\n');
  return '''
USER CATEGORY RULES (must obey when note/merchant matches; set categoryHint exactly):
$lines
''';
}

String? _matchRuleCategory(String haystack, List<AiCategoryRule> rules) {
  final h = haystack.toLowerCase();
  if (h.isEmpty) return null;
  // Longest pattern first — "uber eats" before "uber".
  final sorted = [...rules]
    ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
  for (final r in sorted) {
    final p = r.pattern.toLowerCase().trim();
    if (p.isEmpty) continue;
    if (h.contains(p)) return r.categoryName;
  }
  return null;
}

/// Override [categoryHint] from stored rules (note/merchant).
List<TransactionDraftFromAi> applyAiCategoryRules(
  List<TransactionDraftFromAi> drafts,
  List<AiCategoryRule> rules,
) {
  if (rules.isEmpty || drafts.isEmpty) return drafts;
  return [
    for (final d in drafts)
      () {
        if (d.isTransfer) return d;
        final hay =
            '${d.note ?? ''} ${d.merchant ?? ''} ${d.categoryHint ?? ''}'
                .trim();
        final matched = _matchRuleCategory(hay, rules);
        if (matched == null) return d;
        if ((d.categoryHint ?? '').toLowerCase() == matched.toLowerCase()) {
          return d;
        }
        return d.copyWith(categoryHint: matched);
      }(),
  ];
}

/// Normalize a short learnable pattern from note/merchant text.
String? patternForCategoryLearn(String? note, String? merchant) {
  final raw = (note?.trim().isNotEmpty == true ? note!.trim() : merchant?.trim())
      ?? '';
  if (raw.isEmpty) return null;
  // Keep 1–3 tokens / up to 40 chars — avoid learning full utterances.
  final cleaned = raw
      .replaceAll(RegExp(r'[^\w\sÀ-ÿА-яЁёЇїІіЄєҐґ\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.length < 2) return null;
  final words = cleaned.split(' ');
  final short = words.take(3).join(' ');
  if (short.length > 40) return short.substring(0, 40).trim();
  return short;
}

/// Upsert a rule (same pattern, case-insensitive → update category).
List<AiCategoryRule> upsertAiCategoryRule(
  List<AiCategoryRule> existing, {
  required String pattern,
  required String categoryName,
  int maxRules = 80,
}) {
  final p = pattern.trim();
  final c = categoryName.trim();
  if (p.length < 2 || c.isEmpty) return existing;
  final lower = p.toLowerCase();
  final next = <AiCategoryRule>[
    for (final r in existing)
      if (r.pattern.toLowerCase() != lower) r,
    AiCategoryRule(pattern: p, categoryName: c),
  ];
  if (next.length <= maxRules) return next;
  return next.sublist(next.length - maxRules);
}
