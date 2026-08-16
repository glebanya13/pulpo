import 'package:intl/intl.dart';

String formatMoney(num amount, String currency, {bool showSign = false}) {
  final formatter = NumberFormat.currency(
    locale: 'es_ES',
    symbol: _symbolFor(currency),
    decimalDigits: 2,
  );
  final str = formatter.format(amount.abs());
  if (!showSign) return str;
  return amount < 0 ? '−$str' : '+$str';
}

String formatAmountBare(num amount) {
  final f = NumberFormat('#,##0.00', 'es_ES');
  return f.format(amount.abs());
}

String _symbolFor(String code) {
  switch (code.toUpperCase()) {
    case 'EUR':
      return '€';
    case 'USD':
    case 'MXN':
    case 'ARS':
    case 'COP':
    case 'CLP':
    case 'UYU':
    case 'DOP':
    case 'CUP':
      return '\$';
    case 'PEN':
      return 'S/';
    case 'PYG':
      return '₲';
    case 'BOB':
      return 'Bs';
    case 'VES':
      return 'Bs.';
    case 'CRC':
      return '₡';
    case 'GTQ':
      return 'Q';
    case 'HNL':
      return 'L';
    case 'NIO':
      return 'C\$';
    case 'XAF':
      return 'FCFA ';
    default:
      return '$code ';
  }
}
