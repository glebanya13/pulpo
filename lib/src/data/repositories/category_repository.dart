import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'providers.dart';

class CategoryRepository {
  CategoryRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required String name,
    required CategoryType type,
    String icon = 'circle',
    int color = 0xFFF2F2F2,
    int? parentId,
  }) {
    return _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            name: name,
            type: type.index,
            icon: Value(icon),
            color: Value(color),
            parentId: Value(parentId),
          ),
        );
  }

  Future<void> update({
    required int id,
    String? name,
    String? icon,
    int? color,
    CategoryType? type,
  }) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        icon: icon == null ? const Value.absent() : Value(icon),
        color: color == null ? const Value.absent() : Value(color),
        type: type == null ? const Value.absent() : Value(type.index),
      ),
    );
  }

  /// Deletes a category. Nulls out categoryId on transactions/subscriptions
  /// and unlinks child categories to avoid FK violations.
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.update(_db.transactions)
            ..where((t) => t.categoryId.equals(id)))
          .write(const TransactionsCompanion(categoryId: Value(null)));
      await (_db.update(_db.subscriptions)
            ..where((s) => s.categoryId.equals(id)))
          .write(const SubscriptionsCompanion(categoryId: Value(null)));
      await (_db.update(_db.categories)
            ..where((c) => c.parentId.equals(id)))
          .write(const CategoriesCompanion(parentId: Value(null)));
      await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    });
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});
