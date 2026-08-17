import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulpo/src/data/db/app_database.dart';
import 'package:pulpo/src/data/db/enums.dart';
import 'package:pulpo/src/data/repositories/backup_service.dart';
import 'package:pulpo/src/data/repositories/goal_repository.dart';
import 'package:pulpo/src/data/repositories/providers.dart';
import 'package:pulpo/src/data/repositories/scheduled_posting.dart';
import 'package:pulpo/src/data/repositories/settings_service.dart';
import 'package:pulpo/src/data/repositories/transaction_repository.dart';
import 'package:pulpo/src/features/export/export_service.dart';
import 'package:pulpo/src/features/security/lock_controller.dart';

void main() {
  test('hashLockPin is stable and distinguishes PINs', () {
    expect(hashLockPin('1234'), hashLockPin('1234'));
    expect(hashLockPin('1234'), isNot(hashLockPin('0000')));
  });

  test('LockController checkPin', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    final lock = container.read(lockControllerProvider.notifier);
    await lock.setPin('1234');
    expect(lock.checkPin('1234'), isTrue);
    expect(lock.checkPin('0000'), isFalse);
  });

  test('advanceSchedule monthly and weekly', () {
    final start = DateTime(2026, 1, 31);
    expect(advanceSchedule(start, 'monthly').month, 2);
    expect(advanceSchedule(start, 'monthly').day, 28);
    expect(advanceSchedule(DateTime(2026, 1, 5), 'weekly').day, 12);
  });

  test('computeAccountBalance income expense transfer', () {
    final now = DateTime(2026, 8, 1);
    final account = Account(
      id: 1,
      name: 'Card',
      type: AccountType.card.index,
      currency: 'EUR',
      initialBalance: 100,
      icon: 'card',
      color: 0,
      includeInTotal: true,
      isArchived: false,
      sortOrder: 0,
      createdAt: now,
    );
    Transaction tx({
      required int id,
      required double amount,
      required TxType type,
    }) {
      return Transaction(
        id: id,
        accountId: 1,
        amount: amount,
        currency: 'EUR',
        type: type.index,
        date: now,
        status: 0,
        createdAt: now,
        updatedAt: now,
      );
    }

    final txs = [
      tx(id: 1, amount: 50, type: TxType.income),
      tx(id: 2, amount: 20, type: TxType.expense),
      tx(id: 3, amount: 10, type: TxType.transfer),
      tx(id: 4, amount: -5, type: TxType.transfer),
    ];
    expect(computeAccountBalance(account, txs), 100 + 50 - 20 - 10 - (-5));
  });

  test('xlsx export is a real zip workbook', () {
    final now = DateTime(2026, 8, 1);
    final bytes = buildTransactionsXlsx([
      Transaction(
        id: 1,
        accountId: 1,
        amount: 12.5,
        currency: 'EUR',
        type: TxType.expense.index,
        date: now,
        note: 'Café',
        status: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4b);
    expect(bytes.length, greaterThan(200));
  });

  group('database', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('transfer updates both balances', () async {
      final fromId = await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'From',
              type: AccountType.card.index,
              currency: 'EUR',
              initialBalance: const Value(200),
            ),
          );
      final toId = await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'To',
              type: AccountType.cash.index,
              currency: 'EUR',
              initialBalance: const Value(10),
            ),
          );
      await TransactionRepository(db).addTransfer(
        fromAccountId: fromId,
        toAccountId: toId,
        fromAmount: 40,
        toAmount: 40,
        fromCurrency: 'EUR',
        toCurrency: 'EUR',
        date: DateTime(2026, 8, 1),
      );
      final accounts = await db.select(db.accounts).get();
      final txs = await db.select(db.transactions).get();
      final from = accounts.firstWhere((a) => a.id == fromId);
      final to = accounts.firstWhere((a) => a.id == toId);
      expect(computeAccountBalance(from, txs), 160);
      expect(computeAccountBalance(to, txs), 50);
    });

    test('backup restore round-trip', () async {
      await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'Cash',
              type: AccountType.cash.index,
              currency: 'EUR',
              initialBalance: const Value(12),
            ),
          );
      final backup = BackupService(db);
      final snap = await backup.snapshot();
      await db.delete(db.accounts).go();
      expect((await db.select(db.accounts).get()), isEmpty);
      await backup.restoreFromMap(snap);
      final restored = await db.select(db.accounts).get();
      expect(restored.single.name, 'Cash');
      expect(restored.single.initialBalance, 12);
    });

    test('recurring posts due transaction', () async {
      final accountId = await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'Card',
              type: AccountType.card.index,
              currency: 'EUR',
            ),
          );
      await db.into(db.recurringRules).insert(
            RecurringRulesCompanion.insert(
              templateJson:
                  '{"name":"Rent","accountId":$accountId,"amount":800,"currency":"EUR","type":${TxType.expense.index}}',
              frequency: 'monthly',
              nextRunAt: DateTime(2026, 7, 1),
            ),
          );
      final posted = await postDueScheduledItems(
        db,
        now: DateTime(2026, 8, 1),
      );
      expect(posted, greaterThanOrEqualTo(1));
      final txs = await db.select(db.transactions).get();
      expect(txs.any((t) => t.note == 'Rent' && t.amount == 800), isTrue);
    });

    test('goal progress posts expense', () async {
      final accountId = await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'Card',
              type: AccountType.card.index,
              currency: 'EUR',
              initialBalance: const Value(500),
            ),
          );
      final goalId = await GoalRepository(db).add(
        name: 'Trip',
        targetAmount: 1000,
        currency: 'EUR',
      );
      await GoalRepository(db).addProgress(
        id: goalId,
        amount: 80,
        accountId: accountId,
      );
      final goal = (await db.select(db.goals).get()).single;
      expect(goal.currentAmount, 80);
      final txs = await db.select(db.transactions).get();
      expect(txs.single.amount, 80);
      expect(txs.single.type, TxType.expense.index);
      expect(txs.single.note, 'Trip');
    });
  });
}
