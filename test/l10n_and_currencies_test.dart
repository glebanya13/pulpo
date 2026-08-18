import 'package:flutter_test/flutter_test.dart';
import 'package:pulpo/src/core/currencies.dart';
import 'package:pulpo/src/core/l10n/tr.dart';

void main() {
  test('translations: inRealtime exists and is localized', () {
    final ru = Tr.fromLang('ru').inRealtime;
    final es = Tr.fromLang('es').inRealtime;
    final en = Tr.fromLang('en').inRealtime;

    expect(ru, contains('реальном времени'));
    expect(es, contains('tiempo real'));
    expect(en.toLowerCase(), contains('live'));
  });

  test('currencies: EUR and USD are unique (no duplicates)', () {
    final unique = uniqueAppCurrencies();

    int codeCount(String code) =>
        unique.where((c) => c.code == code).length;

    final eurCount = codeCount('EUR');
    final usdCount = codeCount('USD');

    expect(eurCount, 1);
    expect(usdCount, 1);

    final eur = unique.firstWhere((c) => c.code == 'EUR');
    expect(eur.country, 'España');

    final usd = unique.firstWhere((c) => c.code == 'USD');
    expect(usd.country, 'Estados Unidos');
  });
}

