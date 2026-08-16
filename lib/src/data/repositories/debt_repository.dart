import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'providers.dart';

class DebtRepository {
  DebtRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required String counterparty,
    required double amount,
    required String currency,
    required DebtDirection direction,
    DateTime? dueDate,
    double? interestRate,
    String? note,
  }) {
    return _db.into(_db.debts).insert(
          DebtsCompanion.insert(
            counterparty: counterparty,
            amount: amount,
            currency: currency,
            direction: direction.index,
            dueDate: Value(dueDate),
            interestRate: Value(interestRate),
            note: Value(note),
          ),
        );
  }

  Future<void> addPayment(int id, double amount) async {
    final debt = await (_db.select(_db.debts)..where((d) => d.id.equals(id)))
        .getSingle();
    final newPaid = debt.paidAmount + amount;
    await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        paidAmount: Value(newPaid),
        status: Value(newPaid >= debt.amount ? 1 : 0),
      ),
    );
  }

  Future<void> update({
    required int id,
    String? counterparty,
    double? amount,
    DebtDirection? direction,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        counterparty: counterparty == null
            ? const Value.absent()
            : Value(counterparty),
        amount: amount == null ? const Value.absent() : Value(amount),
        direction:
            direction == null ? const Value.absent() : Value(direction.index),
        dueDate: clearDueDate
            ? const Value(null)
            : (dueDate == null ? const Value.absent() : Value(dueDate)),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.debts)..where((d) => d.id.equals(id))).go();
  }
}

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository(ref.watch(databaseProvider));
});
