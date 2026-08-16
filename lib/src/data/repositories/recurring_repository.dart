import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'providers.dart';

class RecurringRepository {
  RecurringRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required String name,
    required int accountId,
    int? categoryId,
    required double amount,
    required String currency,
    required TxType type,
    required String frequency, // daily|weekly|monthly|yearly
    required DateTime nextRun,
    int interval = 1,
    DateTime? endAt,
  }) {
    final template = jsonEncode({
      'name': name,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'currency': currency,
      'type': type.index,
    });
    return _db.into(_db.recurringRules).insert(
          RecurringRulesCompanion.insert(
            templateJson: template,
            frequency: frequency,
            interval: Value(interval),
            nextRunAt: nextRun,
            endAt: Value(endAt),
          ),
        );
  }

  Future<void> update({
    required int id,
    required String name,
    required int accountId,
    int? categoryId,
    required double amount,
    required String currency,
    required TxType type,
    required String frequency,
    required DateTime nextRun,
  }) async {
    final template = jsonEncode({
      'name': name,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'currency': currency,
      'type': type.index,
    });
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        templateJson: Value(template),
        frequency: Value(frequency),
        nextRunAt: Value(nextRun),
      ),
    );
  }

  Future<void> togglePause(int id, bool paused) async {
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id)))
        .write(RecurringRulesCompanion(isPaused: Value(paused)));
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.recurringRules)..where((r) => r.id.equals(id))).go();
  }
}

final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.recurringRules)
        ..orderBy([(r) => OrderingTerm.asc(r.nextRunAt)]))
      .watch();
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(databaseProvider));
});

/// Хелпер — распарсенный шаблон для UI.
class RecurringTemplate {
  RecurringTemplate({
    required this.name,
    required this.accountId,
    this.categoryId,
    required this.amount,
    required this.currency,
    required this.type,
  });

  factory RecurringTemplate.fromJson(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return RecurringTemplate(
      name: m['name'] as String? ?? '',
      accountId: m['accountId'] as int? ?? 0,
      categoryId: m['categoryId'] as int?,
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      currency: m['currency'] as String? ?? 'USD',
      type: TxType.values[(m['type'] as int?) ?? 0],
    );
  }

  final String name;
  final int accountId;
  final int? categoryId;
  final double amount;
  final String currency;
  final TxType type;
}
