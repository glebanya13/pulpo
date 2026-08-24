import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import '../../core/l10n/tr.dart';
import 'providers.dart';

class AccountRepository {
  AccountRepository(this._db);
  final AppDatabase _db;

  Future<int> add({
    required String name,
    required AccountType type,
    required String currency,
    double initialBalance = 0,
    String icon = 'wallet',
    int color = 0xFF0F0F0F,
    bool includeInTotal = true,
  }) {
    return _db.into(_db.accounts).insert(
          AccountsCompanion.insert(
            name: name,
            type: type.index,
            currency: currency,
            initialBalance: Value(initialBalance),
            icon: Value(icon),
            color: Value(color),
            includeInTotal: Value(includeInTotal),
          ),
        );
  }

  Future<void> archive(int id) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id)))
        .write(const AccountsCompanion(isArchived: Value(true)));
  }

  /// Deletes account plus all its transactions. Subscriptions/goals that
  /// reference this account are unlinked (set to null).
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.transactions)
            ..where((t) => t.accountId.equals(id)))
          .go();
      await (_db.update(_db.subscriptions)
            ..where((s) => s.accountId.equals(id)))
          .write(const SubscriptionsCompanion(accountId: Value(null)));
      await (_db.update(_db.goals)..where((g) => g.accountId.equals(id)))
          .write(const GoalsCompanion(accountId: Value(null)));
      await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
    });
  }

  Future<void> update({
    required int id,
    String? name,
    String? icon,
    int? color,
    bool? includeInTotal,
    double? creditLimit,
    bool clearCreditLimit = false,
  }) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        icon: icon == null ? const Value.absent() : Value(icon),
        color: color == null ? const Value.absent() : Value(color),
        includeInTotal: includeInTotal == null
            ? const Value.absent()
            : Value(includeInTotal),
        creditLimit: clearCreditLimit
            ? const Value(null)
            : (creditLimit == null
                ? const Value.absent()
                : Value(creditLimit)),
      ),
    );
  }

  /// Renames default onboarding cash accounts when the app language changes.
  Future<void> relocalizeDefaultCashAccount(String locale) async {
    final target = Tr.fromLang(locale).accountTypeCash;
    final known = {
      for (final lang in ['es', 'uk', 'ru', 'en']) Tr.fromLang(lang).accountTypeCash,
    };
    final rows = await (_db.select(_db.accounts)
          ..where(
            (a) =>
                a.type.equals(AccountType.cash.index) &
                a.isArchived.equals(false),
          ))
        .get();
    for (final a in rows) {
      if (known.contains(a.name) && a.name != target) {
        await update(id: a.id, name: target);
      }
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(databaseProvider));
});
