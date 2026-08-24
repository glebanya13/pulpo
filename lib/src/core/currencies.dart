class AppCurrency {
  const AppCurrency({
    required this.country,
    required this.code,
    required this.symbol,
    required this.flag,
  });

  final String country;
  final String code;
  final String symbol;
  final String flag;

  String get title => '$country — $code • $symbol';

  String localizedCountry(String lang) {
    switch (lang) {
      case 'en':
        return _countryEn[country] ?? country;
      case 'uk':
        return _countryUk[country] ?? _countryRu[country] ?? country;
      case 'ru':
        return _countryRu[country] ?? country;
      default:
        return country;
    }
  }

  String localizedTitle(String lang) =>
      '${localizedCountry(lang)} — $code • $symbol';
}

const _countryEn = <String, String>{
  'España': 'Spain',
  'México': 'Mexico',
  'Colombia': 'Colombia',
  'Argentina': 'Argentina',
  'Perú': 'Peru',
  'Venezuela': 'Venezuela',
  'Chile': 'Chile',
  'Estados Unidos': 'United States',
  'Ecuador': 'Ecuador',
  'Guatemala': 'Guatemala',
  'Bolivia': 'Bolivia',
  'República Dominicana': 'Dominican Republic',
  'Cuba': 'Cuba',
  'Honduras': 'Honduras',
  'Paraguay': 'Paraguay',
  'Nicaragua': 'Nicaragua',
  'El Salvador': 'El Salvador',
  'Costa Rica': 'Costa Rica',
  'Panamá': 'Panama',
  'Uruguay': 'Uruguay',
  'Puerto Rico': 'Puerto Rico',
  'Guinea Ecuatorial': 'Equatorial Guinea',
  'Brasil': 'Brazil',
  'Francia': 'France',
  'Alemania': 'Germany',
  'Reino Unido': 'United Kingdom',
  'Italia': 'Italy',
  'Canadá': 'Canada',
  'Suiza': 'Switzerland',
};

const _countryRu = <String, String>{
  'España': 'Испания',
  'México': 'Мексика',
  'Colombia': 'Колумбия',
  'Argentina': 'Аргентина',
  'Perú': 'Перу',
  'Venezuela': 'Венесуэла',
  'Chile': 'Чили',
  'Estados Unidos': 'США',
  'Ecuador': 'Эквадор',
  'Guatemala': 'Гватемала',
  'Bolivia': 'Боливия',
  'República Dominicana': 'Доминиканская Республика',
  'Cuba': 'Куба',
  'Honduras': 'Гондурас',
  'Paraguay': 'Парагвай',
  'Nicaragua': 'Никарагуа',
  'El Salvador': 'Сальвадор',
  'Costa Rica': 'Коста-Рика',
  'Panamá': 'Панама',
  'Uruguay': 'Уругвай',
  'Puerto Rico': 'Пуэрто-Рико',
  'Guinea Ecuatorial': 'Экваториальная Гвинея',
  'Brasil': 'Бразилия',
  'Francia': 'Франция',
  'Alemania': 'Германия',
  'Reino Unido': 'Великобритания',
  'Italia': 'Италия',
  'Canadá': 'Канада',
  'Suiza': 'Швейцария',
};

const _countryUk = <String, String>{
  'España': 'Іспанія',
  'México': 'Мексика',
  'Colombia': 'Колумбія',
  'Argentina': 'Аргентина',
  'Perú': 'Перу',
  'Venezuela': 'Венесуела',
  'Chile': 'Чилі',
  'Estados Unidos': 'США',
  'Ecuador': 'Еквадор',
  'Guatemala': 'Гватемала',
  'Bolivia': 'Болівія',
  'República Dominicana': 'Домініканська Республіка',
  'Cuba': 'Куба',
  'Honduras': 'Гондурас',
  'Paraguay': 'Парагвай',
  'Nicaragua': 'Нікарагуа',
  'El Salvador': 'Сальвадор',
  'Costa Rica': 'Коста-Рика',
  'Panamá': 'Панама',
  'Uruguay': 'Уругвай',
  'Puerto Rico': 'Пуерто-Рико',
  'Guinea Ecuatorial': 'Екваторіальна Гвінея',
  'Brasil': 'Бразилія',
  'Francia': 'Франція',
  'Alemania': 'Німеччина',
  'Reino Unido': 'Велика Британія',
  'Italia': 'Італія',
  'Canadá': 'Канада',
  'Suiza': 'Швейцарія',
};

