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

  test('currencies: full country list order and coverage', () {
    expect(appCurrencies.length, 29);
    expect(appCurrencies.first.country, 'México');
    expect(appCurrencies[1].country, 'Colombia');
    expect(appCurrencies[2].country, 'España');

    final countries = appCurrencies.map((c) => c.country).toList();
    expect(countries, contains('Ecuador'));
    expect(countries, contains('El Salvador'));
    expect(countries, contains('Puerto Rico'));
    expect(countries, contains('Francia'));
    expect(countries, contains('Alemania'));
    expect(countries, contains('Italia'));
  });

  test('currencies: unique list keeps first country per code', () {
    final unique = uniqueAppCurrencies();

    expect(unique.firstWhere((c) => c.code == 'EUR').country, 'España');
    expect(unique.firstWhere((c) => c.code == 'USD').country, 'Estados Unidos');
  });

  test('currencies: defaultCountryForCode resolves first match', () {
    expect(defaultCountryForCode('USD'), 'Estados Unidos');
    expect(defaultCountryForCode('EUR'), 'España');
    expect(firstCurrencyForCode('EUR').country, 'España');
  });

  test('translations: transfer tab labels exist and are localized', () {
    final ru = Tr.fromLang('ru');
    final es = Tr.fromLang('es');
    final en = Tr.fromLang('en');

    expect(ru.transferBetweenTab.toLowerCase(), contains('перевод'));
    expect(ru.transferExternalTab.toLowerCase(), contains('внеш'));

    expect(es.transferBetweenTab.toLowerCase(), contains('interna'));
    expect(es.transferExternalTab.toLowerCase(), contains('externa'));

    expect(en.transferBetweenTab.toLowerCase(), contains('internal'));
    expect(en.transferExternalTab.toLowerCase(), contains('external'));
  });
}
