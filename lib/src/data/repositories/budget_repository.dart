import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import 'providers.dart';

class BudgetRepository {
  BudgetRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required String name,
    required double amount,
    required String currency,
    int period = 1,
    List<int> categoryIds = const [],
    DateTime? startDate,
    int? color,
  }) {
    return _db.into(_db.budgets).insert(
          BudgetsCompanion.insert(
            name: name,
            amount: amount,
            currency: currency,
            period: period,
            categoryIdsJson: Value(jsonEncode(categoryIds)),
            startDate: startDate ?? DateTime.now(),
            color: color == null ? const Value.absent() : Value(color),
          ),
        );
  }

  Future<void> update({
    required int id,
    String? name,
    double? amount,
    int? period,
    List<int>? categoryIds,
  }) async {
    await (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        amount: amount == null ? const Value.absent() : Value(amount),
        period: period == null ? const Value.absent() : Value(period),
        categoryIdsJson: categoryIds == null
            ? const Value.absent()
            : Value(jsonEncode(categoryIds)),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});
