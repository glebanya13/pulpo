import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Fresh credential required by Apple/Firebase before [User.delete].
  Future<void> reauthenticate({String? emailPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    final providers = user.providerData.map((p) => p.providerId).toSet();

    if (providers.contains('apple.com')) {
      await _reauthApple(user);
      return;
    }
    if (providers.contains('google.com')) {
      await _reauthGoogle(user);
      return;
    }
    if (providers.contains('password')) {
      final email = user.email?.trim();
      final password = emailPassword?.trim();
      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        throw FirebaseAuthException(code: 'password-required');
      }
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(cred);
      return;
    }

    throw FirebaseAuthException(code: 'no-reauth-provider');
  }

  Future<void> _reauthApple(User user) async {
    if (!kIsWeb && Platform.isIOS) {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      await user.reauthenticateWithCredential(oauth);
      return;
    }
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    await user.reauthenticateWithProvider(provider);
  }

  Future<void> _reauthGoogle(User user) async {
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
    await user.reauthenticateWithCredential(cred);
  }

  /// Primary sign-in provider for UI (apple / google / password).
  String? primaryAuthProviderId() {
    final user = _auth.currentUser;
    if (user == null) return null;
    final ids = user.providerData.map((p) => p.providerId).toSet();
    if (ids.contains('apple.com')) return 'apple.com';
    if (ids.contains('google.com')) return 'google.com';
    if (ids.contains('password')) return 'password';
    return ids.isEmpty ? null : ids.first;
  }

  Future<void> deleteCloudAccount({String? emailPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    // Always reauth first — Apple/Firebase reject stale sessions on delete.
    await reauthenticate(emailPassword: emailPassword);
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
    final backup = _ref.read(backupServiceProvider);
    if (await backup.looksLikeDemoData()) {
      debugPrint('CloudAuth.uploadMoney: skipped (demo data)');
      return;
    }
    // After scrubbing demo we briefly have a single empty cash account —
    // never push that over a real cloud snapshot.
    if (!await backup.hasLocalMoneyData()) {
      debugPrint('CloudAuth.uploadMoney: skipped (no real local money)');
      return;
    }
    final snapshot = await backup.snapshot();
    final payload = jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
    await _moneyRef(user.uid).set({
      'updatedAt': FieldValue.serverTimestamp(),
      'payload': payload,
      'accountCount': (payload['accounts'] as List?)?.length ?? 0,
      'transactionCount': (payload['transactions'] as List?)?.length ?? 0,
    });
  }

  Future<bool> downloadMoney() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final payload = await _readMoneyPayload();
    if (payload == null) return false;
    return _restoreMoneyPayload(user.uid, payload);
  }

  /// Restore an already-fetched payload (avoids a second Firestore round-trip).
  Future<bool> _restoreMoneyPayload(
    String uid,
    Map<String, dynamic> payload,
  ) async {
    if (BackupService.payloadLooksLikeDemo(payload)) {
      debugPrint('CloudAuth._restoreMoneyPayload: remote is demo — discarding');
      try {
        await _moneyRef(uid).delete();
      } catch (_) {}
      return false;
    }
    final txCount = (payload['transactions'] as List?)?.length ?? 0;
    final accCount = (payload['accounts'] as List?)?.length ?? 0;
    debugPrint(
      'CloudAuth._restoreMoneyPayload: restoring accounts=$accCount txs=$txCount',
    );
    await _ref.read(backupServiceProvider).restoreFromMap(payload);
    await _ref.read(settingsServiceProvider).setDemoData(false);
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

  /// If the signed-in device still has sample data (e.g. demo was restored
  /// before this fix), wipe it and prefer a real cloud snapshot.
  Future<void> scrubDemoIfSignedIn() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final backup = _ref.read(backupServiceProvider);
    if (!await backup.looksLikeDemoData()) return;
    debugPrint('CloudAuth.scrubDemoIfSignedIn: clearing leftover demo');
    await backup.clearDemoData();
    final meta = await peekCloudSnapshotMeta();
    final payload = meta?.payload;
    if (payload != null && !BackupService.payloadLooksLikeDemo(payload)) {
      await _restoreMoneyPayload(user.uid, payload);
    } else if (payload != null && BackupService.payloadLooksLikeDemo(payload)) {
      try {
        await _moneyRef(user.uid).delete();
      } catch (_) {}
    }
    refreshUiAfterMoneyRestoreRef(_ref);
  }

  Future<void> syncOnLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final backup = _ref.read(backupServiceProvider);

    // Sample / review data must never become the signed-in user's cloud data.
    final localWasDemo = await backup.looksLikeDemoData();
    if (localWasDemo) {
      debugPrint('CloudAuth.syncOnLogin: clearing local demo before sync');
      await backup.clearDemoData();
    }

    DocumentSnapshot<Map<String, dynamic>> remote;
    try {
      remote = await _moneyRef(user.uid).get(
        const GetOptions(source: Source.server),
      );
    } catch (e, st) {
      debugPrint('CloudAuth.syncOnLogin server read failed: $e\n$st');
      remote = await _moneyRef(user.uid).get();
    }

    Map<String, dynamic>? remotePayload;
    var hasRealCloud = remote.exists;
    if (hasRealCloud) {
      final raw = remote.data()?['payload'];
      if (raw is Map) {
        remotePayload = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
        if (BackupService.payloadLooksLikeDemo(remotePayload)) {
          debugPrint('CloudAuth.syncOnLogin: deleting demo cloud snapshot');
          try {
            await _moneyRef(user.uid).delete();
          } catch (_) {}
          hasRealCloud = false;
          remotePayload = null;
        }
      }
    }

    var refreshed = false;
    if (hasRealCloud) {
      // After clearDemo, hasLocalMoneyData is false (single empty cash) —
      // treat that like a fresh login and take cloud without a conflict dialog.
      if (localWasDemo || !await backup.hasLocalMoneyData()) {
        final ok = remotePayload != null
            ? await _restoreMoneyPayload(user.uid, remotePayload)
            : await downloadMoney();
        if (ok) {
          refreshUiAfterMoneyRestoreRef(_ref);
          refreshed = true;
        }
      } else {
        _ref.read(cloudUploadHoldProvider.notifier).state = true;
        _ref.read(pendingCloudRestoreProvider.notifier).state = true;
      }
    } else if (await backup.hasLocalMoneyData()) {
      await uploadMoney();
    }

    // clearDemo leaves one cash account (hasLocalMoneyData == false), so the
    // branches above may not refresh — always refresh after wiping demo.
    if (localWasDemo && !refreshed) {
      refreshUiAfterMoneyRestoreRef(_ref);
    }

    // Don't block sign-in on assistant history — chat screen syncs on open.
    unawaited(_syncAssistantQuietly());
  }

  Future<void> _syncAssistantQuietly() async {
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

  /// Uploads a profile photo to Storage and syncs Auth + Firestore.
  Future<void> uploadProfilePhoto(File file) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final storageRef =
        FirebaseStorage.instance.ref().child('users/${user.uid}/avatar.jpg');
    await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await storageRef.getDownloadURL();

    await user.updatePhotoURL(url);
    await _profileRef(user.uid).set(
      {
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await user.reload();
  }

  /// Removes cloud avatar; local file is cleared by the caller.
  Future<void> removeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/avatar.jpg')
          .delete();
    } catch (_) {}

    await user.updatePhotoURL(null);
    await _profileRef(user.uid).set(
      {
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await user.reload();
  }
}

final cloudAuthProvider = Provider<CloudAuth>((ref) => CloudAuth(ref));

final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(cloudAuthProvider).authChanges();
});
