import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import 'providers.dart';

class TagRepository {
  TagRepository(this._db);
  final AppDatabase _db;

  Stream<List<Tag>> watchAll() {
    return (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Tag>> forTransaction(int transactionId) async {
    final links = await (_db.select(_db.transactionTags)
          ..where((tt) => tt.transactionId.equals(transactionId)))
        .get();
    if (links.isEmpty) return const [];
    final ids = links.map((l) => l.tagId).toSet();
    return (_db.select(_db.tags)..where((t) => t.id.isIn(ids.toList()))).get();
  }

  Future<int> upsertByName(String raw) async {
    final name = raw.trim();
    if (name.isEmpty) throw ArgumentError('empty tag');
    final existing = await (_db.select(_db.tags)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.tags).insert(TagsCompanion.insert(name: name));
  }

  Future<void> setTagsForTransaction(int transactionId, List<int> tagIds) async {
    await _db.transaction(() async {
      await (_db.delete(_db.transactionTags)
            ..where((tt) => tt.transactionId.equals(transactionId)))
          .go();
      for (final id in tagIds.toSet()) {
        await _db.into(_db.transactionTags).insert(
              TransactionTagsCompanion.insert(
                transactionId: transactionId,
                tagId: id,
              ),
            );
      }
    });
  }

  Future<List<int>> parseAndUpsert(String raw) async {
    final parts = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final ids = <int>[];
    for (final p in parts) {
      ids.add(await upsertByName(p));
    }
    return ids;
  }
}

final tagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tagRepositoryProvider).watchAll();
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.watch(databaseProvider));
});
