import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import 'providers.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required String name,
    required double amount,
    required String currency,
    String cycle = 'monthly',
    required DateTime nextPayment,
    int? accountId,
    int? categoryId,
    String? logoLetter,
    int? logoColor,
  }) {
    return _db.into(_db.subscriptions).insert(
          SubscriptionsCompanion.insert(
            name: name,
            amount: amount,
            currency: currency,
            cycle: Value(cycle),
            nextPayment: nextPayment,
            accountId: Value(accountId),
            categoryId: Value(categoryId),
            logoLetter: Value(logoLetter ??
                (name.isNotEmpty ? name[0].toUpperCase() : '·')),
            logoColor: Value(logoColor ?? _pickColor(name)),
          ),
        );
  }

  Future<void> update({
    required int id,
    String? name,
    double? amount,
    String? cycle,
    DateTime? nextPayment,
  }) async {
    await (_db.update(_db.subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        amount: amount == null ? const Value.absent() : Value(amount),
        cycle: cycle == null ? const Value.absent() : Value(cycle),
        nextPayment:
            nextPayment == null ? const Value.absent() : Value(nextPayment),
        logoLetter: name == null
            ? const Value.absent()
            : Value(name.isNotEmpty ? name[0].toUpperCase() : '·'),
      ),
    );
  }

  Future<void> togglePause(int id, bool paused) async {
    await (_db.update(_db.subscriptions)..where((s) => s.id.equals(id)))
        .write(SubscriptionsCompanion(isPaused: Value(paused)));
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.subscriptions)..where((s) => s.id.equals(id))).go();
  }

  int _pickColor(String name) {
    const palette = [
      0xFFE50914, // netflix red
      0xFF1DB954, // spotify green
      0xFFFF9500, // yandex orange
      0xFF4285F4, // google blue
      0xFF6441A5, // twitch purple
      0xFF5F27CD, // deep purple
      0xFF4ECDC4, // teal
      0xFFFFB84E, // amber
    ];
    return palette[name.hashCode.abs() % palette.length];
  }
}

final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.subscriptions)
        ..orderBy([(s) => OrderingTerm.asc(s.nextPayment)]))
      .watch();
});

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(databaseProvider));
});
