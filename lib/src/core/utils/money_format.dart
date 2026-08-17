import 'package:intl/intl.dart';

import '../currencies.dart';

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

String _symbolFor(String code) => symbolForCode(code);
