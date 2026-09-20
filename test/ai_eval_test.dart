import 'package:flutter_test/flutter_test.dart';

import 'ai_eval_fixtures.dart';

void main() {
  group('AI eval fixtures', () {
    for (final c in aiEvalCases) {
      test(c.id, () {
        expect(
          evalLooksLikeRecord(c),
          c.expectRecord,
          reason: 'looksLikeTransactionRecord for "${c.input}"',
        );
        if (!c.expectRecord) return;

        final drafts = evalLocalDrafts(c);
        expect(drafts, isNotNull, reason: 'no drafts for ${c.id}');
        expect(drafts!.length, c.expectAmounts.length);
        for (var i = 0; i < drafts.length; i++) {
          expect(drafts[i].amount, c.expectAmounts[i]);
          expect(drafts[i].type, c.expectTypes[i]);
        }
      });
    }
  });
}
