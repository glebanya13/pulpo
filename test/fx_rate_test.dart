import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/fx_rate_service.dart';

void main() {
  test('same currency rate is 1 without network', () async {
    final fx = FxRateService();
    expect(await fx.fetchRate('EUR', 'EUR'), 1);
    expect(await fx.fetchRate('usd', 'USD'), 1);
  });
}
