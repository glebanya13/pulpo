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
}

/// One row per currency code. Eurozone is Spain; USD is the United States.
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
  AppCurrency(country: 'Costa Rica', code: 'CRC', symbol: '₡', flag: '🇨🇷'),
  AppCurrency(country: 'Panamá', code: 'PAB', symbol: 'B/.', flag: '🇵🇦'),
  AppCurrency(country: 'Uruguay', code: 'UYU', symbol: r'$U', flag: '🇺🇾'),
  AppCurrency(country: 'Brasil', code: 'BRL', symbol: r'R$', flag: '🇧🇷'),
  AppCurrency(country: 'Reino Unido', code: 'GBP', symbol: '£', flag: '🇬🇧'),
  AppCurrency(country: 'Canadá', code: 'CAD', symbol: r'$', flag: '🇨🇦'),
  AppCurrency(country: 'Suiza', code: 'CHF', symbol: 'Fr.', flag: '🇨🇭'),
  AppCurrency(
      country: 'Guinea Ecuatorial',
      code: 'XAF',
      symbol: 'FCFA',
      flag: '🇬🇶'),
];

/// Unique codes, in list order (list is already unique).
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
