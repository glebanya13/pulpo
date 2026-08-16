enum AccountType {
  cash,
  card,
  bankAccount,
  eWallet,
  crypto,
  investment,
  loan,
}

enum CategoryType {
  expense,
  income,
  both,
}

enum TxType {
  expense,
  income,
  transfer,
}

enum TxStatus {
  confirmed,
  planned,
  draft,
}

enum DebtDirection {
  iOwe,
  owedToMe,
}

enum BudgetPeriod {
  week,
  month,
  quarter,
  year,
  custom,
}

/// Локализованные названия типов счёта — берутся через `Tr.of(context).accountTypeLabel(t.index)`.
