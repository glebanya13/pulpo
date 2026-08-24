import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../../core/theme/color_well.dart' show pastelColorRemap;
import '../seed/seed_categories.dart' show legacyRuNameToSlug, normalizeCategorySortOrder;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Tags,
    TransactionTags,
    Budgets,
    Goals,
    Debts,
    RecurringRules,
    ExchangeRates,
    Settings,
    Subscriptions,
    AssistantMessages,
    ErrorLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  /// Wipes every user-facing table. Keeps schema and settings intact.
  Future<void> resetAllData() async {
    await transaction(() async {
      await delete(transactionTags).go();
      await delete(transactions).go();
      await delete(recurringRules).go();
      await delete(subscriptions).go();
      await delete(debts).go();
      await delete(budgets).go();
      await delete(goals).go();
      await delete(tags).go();
      await delete(exchangeRates).go();
      await delete(categories).go();
      await delete(accounts).go();
      await delete(assistantMessages).go();
    });
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(subscriptions);
          }
          if (from < 3) {
            // Переводим RU-имена системных категорий на slug-формат.
            for (final entry in legacyRuNameToSlug.entries) {
              await customStatement(
                'UPDATE categories SET name = ? WHERE name = ?',
                [entry.value, entry.key],
              );
            }
          }
          if (from < 4) {
            // v3→v4: remap pastel colors
            for (final entry in pastelColorRemap.entries) {
              await (update(categories)
                    ..where((c) => c.color.equals(entry.key)))
                  .write(CategoriesCompanion(color: Value(entry.value)));
              await (update(accounts)
                    ..where((a) => a.color.equals(entry.key)))
                  .write(AccountsCompanion(color: Value(entry.value)));
              await (update(budgets)
                    ..where((b) => b.color.equals(entry.key)))
                  .write(BudgetsCompanion(color: Value(entry.value)));
            }
          }
          if (from < 5) {
            await customStatement(
              'ALTER TABLE transactions ADD COLUMN receipt_path TEXT',
            );
          }
          if (from < 6) {
            await normalizeCategorySortOrder(this);
          }
          if (from < 7) {
            await m.createTable(assistantMessages);
            await m.createTable(errorLogs);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pulpo.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
