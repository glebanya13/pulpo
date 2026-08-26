import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'providers.dart';
import 'settings_service.dart';

class BackupService {
  BackupService(this._db, this._settings);
  final AppDatabase _db;
  final SettingsService _settings;

  Future<Map<String, dynamic>> snapshot() async {
    final accounts = await _db.select(_db.accounts).get();
    final categories = await _db.select(_db.categories).get();
    final txs = await _db.select(_db.transactions).get();
    final budgets = await _db.select(_db.budgets).get();
    final goals = await _db.select(_db.goals).get();
    final debts = await _db.select(_db.debts).get();
    final settings = await _db.select(_db.settings).get();
    final recurring = await _db.select(_db.recurringRules).get();
    final subscriptions = await _db.select(_db.subscriptions).get();
    final tags = await _db.select(_db.tags).get();
    final transactionTags = await _db.select(_db.transactionTags).get();

    return {
      'version': 4,
      'exportedAt': DateTime.now().toIso8601String(),
      'appPrefs': _settings.exportAppPrefs(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'transactions': txs.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'debts': debts.map((e) => e.toJson()).toList(),
      'settings': settings.map((e) => e.toJson()).toList(),
      'recurringRules': recurring.map((e) => e.toJson()).toList(),
      'subscriptions': subscriptions.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'transactionTags': transactionTags.map((e) => e.toJson()).toList(),
    };
  }

  Future<bool> hasLocalMoneyData() async {
    final txs = await (_db.select(_db.transactions)..limit(1)).get();
    if (txs.isNotEmpty) return true;
    final accounts = await _db.select(_db.accounts).get();
    // More than a single default cash account ⇒ user has set something up.
    return accounts.length > 1;
  }

  Future<({int accounts, int transactions})> localCounts() async {
    final accounts = await _db.select(_db.accounts).get();
    final txs = await _db.select(_db.transactions).get();
    return (accounts: accounts.length, transactions: txs.length);
  }

  /// Remote becomes base; local transactions missing from remote are re-added
  /// onto matching accounts (by name+currency), creating accounts if needed.
  Future<int> mergeRemoteKeepingLocalOnly(Map<String, dynamic> remote) async {
    final local = await snapshot();
    final remoteTxs = (remote['transactions'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final remoteFingerprints = {
      for (final t in remoteTxs) _txFingerprint(t),
    };

    final localAccounts = (local['accounts'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final localById = {
      for (final a in localAccounts) a['id'] as int: a,
    };

    final localOnly = <({Map<String, dynamic> tx, Map<String, dynamic> account})>[];
    for (final raw in (local['transactions'] as List? ?? const [])) {
      final t = Map<String, dynamic>.from(raw as Map);
      if (remoteFingerprints.contains(_txFingerprint(t))) continue;
      final acc = localById[t['accountId'] as int?];
      if (acc == null) continue;
      localOnly.add((tx: t, account: acc));
    }

    await restoreFromMap(remote);

    if (localOnly.isEmpty) return 0;

    final accountIds = <String, int>{};
    for (final a in await _db.select(_db.accounts).get()) {
      final key =
          '${a.name.trim().toLowerCase()}|${a.currency.trim().toUpperCase()}';
      accountIds[key] = a.id;
    }

    var kept = 0;
    for (final item in localOnly) {
      final key =
          '${(item.account['name'] as String? ?? '').trim().toLowerCase()}|'
          '${(item.account['currency'] as String? ?? '').trim().toUpperCase()}';
      var accountId = accountIds[key];
      if (accountId == null) {
        accountId = await _db.into(_db.accounts).insert(
              AccountsCompanion.insert(
                name: item.account['name'] as String? ?? 'Account',
                type: (item.account['type'] as int?) ?? 0,
                currency: item.account['currency'] as String? ?? 'EUR',
                initialBalance: Value(
                  (item.account['initialBalance'] as num?)?.toDouble() ?? 0,
                ),
              ),
            );
        accountIds[key] = accountId;
      }

      final type = (item.tx['type'] as int?) ?? 0;
      if (type == TxType.transfer.index) continue;
      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amount: (item.tx['amount'] as num?)?.toDouble() ?? 0,
              currency: item.tx['currency'] as String? ?? 'EUR',
              type: type,
              date: DateTime.tryParse(item.tx['date']?.toString() ?? '') ??
                  DateTime.now(),
              categoryId: Value(item.tx['categoryId'] as int?),
              note: Value(item.tx['note'] as String?),
            ),
          );
      kept++;
    }
    return kept;
  }

  static String _txFingerprint(Map<String, dynamic> t) {
    final date = DateTime.tryParse(t['date']?.toString() ?? '');
    final day = date == null
        ? ''
        : '${date.year}-${date.month}-${date.day}';
    final amount = (t['amount'] as num?)?.toStringAsFixed(2) ?? '';
    final currency = (t['currency']?.toString() ?? '').toUpperCase();
    final type = '${t['type'] ?? ''}';
    final note = (t['note']?.toString() ?? '').trim().toLowerCase();
    return '$day|$amount|$currency|$type|$note';
  }

  Future<File> writeBackup() async {
    final data = await snapshot();
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/backup-$ts.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  Future<void> exportAndShare() async {
    final file = await writeBackup();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Monedero backup',
    );
  }

  Future<void> restoreFromFile(File file) async {
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    await restoreFromMap(json);
  }

  Future<void> restoreFromMap(Map<String, dynamic> json) async {
    Map<String, dynamic> asMap(dynamic j) =>
        Map<String, dynamic>.from(j as Map);

    // Normalize Firestore / JSON quirks before Drift fromJson.
    final normalized = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

    await _db.transaction(() async {
      await _db.delete(_db.transactionTags).go();
      await _db.delete(_db.tags).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.goals).go();
      await _db.delete(_db.debts).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.subscriptions).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.settings).go();

      for (final j in (normalized['categories'] as List? ?? [])) {
        await _db.into(_db.categories).insert(
              Category.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['accounts'] as List? ?? [])) {
        await _db.into(_db.accounts).insert(
              Account.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['transactions'] as List? ?? [])) {
        await _db.into(_db.transactions).insert(
              Transaction.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['tags'] as List? ?? [])) {
        await _db.into(_db.tags).insert(
              Tag.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['transactionTags'] as List? ?? [])) {
        await _db.into(_db.transactionTags).insert(
              TransactionTag.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['budgets'] as List? ?? [])) {
        await _db.into(_db.budgets).insert(
              Budget.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['goals'] as List? ?? [])) {
        await _db.into(_db.goals).insert(
              Goal.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['debts'] as List? ?? [])) {
        await _db.into(_db.debts).insert(
              Debt.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['settings'] as List? ?? [])) {
        await _db.into(_db.settings).insert(
              Setting.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['recurringRules'] as List? ?? [])) {
        await _db.into(_db.recurringRules).insert(
              RecurringRule.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final j in (normalized['subscriptions'] as List? ?? [])) {
        await _db.into(_db.subscriptions).insert(
              Subscription.fromJson(asMap(j)),
              mode: InsertMode.insertOrReplace,
            );
      }
    });

    final prefs = normalized['appPrefs'];
    if (prefs is Map) {
      try {
        await _settings.importAppPrefs(Map<String, dynamic>.from(prefs));
      } catch (e, st) {
        debugPrint('BackupService importAppPrefs: $e\n$st');
      }
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    ref.watch(settingsServiceProvider),
  );
});
