import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'providers.dart';

class GoalRepository {
  GoalRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required String name,
    required double targetAmount,
    required String currency,
    double currentAmount = 0,
    DateTime? targetDate,
    int? accountId,
    int color = 0xFFCDFF3A,
  }) {
    return _db.into(_db.goals).insert(
          GoalsCompanion.insert(
            name: name,
            targetAmount: targetAmount,
            currency: currency,
            currentAmount: Value(currentAmount),
            targetDate: Value(targetDate),
            accountId: Value(accountId),
            color: Value(color),
            isCompleted: Value(currentAmount >= targetAmount && targetAmount > 0),
          ),
        );
  }

  Future<void> update({
    required int id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
    int? accountId,
  }) async {
    final existing =
        await (_db.select(_db.goals)..where((g) => g.id.equals(id))).getSingle();
    final target = targetAmount ?? existing.targetAmount;
    final current = currentAmount ?? existing.currentAmount;
    await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        targetAmount:
            targetAmount == null ? const Value.absent() : Value(targetAmount),
        currentAmount:
            currentAmount == null ? const Value.absent() : Value(currentAmount),
        targetDate: clearTargetDate
            ? const Value(null)
            : (targetDate == null ? const Value.absent() : Value(targetDate)),
        isCompleted: Value(target > 0 && current >= target),
        accountId: accountId == null ? const Value.absent() : Value(accountId),
      ),
    );
  }

  /// Увеличивает накопление и списывает сумму со счёта как расход.
  Future<void> addProgress({
    required int id,
    required double amount,
    required int accountId,
  }) async {
    await _db.transaction(() async {
      final goal = await (_db.select(_db.goals)..where((g) => g.id.equals(id)))
          .getSingle();
      final next = goal.currentAmount + amount;
      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amount: amount,
              currency: goal.currency,
              type: TxType.expense.index,
              date: DateTime.now(),
              note: Value(goal.name),
            ),
          );
      await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
        GoalsCompanion(
          currentAmount: Value(next),
          isCompleted:
              Value(goal.targetAmount > 0 && next >= goal.targetAmount),
          accountId: Value(accountId),
        ),
      );
    });
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.goals)..where((g) => g.id.equals(id))).go();
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(databaseProvider));
});
