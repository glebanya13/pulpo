import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// Trial length and yearly savings derived from the store (fallback = null).
class ProductOfferInfo {
  const ProductOfferInfo._();

  /// Free-trial length in days from StoreKit / Play, if configured.
  static int? trialDays(ProductDetails product) {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final sk2 = _sk2TrialDays(product);
        if (sk2 != null) return sk2;
        return _sk1TrialDays(product);
      }
      if (!kIsWeb && Platform.isAndroid) {
        return _androidTrialDays(product);
      }
    } catch (e, st) {
      debugPrint('ProductOfferInfo.trialDays: $e\n$st');
    }
    return null;
  }

  /// Percent saved vs 12× monthly, or null if prices missing / not cheaper.
  static int? yearlySavePercent({
    required ProductDetails? monthly,
    required ProductDetails? yearly,
  }) {
    final m = monthly?.rawPrice ?? 0;
    final y = yearly?.rawPrice ?? 0;
    if (m <= 0 || y <= 0) return null;
    final full = m * 12;
    if (full <= y) return null;
    return ((1 - y / full) * 100).round().clamp(1, 99);
  }

  /// Percent saved vs 6× monthly.
  static int? semiAnnualSavePercent({
    required ProductDetails? monthly,
    required ProductDetails? semiAnnual,
  }) {
    final m = monthly?.rawPrice ?? 0;
    final s = semiAnnual?.rawPrice ?? 0;
    if (m <= 0 || s <= 0) return null;
    final full = m * 6;
    if (full <= s) return null;
    return ((1 - s / full) * 100).round().clamp(1, 99);
  }

  /// Strikethrough reference price (e.g. 12× monthly for yearly).
  static String? comparePrice({
    required ProductDetails? base,
    required int multiplier,
  }) {
    if (base == null || multiplier <= 0) return null;
    final total = base.rawPrice * multiplier;
    if (total <= 0) return null;
    final sym = base.currencySymbol;
    final decimals = total == total.roundToDouble() ? 0 : 2;
    return '$sym${total.toStringAsFixed(decimals)}';
  }

  static int? _sk2TrialDays(ProductDetails product) {
    if (product is! AppStoreProduct2Details) return null;
    final offers = product.sk2Product.subscription?.promotionalOffers;
    if (offers == null) return null;
    for (final offer in offers) {
      if (offer.type != SK2SubscriptionOfferType.introductory) continue;
      if (offer.paymentMode != SK2SubscriptionOfferPaymentMode.freeTrial) {
        continue;
      }
      return _periodToDays(offer.period, offer.periodCount);
    }
    return null;
  }

  static int? _sk1TrialDays(ProductDetails product) {
    if (product is! AppStoreProductDetails) return null;
    final intro = product.skProduct.introductoryPrice;
    if (intro == null) return null;
    if (intro.paymentMode != SKProductDiscountPaymentMode.freeTrail) {
      return null;
    }
    final period = intro.subscriptionPeriod;
    final unitDays = switch (period.unit) {
      SKSubscriptionPeriodUnit.day => 1,
      SKSubscriptionPeriodUnit.week => 7,
      SKSubscriptionPeriodUnit.month => 30,
      SKSubscriptionPeriodUnit.year => 365,
    };
    return unitDays * period.numberOfUnits * intro.numberOfPeriods;
  }

  static int? _androidTrialDays(ProductDetails product) {
    if (product is! GooglePlayProductDetails) return null;
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    final phases = offers[index].pricingPhases;
    for (final phase in phases) {
      if (phase.priceAmountMicros != 0) continue;
      final days = _iso8601PeriodToDays(phase.billingPeriod);
      if (days == null || days <= 0) continue;
      final cycles = phase.billingCycleCount <= 0 ? 1 : phase.billingCycleCount;
      return days * cycles;
    }
    return null;
  }

  /// Parses Play Billing ISO-8601 periods like `P1W`, `P7D`, `P1M`.
  static int? _iso8601PeriodToDays(String period) {
    final m = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$')
        .firstMatch(period.trim().toUpperCase());
    if (m == null) return null;
    final y = int.tryParse(m.group(1) ?? '') ?? 0;
    final mo = int.tryParse(m.group(2) ?? '') ?? 0;
    final w = int.tryParse(m.group(3) ?? '') ?? 0;
    final d = int.tryParse(m.group(4) ?? '') ?? 0;
    return y * 365 + mo * 30 + w * 7 + d;
  }

  static int _periodToDays(SK2SubscriptionPeriod period, int count) {
    final unitDays = switch (period.unit) {
      SK2SubscriptionPeriodUnit.day => 1,
      SK2SubscriptionPeriodUnit.week => 7,
      SK2SubscriptionPeriodUnit.month => 30,
      SK2SubscriptionPeriodUnit.year => 365,
    };
    return unitDays * period.value * count;
  }
}
