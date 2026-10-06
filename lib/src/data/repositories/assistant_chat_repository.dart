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
  /// Skips a full wipe when local already matches remote (avoids open flicker).
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

    final local = await all();
    if (_sameConversation(local, remote)) return;

    // One transaction → one stream tick. A clear-then-loop-add used to
    // flash empty→full and jerk the chat on cold open after sync.
    await _db.transaction(() async {
      await _db.delete(_db.assistantMessages).go();
      for (final m in remote) {
        await _db.into(_db.assistantMessages).insert(
              AssistantMessagesCompanion.insert(
                isFromUser: m.isFromUser,
                body: m.body,
                imagePath: Value(m.imagePath),
                createdAt: m.createdAt,
              ),
            );
      }
    });
    await _prune();
  }

  /// Fast equality: same length + same last message fingerprint.
  bool _sameConversation(
    List<AssistantMessage> local,
    List<CloudChatMessage> remote,
  ) {
    if (local.length != remote.length) return false;
    if (local.isEmpty) return true;
    final a = local.last;
    final b = remote.last;
    return a.isFromUser == b.isFromUser &&
        a.body == b.body &&
        a.createdAt.millisecondsSinceEpoch ==
            b.createdAt.millisecondsSinceEpoch;
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

/// Local SQLite stream — kept alive so returning to chat is instant.
/// Cold start: emit a one-shot snapshot first so /assistant isn't empty→filled.
final assistantMessagesProvider =
    StreamProvider<List<AssistantMessage>>((ref) async* {
  ref.keepAlive();
  final repo = ref.watch(assistantChatRepositoryProvider);
  yield await repo.all();
  yield* repo.watchMessages();
});

/// Sync chat from Firestore once per signed-in session (never blocks UI).
final assistantChatSyncProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return;
  await ref.read(assistantChatRepositoryProvider).syncWithCloud();
});
