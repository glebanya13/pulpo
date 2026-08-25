import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../features/auth/cloud_auth.dart';

/// Cloud diagnostics for TestFlight / signed-in users.
///
/// Paths:
/// - `users/{uid}/error_logs/{id}` — per-user (owner can read in-app if needed)
/// - `client_error_logs/{id}` — flat table for Firebase Console / support
class ErrorLogCloud {
  ErrorLogCloud();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const maxRemote = 200;

  Future<void> upload({
    required String source,
    required String message,
    String? detail,
    DateTime? createdAt,
  }) async {
    if (!AppInfo.firebaseConfigured) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final at = createdAt ?? DateTime.now();
    final payload = <String, dynamic>{
      'uid': user.uid,
      if (user.email != null) 'email': user.email,
      if (user.displayName != null) 'displayName': user.displayName,
      'source': source,
      'message': message.length > 2000
          ? '${message.substring(0, 2000)}…'
          : message,
      if (detail != null && detail.isNotEmpty)
        'detail': detail.length > 4000
            ? '${detail.substring(0, 4000)}…'
            : detail,
      'createdAt': Timestamp.fromDate(at),
      'appVersion': AppInfo.version,
      'bundleId': !kIsWeb && Platform.isAndroid
          ? AppInfo.androidBundleId
          : AppInfo.bundleId,
      'platform': kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : Platform.isAndroid
                  ? 'android'
                  : Platform.operatingSystem,
      'buildMode': kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
    };

    final batch = _db.batch();
    final userRef =
        _db.collection('users').doc(user.uid).collection('error_logs').doc();
    final flatRef = _db.collection('client_error_logs').doc(userRef.id);
    batch.set(userRef, payload);
    batch.set(flatRef, payload);
    await batch.commit();

    // Best-effort prune of the flat table for this uid (keep last N).
    try {
      await _pruneUser(user.uid);
    } catch (_) {}
  }

  Future<void> clearForUid(String uid) async {
    if (!AppInfo.firebaseConfigured) return;
    final userCol =
        _db.collection('users').doc(uid).collection('error_logs');
    await _deleteQuery(userCol.limit(500));

    final flat = await _db
        .collection('client_error_logs')
        .where('uid', isEqualTo: uid)
        .limit(500)
        .get();
    if (flat.docs.isEmpty) return;
    var batch = _db.batch();
    var n = 0;
    for (final doc in flat.docs) {
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

  Future<void> _pruneUser(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('error_logs')
        .orderBy('createdAt', descending: true)
        .limit(maxRemote + 40)
        .get();
    if (snap.docs.length <= maxRemote) return;
    final extra = snap.docs.skip(maxRemote);
    var batch = _db.batch();
    var n = 0;
    for (final doc in extra) {
      batch.delete(doc.reference);
      final flat = _db.collection('client_error_logs').doc(doc.id);
      batch.delete(flat);
      n++;
      if (n >= 200) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
  }

  Future<void> _deleteQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    final snap = await query.get();
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
}

final errorLogCloudProvider = Provider<ErrorLogCloud>((ref) {
  ref.watch(authUserProvider);
  return ErrorLogCloud();
});
