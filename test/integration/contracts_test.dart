import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/app_info.dart';
import 'package:pulpo/src/core/pro/pro_limits.dart';

/// Contract tests for release integrations (Firebase, IAP). Full device/emulator
/// flows belong in CI with secrets; these guard static configuration drift.
void main() {
  group('Firebase App Check / bundle ids', () {
    test('Android and iOS ids are documented separately', () {
      expect(AppInfo.androidBundleId, startsWith('com.pulpo.'));
      expect(AppInfo.bundleId, startsWith('com.pulpo.'));
    });
  });

  group('In-app purchase product ids', () {
    test('Pro SKUs are non-empty and unique', () {
      expect(ProProducts.monthlyId, 'monedero_pro_mensual');
      expect(ProProducts.semiAnnualId, 'monedero_pro_6meses');
      expect(ProProducts.yearlyId, 'monedero_pro_anual');
      expect(ProProducts.ids.length, 3);
      expect(ProProducts.subscriptionGroupId, '22339635');
    });
  });
}
