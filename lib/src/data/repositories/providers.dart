import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/enums.dart';

/// Синглтон-провайдер БД. Открывается один раз на всё приложение.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Список счетов (не архивных).
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.accounts)
        ..where((a) => a.isArchived.equals(false))
        ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
      .watch();
});

/// Все категории.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
        ..where((c) => c.isHidden.equals(false))
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .watch();
});

/// Все транзакции (по убыванию даты).
final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();
});

/// Недавние транзакции для дашборда (последние N).
final recentTransactionsProvider =
    StreamProvider.family<List<Transaction>, int>((ref, limit) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        ..limit(limit))
      .watch();
});

/// Транзакции за период (start inclusive, end exclusive).
final transactionsInRangeProvider = StreamProvider.family<List<Transaction>,
    ({DateTime start, DateTime end})>((ref, range) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..where((t) =>
            t.date.isBiggerOrEqualValue(range.start) &
            t.date.isSmallerThanValue(range.end))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();
});

/// Все бюджеты.
final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.budgets).watch();
});

/// Все цели.
final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.goals)
        ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
      .watch();
});

/// Все долги.
final debtsProvider = StreamProvider<List<Debt>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.debts).watch();
});

/// Хелпер: категория по id (map).
final categoryByIdProvider = Provider.family<Category?, int?>((ref, id) {
  if (id == null) return null;
  final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
  for (final c in cats) {
    if (c.id == id) return c;
  }
  return null;
});

final accountByIdProvider = Provider.family<Account?, int?>((ref, id) {
  if (id == null) return null;
  final accs = ref.watch(accountsProvider).valueOrNull ?? [];
  for (final a in accs) {
    if (a.id == id) return a;
  }
  return null;
});

/// Считает баланс счёта: initialBalance + приход − расход +/− переводы.
double computeAccountBalance(Account account, List<Transaction> txs) {
  var balance = account.initialBalance;
  for (final t in txs) {
    if (t.accountId != account.id) continue;
    final type = TxType.values[t.type];
    switch (type) {
      case TxType.income:
        balance += t.amount;
        break;
      case TxType.expense:
        balance -= t.amount;
        break;
      case TxType.transfer:
        // transfer хранится двумя транзакциями (out и in), связанными transferGroupId
        // out = expense-like на исходном счёте, in = income-like на целевом
        // Здесь просто следуем знаку амаунта (out < 0 хранится как отдельная запись)
        // Для простоты: transferGroupId != null и type == transfer — считаем как расход,
        // а на приёмном счёте будет вторая запись с типом income.
        balance -= t.amount;
        break;
    }
  }
  return balance;
}

/// Балансы всех счетов в мапе.
final accountBalancesProvider = Provider<Map<int, double>>((ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
  final txs = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  return {
    for (final a in accounts) a.id: computeAccountBalance(a, txs),
  };
});

/// Общий баланс (сумма по счетам с includeInTotal). Пока без конвертации валют.
final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
  final balances = ref.watch(accountBalancesProvider);
  var total = 0.0;
  for (final a in accounts) {
    if (!a.includeInTotal) continue;
    total += balances[a.id] ?? 0.0;
  }
  return total;
});
