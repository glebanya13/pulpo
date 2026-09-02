import 'package:intl/intl.dart';

import '../currencies.dart';

String formatMoney(
  num amount,
  String currency, {
  bool showSign = false,
  String? locale,
}) {
  final formatter = NumberFormat.currency(
    locale: locale ?? localeForCurrency(currency),
    symbol: _symbolFor(currency),
    decimalDigits: 2,
  );
  final str = formatter.format(amount.abs());
  if (!showSign) return str;
  return amount < 0 ? '−$str' : '+$str';
}

/// NumberFormat locale for a currency (display only).
String localeForCurrency(String currencyCode) {
  return switch (currencyCode.toUpperCase()) {
    'EUR' => 'es_ES',
    'USD' => 'en_US',
    'GBP' => 'en_GB',
    'MXN' => 'es_MX',
    'BRL' => 'pt_BR',
    'CAD' => 'en_CA',
    'CHF' => 'de_CH',
    'UAH' => 'uk_UA',
    'RUB' => 'ru_RU',
    'COP' || 'ARS' || 'CLP' || 'PEN' => 'es_ES',
    _ => 'es_ES',
  };
}

String formatAmountBare(num amount) {
  final f = NumberFormat('#,##0.00', 'es_ES');
  return f.format(amount.abs());
}

String _symbolFor(String code) => symbolForCode(code);
