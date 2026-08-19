import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/settings_service.dart';
import 'pro_limits.dart';

const _kEntitled = 'pro_entitled';
const _kDebugUnlock = 'pro_debug_unlock';
const _kProductId = 'pro_product_id';

class ProState {
  const ProState({
    required this.entitled,
    required this.debugUnlock,
    required this.loading,
    required this.purchasing,
    required this.storeAvailable,
    required this.products,
    this.error,
  });

  final bool entitled;
  final bool debugUnlock;
  final bool loading;
  final bool purchasing;
  final bool storeAvailable;
  final List<ProductDetails> products;
  final String? error;

  bool get isPro => entitled || debugUnlock;

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
    bool? debugUnlock,
    bool? loading,
    bool? purchasing,
    bool? storeAvailable,
    List<ProductDetails>? products,
    String? error,
    bool clearError = false,
  }) {
    return ProState(
      entitled: entitled ?? this.entitled,
      debugUnlock: debugUnlock ?? this.debugUnlock,
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

  @override
  ProState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _listening = false;
    });
    final entitled = _prefs.getBool(_kEntitled) ?? false;
    final debug = _prefs.getBool(_kDebugUnlock) ?? false;
    Future<void>.microtask(refresh);
    return ProState(
      entitled: entitled,
      debugUnlock: debug,
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

    state = state.copyWith(
      loading: false,
      storeAvailable: available,
      products: products,
      entitled: _prefs.getBool(_kEntitled) ?? false,
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

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    var unlocked = false;
    String? productId;
    String? error;
    for (final p in purchases) {
      if (!ProProducts.ids.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          unlocked = true;
          productId = p.productID;
        case PurchaseStatus.error:
          error = p.error?.message ?? 'purchase error';
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (e, st) {
          debugPrint('iap complete: $e\n$st');
        }
      }
    }

    if (unlocked) {
      await _prefs.setBool(_kEntitled, true);
      if (productId != null) {
        await _prefs.setString(_kProductId, productId);
      }
      state = state.copyWith(
        entitled: true,
        purchasing: false,
        clearError: true,
      );
      return;
    }

    if (error != null) {
      state = state.copyWith(purchasing: false, error: error);
    } else {
      state = state.copyWith(purchasing: false);
    }
  }

  Future<bool> buy(ProductDetails product) async {
    if (kIsWeb) return false;
    state = state.copyWith(purchasing: true, clearError: true);
    try {
      final ok = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
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

  Future<void> restore() async {
    if (kIsWeb) return;
    state = state.copyWith(purchasing: true, clearError: true);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e, st) {
      debugPrint('iap restore: $e\n$st');
      state = state.copyWith(purchasing: false, error: e.toString());
    }
  }

  Future<void> setDebugUnlock(bool value) async {
    await _prefs.setBool(_kDebugUnlock, value);
    state = state.copyWith(debugUnlock: value);
  }
}

final proControllerProvider =
    NotifierProvider<ProController, ProState>(ProController.new);
