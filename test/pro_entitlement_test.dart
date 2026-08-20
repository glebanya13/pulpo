import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/pro/cloud_pro_service.dart';
import 'package:pulpo/src/core/pro/pro_controller.dart';
import 'package:pulpo/src/core/pro/pro_limits.dart';

ProState _state({
  bool entitled = false,
  DateTime? localExpiresAt,
  CloudProSnapshot cloud = CloudProSnapshot.none,
  bool debugUnlock = false,
}) {
  return ProState(
    entitled: entitled,
    localExpiresAt: localExpiresAt,
    debugUnlock: debugUnlock,
    cloud: cloud,
    loading: false,
    purchasing: false,
    storeAvailable: true,
    products: const [],
  );
}

void main() {
  group('ProState.isPro', () {
    test('debug unlock always grants Pro', () {
      expect(_state(debugUnlock: true).isPro, isTrue);
    });

    test('signed-in cloud entitlement wins', () {
      final state = _state(
        entitled: false,
        cloud: const CloudProSnapshot(
          signedIn: true,
          hasRemote: true,
          entitled: true,
          revokedByAdmin: false,
          expiresAt: null,
        ),
      );
      expect(state.isPro, isTrue);
    });

    test('admin revoke blocks Pro even with local cache', () {
      final state = _state(
        entitled: true,
        localExpiresAt: DateTime.now().add(const Duration(days: 30)),
        cloud: const CloudProSnapshot(
          signedIn: true,
          hasRemote: true,
          entitled: false,
          revokedByAdmin: true,
        ),
      );
      expect(state.isPro, isFalse);
    });

    test('local entitlement requires future expiry', () {
      expect(
        _state(
          entitled: true,
          localExpiresAt: DateTime.now().add(const Duration(days: 1)),
        ).isPro,
        isTrue,
      );
      expect(
        _state(
          entitled: true,
          localExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ).isPro,
        isFalse,
      );
      expect(_state(entitled: true, localExpiresAt: null).isPro, isFalse);
    });

    test('unsigned user does not inherit expired cloud doc', () {
      expect(
        _state(
          entitled: false,
          cloud: CloudProSnapshot.none,
        ).isPro,
        isFalse,
      );
    });
  });

  group('CloudProSnapshot parsing', () {
    test('entitlement expires in the past', () {
      final snap = CloudProSnapshot.fromProfileData({
        'pro': {
          'entitled': true,
          'source': 'iap',
          'expiresAt': DateTime.now()
              .subtract(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
        },
      });
      expect(snap.entitled, isFalse);
    });

    test('future trial expiry stays entitled', () {
      final snap = CloudProSnapshot.fromProfileData({
        'pro': {
          'entitled': true,
          'source': 'iap',
          'productId': ProProducts.yearlyId,
          'expiresAt': DateTime.now()
              .add(const Duration(days: 7))
              .toUtc()
              .toIso8601String(),
        },
      });
      expect(snap.entitled, isTrue);
      expect(snap.productId, ProProducts.yearlyId);
    });

    test('admin revoke detected', () {
      final snap = CloudProSnapshot.fromProfileData({
        'pro': {
          'entitled': false,
          'source': 'admin',
        },
      });
      expect(snap.revokedByAdmin, isTrue);
    });
  });

  group('VerifyPurchaseResult', () {
    test('parses callable payload', () {
      final result = VerifyPurchaseResult.fromMap({
        'entitled': true,
        'productId': ProProducts.yearlyId,
        'expiresAt': '2026-12-31T00:00:00.000Z',
        'transactionId': 'tx_123',
      });
      expect(result.entitled, isTrue);
      expect(result.productId, ProProducts.yearlyId);
      expect(result.expiresAt, isNotNull);
      expect(result.transactionId, 'tx_123');
    });
  });
}
