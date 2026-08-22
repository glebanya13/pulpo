import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/app_info.dart';
import 'package:pulpo/src/core/app_startup.dart';
import 'package:pulpo/src/core/pro/pro_limits.dart';

void main() {
  test('AppStartupState flags firebase and data failures', () {
    const ok = AppStartupState(firebaseReady: true);
    expect(ok.showFirebaseWarning, isFalse);
    expect(ok.showDataWarning, isFalse);

    const firebaseFail = AppStartupState(firebaseError: 'network');
    expect(firebaseFail.showFirebaseWarning, isTrue);

    const dataFail = AppStartupState(
      firebaseReady: true,
      dataInitError: 'seed failed',
    );
    expect(dataFail.showDataWarning, isTrue);
    expect(dataFail.showFirebaseWarning, isFalse);
  });

  test('platform bundle ids differ between Android and iOS', () {
    expect(AppInfo.bundleId, 'com.pulpo.app');
    expect(AppInfo.androidBundleId, 'com.pulpo.android');
    expect(AppInfo.bundleId, isNot(AppInfo.androidBundleId));
  });

  test('CSV import is not a Pro quota gate', () {
    expect(ProLimits.freeLimit(ProGate.importCsv), isNull);
  });
}
