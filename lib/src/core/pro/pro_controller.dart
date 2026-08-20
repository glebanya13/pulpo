import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_service.dart';
import 'cloud_pro_service.dart';
import 'pro_limits.dart';

const _kEntitled = 'pro_entitled';
const _kDebugUnlock = 'pro_debug_unlock';
const _kProductId = 'pro_product_id';
const _kExpiresAt = 'pro_expires_at';

class ProState {
  const ProState({
    required this.entitled,
    required this.localExpiresAt,
    required this.debugUnlock,
    required this.cloud,
    required this.loading,
    required this.purchasing,
    required this.storeAvailable,
    required this.products,
    this.error,
  });

  final bool entitled;
  final DateTime? localExpiresAt;
  final bool debugUnlock;
  final CloudProSnapshot cloud;
  final bool loading;
  final bool purchasing;
  final bool storeAvailable;
  final List<ProductDetails> products;
  final String? error;

  bool get isPro {
    if (kDebugMode && debugUnlock) return true;
    if (cloud.signedIn && cloud.hasRemote) {
      if (cloud.revokedByAdmin) return false;
      return cloud.entitled;
    }
    if (!entitled) return false;
    final expires = localExpiresAt;
    if (expires == null) return false;
    return expires.isAfter(DateTime.now());
  }

  DateTime? get subscriptionExpiresAt => cloud.expiresAt ?? localExpiresAt;

  int? get daysUntilExpiry {
    final exp = subscriptionExpiresAt;
    if (exp == null) return null;
    return exp.difference(DateTime.now()).inDays;
  }

  ProductDetails? get monthly => _byId(ProProducts.monthlyId);
  ProductDetails? get semiAnnual => _byId(ProProducts.semiAnnualId);
  ProductDetails? get yearly => _byId(ProProducts.yearlyId);

  ProductDetails? _byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  ProState copyWith({
    bool? entitled,
    DateTime? localExpiresAt,
    bool clearLocalExpiresAt = false,
    bool? debugUnlock,
    CloudProSnapshot? cloud,
    bool? loading,
    bool? purchasing,
    bool? storeAvailable,
    List<ProductDetails>? products,
    String? error,
    bool clearError = false,
  }) {
    return ProState(
      entitled: entitled ?? this.entitled,
      localExpiresAt:
          clearLocalExpiresAt ? null : (localExpiresAt ?? this.localExpiresAt),
      debugUnlock: debugUnlock ?? this.debugUnlock,
      cloud: cloud ?? this.cloud,
      loading: loading ?? this.loading,
      purchasing: purchasing ?? this.purchasing,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      products: products ?? this.products,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProController extends Notifier<ProState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  var _listening = false;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  DateTime? _readLocalExpiresAt() {
    final raw = _prefs.getString(_kExpiresAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _writeLocalEntitlement({
    required bool entitled,
    String? productId,
    DateTime? expiresAt,
  }) async {
    await _prefs.setBool(_kEntitled, entitled);
    if (productId != null) {
      await _prefs.setString(_kProductId, productId);
    }
    if (expiresAt != null) {
      await _prefs.setString(_kExpiresAt, expiresAt.toUtc().toIso8601String());
    } else {
      await _prefs.remove(_kExpiresAt);
    }
  }

  Future<void> _clearLocalEntitlement() async {
    await _prefs.setBool(_kEntitled, false);
    await _prefs.remove(_kProductId);
    await _prefs.remove(_kExpiresAt);
  }

  void _syncFromCloud(CloudProSnapshot snap) {
    if (!snap.signedIn) return;
    if (snap.hasRemote && snap.entitled && snap.expiresAt != null) {
      unawaited(_writeLocalEntitlement(
        entitled: true,
        productId: snap.productId,
        expiresAt: snap.expiresAt,
      ));
      state = state.copyWith(
        entitled: true,
        localExpiresAt: snap.expiresAt,
        cloud: snap,
      );
      return;
    }
    if (snap.hasRemote && !snap.entitled) {
      unawaited(_clearLocalEntitlement());
      state = state.copyWith(
        entitled: false,
        clearLocalExpiresAt: true,
        cloud: snap,
      );
    }
  }

  @override
  ProState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _listening = false;
    });

    ref.listen<AsyncValue<CloudProSnapshot>>(cloudProSnapshotProvider, (_, next) {
      final snap = next.value ?? CloudProSnapshot.none;
      _syncFromCloud(snap);
      state = state.copyWith(cloud: snap);
    });

    final entitled = _prefs.getBool(_kEntitled) ?? false;
    var debug = _prefs.getBool(_kDebugUnlock) ?? false;
    if (!kDebugMode && debug) {
      debug = false;
      unawaited(_prefs.setBool(_kDebugUnlock, false));
    }
    Future<void>.microtask(refresh);
    return ProState(
      entitled: entitled,
      localExpiresAt: _readLocalExpiresAt(),
      debugUnlock: kDebugMode && debug,
      cloud: CloudProSnapshot.none,
      loading: true,
      purchasing: false,
      storeAvailable: false,
      products: const [],
    );
  }

  Future<void> refresh() async {
    if (kIsWeb) {
      state = state.copyWith(
        loading: false,
        storeAvailable: false,
      );
      return;
    }

    _listenIfNeeded();
    final iap = InAppPurchase.instance;
    var available = false;
    try {
      available = await iap.isAvailable();
    } catch (e, st) {
      debugPrint('iap available: $e\n$st');
    }

    var products = const <ProductDetails>[];
    if (available) {
      try {
        final response = await iap.queryProductDetails(ProProducts.ids);
        products = response.productDetails;
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('iap missing: ${response.notFoundIDs}');
        }
      } catch (e, st) {
        debugPrint('iap products: $e\n$st');
      }
    }

    if (FirebaseAuth.instance.currentUser != null) {
      try {
        await ref.read(cloudProServiceProvider).refreshEntitlement();
      } catch (e, st) {
        debugPrint('refresh entitlement: $e\n$st');
      }
      try {
        final snap = await ref.read(cloudProServiceProvider).fetchCurrent();
        await _restoreIfSubscriptionNeedsSync(snap);
      } catch (e, st) {
        debugPrint('iap sync restore: $e\n$st');
      }
    }

    state = state.copyWith(
      loading: false,
      storeAvailable: available,
      products: products,
      entitled: _prefs.getBool(_kEntitled) ?? false,
      localExpiresAt: _readLocalExpiresAt(),
      debugUnlock: _prefs.getBool(_kDebugUnlock) ?? false,
      clearError: true,
    );
  }

