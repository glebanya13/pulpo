import 'package:pulpo/src/core/ai/ai_local_parse.dart';
import 'package:pulpo/src/core/ai/ai_models.dart';
import 'package:pulpo/src/core/ai/ai_record_hint.dart';

/// Golden NL cases for post-process / retype — keep these green in CI.
/// Production parse is Gemini-only; local parse here only validates helpers.
class AiEvalCase {
  const AiEvalCase({
    required this.id,
    required this.input,
    required this.expectRecord,
    this.expectTypes = const [],
    this.expectAmounts = const [],
    this.currencyHint = 'EUR',
  });

  final String id;
  final String input;
  final bool expectRecord;
  final List<String> expectTypes;
  final List<double> expectAmounts;
  final String currencyHint;
}

const aiEvalCases = <AiEvalCase>[
  AiEvalCase(
    id: 'simple_coffee',
    input: 'кофе 3 евро',
    expectRecord: true,
    expectTypes: ['expense'],
    expectAmounts: [3],
  ),
  AiEvalCase(
    id: 'salary_only',
    input: 'зарплата 2000 евро',
    expectRecord: true,
    expectTypes: ['income'],
    expectAmounts: [2000],
  ),
  AiEvalCase(
    id: 'mixed_spend_then_salary',
    input:
        'потратил 10 евро на хлеб, 20 евро на такси, 5 евро на другое '
        'и также мне пришла зарплата в размере 3000 евро',
    expectRecord: true,
    expectTypes: ['expense', 'expense', 'expense', 'income'],
    expectAmounts: [10, 20, 5, 3000],
  ),
  AiEvalCase(
    id: 'balance_question_not_record',
    input: 'сколько у меня денег?',
    expectRecord: false,
  ),
  AiEvalCase(
    id: 'spend_question_not_record',
    input: 'сколько я потратил на еду?',
    expectRecord: false,
  ),
  AiEvalCase(
    id: 'avance_income',
    input: 'аванс 800 евро',
    expectRecord: true,
    expectTypes: ['income'],
    expectAmounts: [800],
  ),
  AiEvalCase(
    id: 'sueldo_es',
    input: 'sueldo 1500 euros',
    expectRecord: true,
    expectTypes: ['income'],
    expectAmounts: [1500],
  ),
  AiEvalCase(
    id: 'cashback_income',
    input: 'кешбек 12 евро',
    expectRecord: true,
    expectTypes: ['income'],
    expectAmounts: [12],
  ),
  AiEvalCase(
    id: 'taxi_list',
    input: 'taxi 8€ and bread 12€',
    expectRecord: true,
    expectTypes: ['expense', 'expense'],
    expectAmounts: [8, 12],
  ),
];

/// Resolve expected drafts via local parse + retype (no network).
List<TransactionDraftFromAi>? evalLocalDrafts(AiEvalCase c) {
  final local = tryParseLocalTransactions(
    c.input,
    currencyHint: c.currencyHint,
  );
  if (local == null || local.isEmpty) {
    // Chatty multi → simulate Gemini mislabel, then retype from source.
    if (c.expectTypes.contains('income') && c.expectAmounts.length >= 2) {
      final fake = [
        for (var i = 0; i < c.expectAmounts.length; i++)
          TransactionDraftFromAi(
            amount: c.expectAmounts[i],
            currency: c.currencyHint,
            note: 'item$i',
            type: 'expense',
          ),
      ];
      return retypeDraftsFromSource(fake, c.input);
    }
    return null;
  }
  return retypeDraftsFromSource(local, c.input);
}

bool evalLooksLikeRecord(AiEvalCase c) => looksLikeTransactionRecord(c.input);
