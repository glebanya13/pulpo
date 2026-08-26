import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../firebase_options.dart';
import '../../core/app_info.dart';
import '../../data/repositories/assistant_chat_cloud.dart';
import '../../data/repositories/assistant_chat_repository.dart';
import '../../data/repositories/backup_service.dart';
import '../../data/repositories/error_log_cloud.dart';
import '../../data/repositories/settings_service.dart';
import '../shared_budget/household_service.dart';
import 'cloud_restore_prompt.dart';

class CloudNotConfigured implements Exception {
  const CloudNotConfigured();
}

class CloudSnapshotMeta {
  const CloudSnapshotMeta({
    required this.updatedAt,
    required this.accounts,
    required this.transactions,
    this.payload,
  });

  final DateTime? updatedAt;
  final int accounts;
  final int transactions;
  final Map<String, dynamic>? payload;
}

class CloudAuth {
  CloudAuth(this._ref);

  final Ref _ref;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool get isConfigured => AppInfo.firebaseConfigured;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authChanges() => _auth.userChanges();

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _moneyRef(String uid) =>
      _profileRef(uid).collection('money').doc('snapshot');

  Future<void> signInWithApple() async {
    String? appleName;
    final UserCredential cred;
    if (!kIsWeb && Platform.isIOS) {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      appleName = _joinName(apple.givenName, apple.familyName);
      final oauth = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      cred = await _auth.signInWithCredential(oauth);
    } else {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      cred = await _auth.signInWithProvider(provider);
    }
    await _afterSignIn(cred, providerName: appleName);
  }

  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: AppInfo.googleServerClientId,
      clientId: !kIsWeb && Platform.isIOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
    );
    final account = await google.signIn();
    if (account == null) {
      throw FirebaseAuthException(code: 'canceled');
    }
    final tokens = await account.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    final userCred = await _auth.signInWithCredential(cred);
    await _afterSignIn(
      userCred,
      providerName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    final trimmed = email.trim();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      await _afterSignIn(cred);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: trimmed,
          password: password,
        );
        await _afterSignIn(cred);
        return;
      }
      rethrow;
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _afterSignIn(cred);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn(
        serverClientId: AppInfo.googleServerClientId,
      ).signOut();
    } catch (_) {}
    try {
      await _ref
          .read(assistantChatRepositoryProvider)
          .clear(syncCloud: false);
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> deleteCloudAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final uid = user.uid;
    try {
      await _ref.read(householdServiceProvider).purgeUserSharedData();
    } catch (_) {}
    try {
      await _moneyRef(uid).delete();
    } catch (_) {}
    try {
      await AssistantChatCloud().deleteForUid(uid);
    } catch (_) {}
    try {
      await ErrorLogCloud().clearForUid(uid);
    } catch (_) {}
    try {
      await _profileRef(uid).delete();
    } catch (_) {}
    await user.delete();
    try {
      await GoogleSignIn(
        serverClientId: AppInfo.googleServerClientId,
      ).signOut();
    } catch (_) {}
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      if (user.displayName != trimmed) {
        await user.updateDisplayName(trimmed);
      }
      await _profileRef(user.uid).set({
        'displayName': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('CloudAuth.updateDisplayName: $e\n$st');
      rethrow;
    }
  }

  Future<void> uploadBackup([String? _]) async {
    await uploadMoney();
  }

  Future<String?> downloadBackup() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _moneyRef(user.uid).get(
      const GetOptions(source: Source.server),
    );
    final data = snap.data();
    if (data == null) return null;
    final payload = data['payload'];
    if (payload is Map<String, dynamic>) {
      return jsonEncode(payload);
    }
    if (payload is Map) {
      return jsonEncode(Map<String, dynamic>.from(payload));
    }
    return null;
  }

  Future<void> uploadMoney({bool bypassHold = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Not signed in',
      );
    }
    if (!bypassHold && _ref.read(cloudUploadHoldProvider)) {
      debugPrint('CloudAuth.uploadMoney: skipped (restore hold)');
      return;
    }
    final snapshot = await _ref.read(backupServiceProvider).snapshot();
    final payload = jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
    await _moneyRef(user.uid).set({
      'updatedAt': FieldValue.serverTimestamp(),
      'payload': payload,
    });
  }

  Future<bool> downloadMoney() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final payload = await _readMoneyPayload();
    if (payload == null) return false;
    final txCount = (payload['transactions'] as List?)?.length ?? 0;
    final accCount = (payload['accounts'] as List?)?.length ?? 0;
    debugPrint(
      'CloudAuth.downloadMoney: restoring accounts=$accCount txs=$txCount',
    );
    await _ref.read(backupServiceProvider).restoreFromMap(payload);
    return true;
  }

  Future<CloudSnapshotMeta?> peekCloudSnapshotMeta() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _moneyRef(user.uid).get(
        const GetOptions(source: Source.server),
      );
    } catch (_) {
      snap = await _moneyRef(user.uid).get();
    }
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    DateTime? updated;
    final rawUpdated = data['updatedAt'];
    if (rawUpdated is Timestamp) updated = rawUpdated.toDate();
    final raw = data['payload'];
    if (raw is! Map) {
      return CloudSnapshotMeta(
        updatedAt: updated,
        accounts: 0,
        transactions: 0,
      );
    }
    final payload = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
    if (updated == null) {
      updated = DateTime.tryParse(payload['exportedAt']?.toString() ?? '');
    }
    return CloudSnapshotMeta(
      updatedAt: updated,
      accounts: (payload['accounts'] as List?)?.length ?? 0,
      transactions: (payload['transactions'] as List?)?.length ?? 0,
      payload: payload,
    );
  }

  /// Restore remote, keep local-only txs, then upload the union.
  Future<int> mergeMoney() async {
    final meta = await peekCloudSnapshotMeta();
    final payload = meta?.payload;
    if (payload == null) return -1;
    final kept = await _ref
        .read(backupServiceProvider)
        .mergeRemoteKeepingLocalOnly(payload);
    await uploadMoney(bypassHold: true);
    return kept;
  }

  Future<Map<String, dynamic>?> _readMoneyPayload() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _moneyRef(user.uid).get(
        const GetOptions(source: Source.server),
      );
    } catch (e, st) {
      debugPrint('CloudAuth._readMoneyPayload server read failed: $e\n$st');
      snap = await _moneyRef(user.uid).get();
    }
    final data = snap.data();
    if (data == null) return null;
    final raw = data['payload'];
    if (raw is! Map) return null;
    return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  }

  Future<DateTime?> cloudSnapshotUpdatedAt() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _moneyRef(user.uid).get(
      const GetOptions(source: Source.server),
    );
    if (!snap.exists) return null;
    final updated = snap.data()?['updatedAt'];
    if (updated is Timestamp) return updated.toDate();
    return null;
  }

  Future<bool> hasCloudSnapshot() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      return (await _moneyRef(user.uid).get(
            const GetOptions(source: Source.server),
          ))
          .exists;
    } catch (_) {
      return (await _moneyRef(user.uid).get()).exists;
    }
  }

  Future<void> syncOnLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    DocumentSnapshot<Map<String, dynamic>> remote;
    try {
      remote = await _moneyRef(user.uid).get(
        const GetOptions(source: Source.server),
      );
    } catch (e, st) {
      debugPrint('CloudAuth.syncOnLogin server read failed: $e\n$st');
      remote = await _moneyRef(user.uid).get();
    }
    if (!remote.exists) {
      await uploadMoney();
    } else {
      // Hold uploads until the user picks cloud vs local (see CloudLoginSyncBinder).
      _ref.read(cloudUploadHoldProvider.notifier).state = true;
      _ref.read(pendingCloudRestoreProvider.notifier).state = true;
    }
    try {
      await _ref.read(assistantChatRepositoryProvider).syncWithCloud();
    } catch (_) {}
  }

  Future<void> _afterSignIn(
    UserCredential cred, {
    String? providerName,
    String? photoUrl,
  }) async {
    final user = cred.user;
    if (user == null) return;

    final settings = _ref.read(settingsControllerProvider);
    final local = settings.userName.trim();
    final placeholder = local.isEmpty || local.toLowerCase() == 'user';
    final isNew = cred.additionalUserInfo?.isNewUser ?? false;

    final fromAppleOrGoogle = providerName?.trim();
    final fromFirebase = user.displayName?.trim();
    final fromEmail = user.email?.split('@').first.trim();

    String? chosen;
    if (isNew || placeholder) {
      chosen = _firstNonEmpty(
        [fromAppleOrGoogle, fromFirebase, fromEmail, if (!placeholder) local],
      );
    } else {
      chosen = local;
    }

    final picture = _hiResPhoto(
      photoUrl ??
          cred.additionalUserInfo?.profile?['picture'] as String? ??
          user.photoURL,
    );

    if (chosen != null) {
      await _ref.read(settingsControllerProvider.notifier).setUserName(chosen);
      if (user.displayName != chosen) {
        await user.updateDisplayName(chosen);
      }
    } else {
      final existing = await _profileRef(user.uid).get();
      final remoteName = existing.data()?['displayName'] as String?;
      if (remoteName != null && remoteName.trim().isNotEmpty) {
        await _ref
            .read(settingsControllerProvider.notifier)
            .setUserName(remoteName.trim());
      }
    }

    if (picture != null && user.photoURL != picture) {
      await user.updatePhotoURL(picture);
    }

    await _profileRef(user.uid).set({
      if (chosen != null) 'displayName': chosen,
      if (picture != null) 'photoUrl': picture,
      if (user.email != null) 'email': user.email,
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.reload();
    await syncOnLogin();
  }

  static String? _hiResPhoto(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    var u = url.trim();
    // Googleusercontent: force square crop + higher res for avatars.
    if (u.contains('googleusercontent.com')) {
      u = u
          .replaceAll(RegExp(r'=s\d+-c?\b'), '=s256-c')
          .replaceAll(RegExp(r'/s\d+-c?/'), '/s256-c/');
      if (!RegExp(r'[=/]s\d').hasMatch(u)) {
        u = u.contains('?') ? '$u&sz=256' : '$u=s256-c';
      }
    }
    return u;
  }

  static String? _joinName(String? given, String? family) {
    final parts = [
      given?.trim(),
      family?.trim(),
    ].where((e) => e != null && e.isNotEmpty).cast<String>();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}

final cloudAuthProvider = Provider<CloudAuth>((ref) => CloudAuth(ref));

final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(cloudAuthProvider).authChanges();
});
