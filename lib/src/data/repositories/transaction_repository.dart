import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'providers.dart';

class TransactionRepository {
  TransactionRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required int accountId,
    int? categoryId,
    required double amount,
    required String currency,
    required TxType type,
    required DateTime date,
    String? note,
    String? counterparty,
    String? receiptPath,
  }) {
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: accountId,
            categoryId: Value(categoryId),
            amount: amount,
            currency: currency,
            type: type.index,
            date: date,
            note: Value(note),
            counterparty: Value(counterparty),
            receiptPath: Value(receiptPath),
          ),
        );
  }

  Future<int> addTransfer({
    required int fromAccountId,
    required int toAccountId,
    required double fromAmount,
    required double toAmount,
    required String fromCurrency,
    required String toCurrency,
    required DateTime date,
    String? note,
  }) async {
    // groupId := timestamp micros для простоты уникальности
    final groupId = DateTime.now().microsecondsSinceEpoch % 2147483647;

    await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: fromAccountId,
            amount: fromAmount,
            currency: fromCurrency,
            type: TxType.transfer.index,
            date: date,
            note: Value(note),
            transferGroupId: Value(groupId),
          ),
        );
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: toAccountId,
            amount: -toAmount, // отрицательный, чтобы вычесть при подсчёте баланса и получить +toAmount
            currency: toCurrency,
            type: TxType.transfer.index,
            date: date,
            note: Value(note),
            transferGroupId: Value(groupId),
          ),
        );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> update({
    required int id,
    double? amount,
    int? categoryId,
    int? accountId,
    DateTime? date,
    String? note,
    Value<String?> receiptPath = const Value.absent(),
  }) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amount: amount == null ? const Value.absent() : Value(amount),
        categoryId:
            categoryId == null ? const Value.absent() : Value(categoryId),
        accountId: accountId == null ? const Value.absent() : Value(accountId),
        date: date == null ? const Value.absent() : Value(date),
        note: note == null ? const Value.absent() : Value(note),
        receiptPath: receiptPath,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});
