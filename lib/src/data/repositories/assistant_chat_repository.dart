import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../features/auth/cloud_auth.dart';
import '../db/app_database.dart';
import 'assistant_chat_cloud.dart';
import 'providers.dart';

class AssistantChatRepository {
  AssistantChatRepository(this._db, this._cloud, this._ref);

  final AppDatabase _db;
  final AssistantChatCloud _cloud;
  final Ref _ref;
  static const _maxMessages = 200;

  Stream<List<AssistantMessage>> watchMessages() {
    return (_db.select(_db.assistantMessages)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  Future<List<AssistantMessage>> all() {
    return (_db.select(_db.assistantMessages)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<int> count() async {
    final c = _db.assistantMessages.id.count();
    final q = _db.selectOnly(_db.assistantMessages)..addColumns([c]);
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  Future<void> add({
    required bool isFromUser,
    required String body,
    String? imagePath,
    DateTime? createdAt,
    String? cloudId,
    bool syncCloud = true,
  }) async {
    final at = createdAt ?? DateTime.now();
    final id = await _db.into(_db.assistantMessages).insert(
          AssistantMessagesCompanion.insert(
            isFromUser: isFromUser,
            body: body,
            imagePath: Value(imagePath),
            createdAt: at,
          ),
        );
    await _prune();
    if (!syncCloud) return;
    final uid = _ref.read(authUserProvider).valueOrNull?.uid;
    if (uid == null || !AppInfo.firebaseConfigured) return;
    try {
      await _cloud.upsert(
        id: cloudId ?? 'local_$id',
        isFromUser: isFromUser,
        body: body,
        createdAt: at,
        imagePath: imagePath,
      );
    } catch (_) {
      // Offline / rules — local copy remains.
    }
  }

  Future<void> ensureWelcome(String welcomeText) async {
    final n = await count();
    if (n > 0) return;
    await add(isFromUser: false, body: welcomeText);
  }

  Future<void> clear({bool syncCloud = true}) async {
    await _db.delete(_db.assistantMessages).go();
    if (!syncCloud) return;
    try {
      await _cloud.clear();
    } catch (_) {}
  }

  /// Pull signed-in user's Firestore history into local SQLite.
  /// Prefer cloud when it has messages; otherwise upload local.
  Future<void> syncWithCloud() async {
    if (!AppInfo.firebaseConfigured) return;
    final uid = _ref.read(authUserProvider).valueOrNull?.uid;
    if (uid == null) return;

    List<CloudChatMessage> remote;
    try {
      remote = await _cloud.fetchAll();
    } catch (_) {
      return;
    }

    if (remote.isEmpty) {
      final local = await all();
      for (final m in local) {
        try {
          await _cloud.upsert(
            id: 'local_${m.id}',
            isFromUser: m.isFromUser,
            body: m.body,
            createdAt: m.createdAt,
          );
        } catch (_) {
          break;
        }
      }
      return;
    }

    await clear(syncCloud: false);
    for (final m in remote) {
      await add(
        isFromUser: m.isFromUser,
        body: m.body,
        imagePath: m.imagePath,
        createdAt: m.createdAt,
        cloudId: m.id,
        syncCloud: false,
      );
    }
  }

  Future<void> _prune() async {
    final rows = await (_db.select(_db.assistantMessages)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(_maxMessages + 40))
        .get();
    if (rows.length <= _maxMessages) return;
    final cutoff = rows[_maxMessages - 1].id;
    await (_db.delete(_db.assistantMessages)
          ..where((t) => t.id.isSmallerThanValue(cutoff)))
        .go();
  }
}

final assistantChatRepositoryProvider =
    Provider<AssistantChatRepository>((ref) {
  return AssistantChatRepository(
    ref.watch(databaseProvider),
    ref.watch(assistantChatCloudProvider),
    ref,
  );
});

final assistantMessagesProvider =
    StreamProvider<List<AssistantMessage>>((ref) {
  return ref.watch(assistantChatRepositoryProvider).watchMessages();
});

/// Sync chat from Firestore once per signed-in session.
final assistantChatSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return;
  await ref.read(assistantChatRepositoryProvider).syncWithCloud();
});
