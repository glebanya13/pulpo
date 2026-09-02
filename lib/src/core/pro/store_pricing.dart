// App Store / Play storefront country → billing currency.
//
// Apple returns prices in the currency of the user's App Store account
// (ProductDetails.currencyCode), not GPS location. StoreKit exposes the
// storefront as ISO 3166-1 alpha-3 (e.g. ESP, USA).
import 'dart:ui' show PlatformDispatcher;

import 'pro_limits.dart';

class StorePricing {
  const StorePricing._();

  /// ISO 3166-1 alpha-3 → ISO 4217. Covers Monedero target territories.
  static const countryCurrency = <String, String>{
    // Europe
    'ESP': 'EUR',
    'FRA': 'EUR',
    'DEU': 'EUR',
    'ITA': 'EUR',
    'PRT': 'EUR',
    'NLD': 'EUR',
    'BEL': 'EUR',
    'AUT': 'EUR',
    'IRL': 'EUR',
    'FIN': 'EUR',
    'GRC': 'EUR',
    'SVK': 'EUR',
    'SVN': 'EUR',
    'EST': 'EUR',
    'LVA': 'EUR',
    'LTU': 'EUR',
    'LUX': 'EUR',
    'MLT': 'EUR',
    'CYP': 'EUR',
    'GBR': 'GBP',
    'CHE': 'CHF',
    'UKR': 'UAH',
    'RUS': 'RUB',
    // Americas
    'USA': 'USD',
    'MEX': 'MXN',
    'COL': 'COP',
    'ARG': 'ARS',
    'PER': 'PEN',
    'VEN': 'VES',
    'CHL': 'CLP',
    'ECU': 'USD',
    'GTM': 'GTQ',
    'BOL': 'BOB',
    'DOM': 'DOP',
    'CUB': 'CUP',
    'HND': 'HNL',
    'PRY': 'PYG',
    'NIC': 'NIO',
    'SLV': 'USD',
    'CRI': 'CRC',
    'PAN': 'PAB',
    'URY': 'UYU',
    'PRI': 'USD',
    'GNQ': 'XAF',
    'BRA': 'BRL',
    'CAN': 'CAD',
    // ISO 3166-1 alpha-2 (StoreKit priceLocale.countryCode)
    'ES': 'EUR',
    'US': 'USD',
    'MX': 'MXN',
    'GB': 'GBP',
    'FR': 'EUR',
    'DE': 'EUR',
    'IT': 'EUR',
    'BR': 'BRL',
    'UA': 'UAH',
    'RU': 'RUB',
  };

  static String? currencyForCountry(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return null;
    return countryCurrency[countryCode.toUpperCase()];
  }

  /// Device region from OS locale (`es_ES` → `ES`, `ru_ES` → `ES`).
  static String? deviceCountryCode() {
    final code = PlatformDispatcher.instance.locale.countryCode;
    if (code == null || code.isEmpty) return null;
    return code.toUpperCase();
  }

  /// StoreKit storefront → SK1 price locale → app currency country → device region.
  static String? resolveCountry({
    String? storeCountryCode,
    String? productCountryCode,
    String? preferredCountryCode,
  }) {
    for (final code in [
      storeCountryCode,
      productCountryCode,
      preferredCountryCode,
      deviceCountryCode(),
    ]) {
      if (code == null || code.isEmpty) continue;
      final upper = code.toUpperCase();
      if (currencyForCountry(upper) != null) return upper;
    }
    return storeCountryCode?.toUpperCase() ??
        productCountryCode?.toUpperCase() ??
        preferredCountryCode?.toUpperCase() ??
        deviceCountryCode();
  }

  /// Use ASC catalog (EUR) when the store price is in another currency but the
  /// user's storefront / app currency expects euros (common with US sandbox).
  static bool shouldUseCatalog({
    required String storeCurrency,
    required String? countryCode,
    String? preferredCurrency,
  }) {
    final store = storeCurrency.toUpperCase();
    if (store == ProProducts.catalogCurrency) return false;

    final expected = currencyForCountry(countryCode);
    if (expected == ProProducts.catalogCurrency) return true;

    if (preferredCurrency?.toUpperCase() == ProProducts.catalogCurrency) {
      return true;
    }
    return false;
  }
}