/// Countries and currencies in the required order.
/// Same code may appear for multiple countries (EUR, USD).
const appCurrencies = <AppCurrency>[
  AppCurrency(country: 'España', code: 'EUR', symbol: '€', flag: '🇪🇸'),
  AppCurrency(country: 'México', code: 'MXN', symbol: r'$', flag: '🇲🇽'),
  AppCurrency(country: 'Colombia', code: 'COP', symbol: r'$', flag: '🇨🇴'),
  AppCurrency(country: 'Argentina', code: 'ARS', symbol: r'$', flag: '🇦🇷'),
  AppCurrency(country: 'Perú', code: 'PEN', symbol: 'S/', flag: '🇵🇪'),
  AppCurrency(country: 'Venezuela', code: 'VES', symbol: 'Bs.', flag: '🇻🇪'),
  AppCurrency(country: 'Chile', code: 'CLP', symbol: r'$', flag: '🇨🇱'),
  AppCurrency(
      country: 'Estados Unidos', code: 'USD', symbol: r'$', flag: '🇺🇸'),
  AppCurrency(country: 'Ecuador', code: 'USD', symbol: r'$', flag: '🇪🇨'),
  AppCurrency(country: 'Guatemala', code: 'GTQ', symbol: 'Q', flag: '🇬🇹'),
  AppCurrency(country: 'Bolivia', code: 'BOB', symbol: 'Bs.', flag: '🇧🇴'),
  AppCurrency(
      country: 'República Dominicana',
      code: 'DOP',
      symbol: r'RD$',
      flag: '🇩🇴'),
  AppCurrency(country: 'Cuba', code: 'CUP', symbol: r'$', flag: '🇨🇺'),
  AppCurrency(country: 'Honduras', code: 'HNL', symbol: 'L', flag: '🇭🇳'),
  AppCurrency(country: 'Paraguay', code: 'PYG', symbol: '₲', flag: '🇵🇾'),
  AppCurrency(country: 'Nicaragua', code: 'NIO', symbol: r'C$', flag: '🇳🇮'),
  AppCurrency(
      country: 'El Salvador', code: 'USD', symbol: r'$', flag: '🇸🇻'),
  AppCurrency(country: 'Costa Rica', code: 'CRC', symbol: '₡', flag: '🇨🇷'),
  AppCurrency(country: 'Panamá', code: 'PAB', symbol: 'B/.', flag: '🇵🇦'),
  AppCurrency(country: 'Uruguay', code: 'UYU', symbol: r'$U', flag: '🇺🇾'),
  AppCurrency(
      country: 'Puerto Rico', code: 'USD', symbol: r'$', flag: '🇵🇷'),
  AppCurrency(
      country: 'Guinea Ecuatorial',
      code: 'XAF',
      symbol: 'FCFA',
      flag: '🇬🇶'),
  AppCurrency(country: 'Brasil', code: 'BRL', symbol: r'R$', flag: '🇧🇷'),
  AppCurrency(country: 'Francia', code: 'EUR', symbol: '€', flag: '🇫🇷'),
  AppCurrency(country: 'Alemania', code: 'EUR', symbol: '€', flag: '🇩🇪'),
  AppCurrency(country: 'Reino Unido', code: 'GBP', symbol: '£', flag: '🇬🇧'),
  AppCurrency(country: 'Italia', code: 'EUR', symbol: '€', flag: '🇮🇹'),
  AppCurrency(country: 'Canadá', code: 'CAD', symbol: r'$', flag: '🇨🇦'),
  AppCurrency(country: 'Suiza', code: 'CHF', symbol: 'Fr.', flag: '🇨🇭'),
];

/// Unique codes, in order of first appearance in [appCurrencies].
List<AppCurrency> uniqueAppCurrencies() {
  final seen = <String>{};
  return [
    for (final c in appCurrencies)
      if (seen.add(c.code)) c,
  ];
}

String symbolForCode(String code) {
  final upper = code.toUpperCase();
  for (final c in appCurrencies) {
    if (c.code == upper) return c.symbol;
  }
  return '$upper ';
}

AppCurrency firstCurrencyForCode(String code) {
  final upper = code.toUpperCase();
  return appCurrencies.firstWhere((c) => c.code == upper);
}

AppCurrency? currencyForCountry(String country) {
  for (final c in appCurrencies) {
    if (c.country == country) return c;
  }
  return null;
}

String defaultCountryForCode(String code) => firstCurrencyForCode(code).country;
