/// DTOs for Firebase AI Logic (Gemini) structured JSON responses.
library;

class ReceiptLineItem {
  const ReceiptLineItem({
    this.amount,
    this.note,
    this.categoryHint,
  });

  final double? amount;
  final String? note;
  final String? categoryHint;
}

class ReceiptParseResult {
  const ReceiptParseResult({
    this.amount,
    this.currency,
    this.dateIso,
    this.merchant,
    this.note,
    this.categoryHint,
    this.type = 'expense',
    this.items = const [],
  });

  final double? amount;
  final String? currency;
  final String? dateIso;
  final String? merchant;
  final String? note;
  final String? categoryHint;
  final String type;
  /// Line items when the receipt lists multiple products.
  final List<ReceiptLineItem> items;

  DateTime? get date {
    final raw = dateIso;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool get hasLineItems =>
      items.where((i) => i.amount != null && i.amount! > 0).length >= 2;
}

class TransactionDraftFromAi {
  const TransactionDraftFromAi({
    this.amount,
    this.currency,
    this.dateIso,
    this.note,
    this.merchant,
    this.categoryHint,
    this.accountHint,
    this.toAccountHint,
    this.type = 'expense',
  });

  final double? amount;
  final String? currency;
  final String? dateIso;
  final String? note;
  final String? merchant;
  final String? categoryHint;
  /// Debit / source account name as spoken (matched to user accounts).
  final String? accountHint;
  /// Destination account for transfers (matched to user accounts).
  final String? toAccountHint;
  /// `expense` | `income` | `transfer`
  final String type;

  bool get isTransfer => type == 'transfer';

  DateTime? get date {
    final raw = dateIso;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  TransactionDraftFromAi copyWith({
    double? amount,
    String? currency,
    String? dateIso,
    String? note,
    String? merchant,
    String? categoryHint,
    String? accountHint,
    String? toAccountHint,
    String? type,
  }) {
    return TransactionDraftFromAi(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dateIso: dateIso ?? this.dateIso,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      categoryHint: categoryHint ?? this.categoryHint,
      accountHint: accountHint ?? this.accountHint,
      toAccountHint: toAccountHint ?? this.toAccountHint,
      type: type ?? this.type,
    );
  }
}

class CategorySuggestion {
  const CategorySuggestion({
    required this.categoryName,
    this.confidence,
  });

  final String categoryName;
  final double? confidence;
}

class PeriodInsight {
  const PeriodInsight({required this.text});

  final String text;
}

class PeriodInsightInput {
  const PeriodInsightInput({
    required this.periodLabel,
    required this.currency,
    required this.totalExpense,
    required this.totalIncome,
    required this.topCategories,
  });

  final String periodLabel;
  final String currency;
  final double totalExpense;
  final double totalIncome;
  final List<({String name, double amount})> topCategories;
}

class AssistantTurnResult {
  const AssistantTurnResult({
    required this.intent,
    required this.reply,
    this.transactions = const [],
    this.table,
  });

  /// `record` — save transactions; `clarify` — ask for missing fields;
  /// `question` — answer from app data only.
  final String intent;
  final String reply;
  final List<TransactionDraftFromAi> transactions;

  /// Optional structured table for spend/breakdown answers (preferred over
  /// markdown pipes inside [reply]).
  final AiChatTable? table;

  bool get isRecord => intent == 'record' && transactions.isNotEmpty;

  bool get isClarify =>
      intent == 'clarify' ||
      (intent == 'record' && transactions.isEmpty && reply.trim().isNotEmpty);
}

/// Structured table for assistant Q&A replies (Category | Date | Amount, …).
class AiChatTable {
  const AiChatTable({
    required this.headers,
    required this.rows,
    this.total,
  });

  final List<String> headers;
  final List<List<String>> rows;

  /// Optional total amount cell (shown as TOTAL pill).
  final String? total;
}