  void _listenIfNeeded() {
    if (_listening || kIsWeb) return;
    _listening = true;
    try {
      _sub = InAppPurchase.instance.purchaseStream.listen(
        _onPurchases,
        onError: (Object e, StackTrace st) {
          debugPrint('iap stream: $e\n$st');
          state = state.copyWith(purchasing: false, error: e.toString());
        },
      );
    } catch (e, st) {
      debugPrint('iap listen: $e\n$st');
    }
  }

  /// Re-query store when cloud expiry is missing, past, or within 3 days so
  /// trial→paid renewals update Firebase via verifyPurchase.
  Future<void> _restoreIfSubscriptionNeedsSync(CloudProSnapshot cloud) async {
    if (kIsWeb) return;
    if (!cloud.signedIn) return;
    final exp = cloud.expiresAt ?? state.localExpiresAt;
    final stillFresh = exp != null &&
        exp.isAfter(DateTime.now().add(const Duration(days: 3)));
    if (stillFresh) return;
    if (!cloud.hasRemote && !state.entitled) return;
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    String? error;
    var verifiedAny = false;

    for (final p in purchases) {
      if (!ProProducts.ids.contains(p.productID)) continue;

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (FirebaseAuth.instance.currentUser == null) {
          error = 'sign_in_required';
        } else {
          try {
            final platform = !kIsWeb && Platform.isIOS ? 'ios' : 'android';
            final result =
                await ref.read(cloudProServiceProvider).verifyPurchase(
                      platform: platform,
                      productId: p.productID,
                      verificationData:
                          p.verificationData.serverVerificationData,
                      purchaseId: p.purchaseID,
                    );
            if (result.entitled && result.expiresAt != null) {
              verifiedAny = true;
              await _writeLocalEntitlement(
                entitled: true,
                productId: result.productId ?? p.productID,
                expiresAt: result.expiresAt,
              );
              state = state.copyWith(
                entitled: true,
                localExpiresAt: result.expiresAt,
                purchasing: false,
                clearError: true,
              );
            }
          } catch (e, st) {
            debugPrint('verify purchase: $e\n$st');
            error = e.toString();
          }
        }
      } else if (p.status == PurchaseStatus.error) {
        error = p.error?.message ?? 'purchase error';
      }

      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (e, st) {
          debugPrint('iap complete: $e\n$st');
        }
      }
    }

    if (verifiedAny) return;

    if (error != null) {
      state = state.copyWith(purchasing: false, error: error);
    } else {
      state = state.copyWith(purchasing: false);
    }
  }

  Future<bool> buy(ProductDetails product) async {
    if (kIsWeb) return false;
    if (FirebaseAuth.instance.currentUser == null) {
      state = state.copyWith(purchasing: false, error: 'sign_in_required');
      return false;
    }

    state = state.copyWith(purchasing: true, clearError: true);
    try {
      final PurchaseParam param = product is GooglePlayProductDetails
          ? GooglePlayPurchaseParam(productDetails: product)
          : PurchaseParam(productDetails: product);
      final ok = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: param,
      );
      if (!ok) {
        state = state.copyWith(purchasing: false, error: 'buy failed');
      }
      return ok;
    } catch (e, st) {
      debugPrint('iap buy: $e\n$st');
      state = state.copyWith(purchasing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> restore() async {
    if (kIsWeb) return false;
    if (FirebaseAuth.instance.currentUser == null) {
      state = state.copyWith(purchasing: false, error: 'sign_in_required');
      return false;
    }

    state = state.copyWith(purchasing: true, clearError: true);
    try {
      await InAppPurchase.instance.restorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final isProNow = ref.read(proControllerProvider).isPro;
      state = state.copyWith(purchasing: false);
      return isProNow;
    } catch (e, st) {
      debugPrint('iap restore: $e\n$st');
      state = state.copyWith(purchasing: false, error: e.toString());
      return false;
    }
  }

  Future<void> setDebugUnlock(bool value) async {
    if (!kDebugMode) return;
    await _prefs.setBool(_kDebugUnlock, value);
    state = state.copyWith(debugUnlock: value);
  }
}

final proControllerProvider =
    NotifierProvider<ProController, ProState>(ProController.new);
