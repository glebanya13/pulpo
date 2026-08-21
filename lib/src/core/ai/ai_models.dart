/// DTOs for Firebase AI Logic (Gemini) structured JSON responses.
library;

class ReceiptParseResult {
  const ReceiptParseResult({
    this.amount,
    this.currency,
    this.dateIso,
    this.merchant,
    this.note,
    this.categoryHint,
    this.type = 'expense',
  });

  final double? amount;
  final String? currency;
  final String? dateIso;
  final String? merchant;
  final String? note;
  final String? categoryHint;
  final String type;

  DateTime? get date {
    final raw = dateIso;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class TransactionDraftFromAi {
  const TransactionDraftFromAi({
    this.amount,
    this.currency,
    this.dateIso,
    this.note,
    this.merchant,
    this.categoryHint,
    this.type = 'expense',
  });

  final double? amount;
  final String? currency;
  final String? dateIso;
  final String? note;
  final String? merchant;
  final String? categoryHint;
  final String type;

  DateTime? get date {
    final raw = dateIso;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
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
