import 'package:flutter_test/flutter_test.dart';

import 'package:pulpo/src/core/utils/money_format.dart';

void main() {
  test('formatMoney keeps minus for negative balances', () {
    final s = formatMoney(-1.75, 'EUR');
    expect(s.contains('1,75') || s.contains('1.75'), isTrue);
    expect(s.startsWith('-') || s.startsWith('−'), isTrue);
  });

  test('formatMoney showSign prefixes +/−', () {
    expect(formatMoney(1.75, 'EUR', showSign: true).startsWith('+'), isTrue);
    expect(
      formatMoney(-1.75, 'EUR', showSign: true).startsWith('−') ||
          formatMoney(-1.75, 'EUR', showSign: true).startsWith('-'),
      isTrue,
    );
  });
}
