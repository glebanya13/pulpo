import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_database.dart';
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
