import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:pulpo/src/core/pro/pro_limits.dart';
import 'package:pulpo/src/core/pro/product_offer_info.dart';
import 'package:pulpo/src/core/pro/store_pricing.dart';

class _FakeProduct extends ProductDetails {
  _FakeProduct({
    required super.id,
    required super.price,
    required super.rawPrice,
    required super.currencyCode,
  }) : super(title: 'Pro', description: 'Pro');
}

void main() {
  test('StorePricing maps Spain storefront to EUR', () {
    expect(StorePricing.currencyForCountry('ESP'), 'EUR');
    expect(StorePricing.currencyForCountry('USA'), 'USD');
  });

  test('paywall uses EUR catalog when storefront is Spain but store returns USD',
      () {
    final monthly = _FakeProduct(
      id: ProProducts.monthlyId,
      price: r'$3.99',
      rawPrice: 3.99,
      currencyCode: 'USD',
    );
    final price =
        ProductOfferInfo.paywallPrice(monthly, storeCountryCode: 'ESP');
    expect(price, contains('€'));
    expect(price, contains('3,99'));
  });

  test('paywall keeps Apple USD price for US storefront', () {
    final monthly = _FakeProduct(
      id: ProProducts.monthlyId,
      price: r'$3.99',
      rawPrice: 3.99,
      currencyCode: 'USD',
    );
    expect(
      ProductOfferInfo.paywallPrice(monthly, storeCountryCode: 'USA'),
      r'$3.99',
    );
  });

  test('paywall uses Apple EUR price for Spanish storefront', () {
    final monthly = _FakeProduct(
      id: ProProducts.monthlyId,
      price: '3,99 €',
      rawPrice: 3.99,
      currencyCode: 'EUR',
    );
    expect(
      ProductOfferInfo.paywallPrice(monthly, storeCountryCode: 'ESP'),
      '3,99 €',
    );
  });

  test('comparePrice uses same currency as paywall for EU sandbox mismatch', () {
    final monthly = _FakeProduct(
      id: ProProducts.monthlyId,
      price: r'$3.99',
      rawPrice: 3.99,
      currencyCode: 'USD',
    );
    final compare = ProductOfferInfo.comparePrice(
      base: monthly,
      multiplier: 12,
      storeCountryCode: 'ESP',
    );
    expect(compare, contains('€'));
    expect(compare, contains('47,88'));
  });
}
