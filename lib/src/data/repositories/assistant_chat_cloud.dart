import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../features/auth/cloud_auth.dart';

/// One assistant message in Firestore: users/{uid}/assistant_messages/{id}.
class CloudChatMessage {
  const CloudChatMessage({
    required this.id,
    required this.isFromUser,
    required this.body,
    required this.createdAt,
    this.imagePath,
  });

  final String id;
  final bool isFromUser;
  final String body;
  final String? imagePath;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'isFromUser': isFromUser,
        'body': body,
        if (imagePath != null) 'imagePath': imagePath,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static CloudChatMessage? fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;
    final created = data['createdAt'];
    final DateTime at;
    if (created is Timestamp) {
      at = created.toDate();
    } else if (created is DateTime) {
      at = created;
    } else {
      at = DateTime.now();
    }
    return CloudChatMessage(
      id: doc.id,
      isFromUser: data['isFromUser'] == true,
      body: (data['body'] as String?) ?? '',
      imagePath: data['imagePath'] as String?,
      createdAt: at,
    );
  }
}

class AssistantChatCloud {
  AssistantChatCloud();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const maxMessages = 200;

  bool get _ready =>
      AppInfo.firebaseConfigured && _auth.currentUser != null;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _col() {
    final uid = _uid;
    if (!_ready || uid == null) return null;
    return _db.collection('users').doc(uid).collection('assistant_messages');
  }

  Future<void> upsert({
    required String id,
    required bool isFromUser,
    required String body,
    required DateTime createdAt,
    String? imagePath,
  }) async {
    final col = _col();
    if (col == null) return;
    // Local image paths are device-specific — skip uploading them.
    await col.doc(id).set(
      CloudChatMessage(
        id: id,
        isFromUser: isFromUser,
        body: body,
        createdAt: createdAt,
        imagePath: null,
      ).toMap(),
      SetOptions(merge: true),
    );
    await _prune(col);
  }

  Future<List<CloudChatMessage>> fetchAll() async {
    final col = _col();
    if (col == null) return const [];
    final snap =
        await col.orderBy('createdAt').limit(maxMessages).get();
    return snap.docs
        .map(CloudChatMessage.fromDoc)
        .whereType<CloudChatMessage>()
        .toList();
  }

  Future<void> clear() async {
    final col = _col();
    if (col == null) return;
    final snap = await col.limit(500).get();
    if (snap.docs.isEmpty) return;
    var batch = _db.batch();
    var n = 0;
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }

  Future<void> deleteForUid(String uid) async {
    if (!AppInfo.firebaseConfigured) return;
    final col =
        _db.collection('users').doc(uid).collection('assistant_messages');
    final snap = await col.limit(500).get();
    if (snap.docs.isEmpty) return;
    var batch = _db.batch();
    var n = 0;
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }

  Future<void> _prune(CollectionReference<Map<String, dynamic>> col) async {
    final snap = await col
        .orderBy('createdAt', descending: true)
        .limit(maxMessages + 40)
        .get();
    if (snap.docs.length <= maxMessages) return;
    final extra = snap.docs.skip(maxMessages);
    var batch = _db.batch();
    var n = 0;
    for (final doc in extra) {
      batch.delete(doc.reference);
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }
}

final assistantChatCloudProvider = Provider<AssistantChatCloud>((ref) {
  ref.watch(authUserProvider);
  return AssistantChatCloud();
});
