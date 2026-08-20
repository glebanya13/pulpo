import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/cloud_auth.dart';
import 'pro_limits.dart';

class CloudProSnapshot {
  const CloudProSnapshot({
    required this.signedIn,
    required this.hasRemote,
    required this.entitled,
    required this.revokedByAdmin,
    this.productId,
    this.expiresAt,
  });

  final bool signedIn;
  final bool hasRemote;
  final bool entitled;
  final bool revokedByAdmin;
  final String? productId;
  final DateTime? expiresAt;

  static const none = CloudProSnapshot(
    signedIn: false,
    hasRemote: false,
    entitled: false,
    revokedByAdmin: false,
  );

  static CloudProSnapshot fromProfileData(Map<String, dynamic>? data) {
    final pro = data?['pro'];
    final map = pro is Map<String, dynamic> ? pro : null;
    DateTime? expires;
    final raw = map?['expiresAt'];
    if (raw is Timestamp) {
      expires = raw.toDate();
    } else if (raw is String) {
      expires = DateTime.tryParse(raw);
    }
    return CloudProSnapshot(
      signedIn: true,
      hasRemote: map != null,
      entitled: _isEntitled(map),
      revokedByAdmin: _revokedByAdmin(map),
      productId: map?['productId'] as String?,
      expiresAt: expires,
    );
  }

  static bool _isEntitled(Map<String, dynamic>? pro) {
    if (pro == null) return false;
    if (pro['entitled'] != true) return false;
    final expiresRaw = pro['expiresAt'];
    if (expiresRaw == null) return true;
    final expires = expiresRaw is Timestamp
        ? expiresRaw.toDate()
        : DateTime.tryParse(expiresRaw.toString());
    if (expires == null) return true;
    return expires.isAfter(DateTime.now());
  }

  static bool _revokedByAdmin(Map<String, dynamic>? pro) {
    if (pro == null) return false;
    return pro['entitled'] == false && pro['source'] == 'admin';
  }
}

class VerifyPurchaseResult {
  const VerifyPurchaseResult({
    required this.entitled,
    this.productId,
    this.expiresAt,
    this.transactionId,
  });

  final bool entitled;
  final String? productId;
  final DateTime? expiresAt;
  final String? transactionId;

  factory VerifyPurchaseResult.fromMap(Map<String, dynamic> data) {
    DateTime? expires;
    final raw = data['expiresAt'];
    if (raw is String && raw.isNotEmpty) {
      expires = DateTime.tryParse(raw);
    }
    return VerifyPurchaseResult(
      entitled: data['entitled'] == true,
      productId: data['productId'] as String?,
      expiresAt: expires,
      transactionId: data['transactionId'] as String?,
    );
  }
}

class CloudProService {
  CloudProService();

  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _db.collection('users').doc(uid);

  CloudProSnapshot parseDoc(Map<String, dynamic>? data) =>
      CloudProSnapshot.fromProfileData(data);

  Future<CloudProSnapshot> fetchCurrent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return CloudProSnapshot.none;
    try {
      final snap = await _profileRef(user.uid).get();
      return parseDoc(snap.data());
    } catch (e, st) {
      debugPrint('cloud pro fetch: $e\n$st');
      return CloudProSnapshot.none.copySignedIn();
    }
  }

  Stream<CloudProSnapshot> watchCurrent() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(CloudProSnapshot.none);
    }
    return _profileRef(user.uid).snapshots().map((snap) => parseDoc(snap.data()));
  }

  Future<VerifyPurchaseResult> verifyPurchase({
    required String platform,
    required String productId,
    required String verificationData,
    String? purchaseId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('sign_in_required');
    }
    if (!ProProducts.ids.contains(productId)) {
      throw ArgumentError('Unknown productId: $productId');
    }

    final callable = _functions.httpsCallable('verifyPurchase');
    final result = await callable.call<Map<String, dynamic>>({
      'platform': platform,
      'productId': productId,
      'verificationData': verificationData,
      if (purchaseId != null && purchaseId.isNotEmpty) 'purchaseId': purchaseId,
    });

    final data = Map<String, dynamic>.from(result.data);
    return VerifyPurchaseResult.fromMap(data);
  }

  Future<VerifyPurchaseResult> refreshEntitlement() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const VerifyPurchaseResult(entitled: false);
    }
    final callable = _functions.httpsCallable('refreshEntitlement');
    final result = await callable.call<Map<String, dynamic>>();
    return VerifyPurchaseResult.fromMap(Map<String, dynamic>.from(result.data));
  }
}

extension on CloudProSnapshot {
  CloudProSnapshot copySignedIn() => CloudProSnapshot(
        signedIn: true,
        hasRemote: hasRemote,
        entitled: entitled,
        revokedByAdmin: revokedByAdmin,
        productId: productId,
        expiresAt: expiresAt,
      );
}

final cloudProServiceProvider = Provider<CloudProService>((ref) {
  return CloudProService();
});

final cloudProSnapshotProvider = StreamProvider<CloudProSnapshot>((ref) {
  ref.watch(authUserProvider);
  return ref.watch(cloudProServiceProvider).watchCurrent();
});
