import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/app_info.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/pro/product_offer_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/cloud_auth.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/pressable.dart';
import '../../widgets/common.dart';
import '../../core/open_link.dart';
import '../../core/pro/subscription_links.dart';

part 'paywall_plan_widgets.dart';
part 'paywall_content_widgets.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.gate = ProGate.generic});

  final ProGate gate;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  ProductDetails? _selected;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final pro = ref.watch(proControllerProvider);
    final storeCountry = pro.storeCountryCode;
    final settings = ref.watch(settingsControllerProvider);
    final pricing = (
      storeCountryCode: storeCountry,
      preferredCurrency: settings.baseCurrency,
      preferredCountryCode: settings.baseCurrencyCountry,
    );
    final signedIn = ref.watch(authUserProvider).valueOrNull != null;
    final yearly = pro.yearly;
    final monthly = pro.monthly;
    final semiAnnual = pro.semiAnnual;
    final selected = _selected ?? monthly ?? semiAnnual ?? yearly;
    final showPinnedCta = !pro.isPro && signedIn;
    final hasTrialOffer = selected != null &&
        (ProductOfferInfo.trialDaysForPaywall(selected) ?? 0) > 0;

    String trialLabelFor(ProductDetails product) {
      final days = ProductOfferInfo.trialDaysForPaywall(product);
      if (days == null || days <= 0) return '';
      return days == 7 ? tr.proTrial : tr.proTrialDays(days);
    }

    Widget paywallCta() {
      return ScaledElevatedButton(
        expand: true,
        onPressed: pro.purchasing || selected == null
            ? null
            : () => _buy(context, ref, tr, selected),
        child: Text(
          hasTrialOffer ? tr.proStartFreeTrial : _ctaLabel(tr, selected),
          textAlign: TextAlign.center,
        ),
      );
    }

    void closePaywall() => Navigator.pop(context);

    Widget floatingControl({
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Pressable(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: context.primaryText),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                56,
                24,
                showPinnedCta ? 100 : 32,
              ),
              children: [
            const Center(child: _PaywallProHero()),
            const SizedBox(height: 18),
            Text(
              tr.proTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tr.proSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: context.isDark
                    ? context.mutedText
                    : AppColors.textSecondary,
              ),
            ),
            if (pro.isPro) ...[
              const SizedBox(height: 20),
              _ProActiveSection(pro: pro),
              const SizedBox(height: 12),
              ScaledOutlinedButton(
                onPressed: () => openManageSubscriptions(context),
                child: Text(tr.proManageSubscription),
              ),
            ] else ...[
              if (!signedIn) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tr.proSignInRequired,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: context.mutedText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ScaledElevatedButton(
                        onPressed: () => context.push('/settings/account'),
                        child: Text(tr.signIn),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: pro.loading &&
                        monthly == null &&
                        semiAnnual == null &&
                        yearly == null &&
                        !pro.isPro
                    ? const _PaywallPlansSkeleton(key: ValueKey('plans-loading'))
                    : Column(
                        key: const ValueKey('plans-loaded'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (monthly != null)
                            _PaywallPlanCard(
                              title: tr.proMonthly,
                              price: ProductOfferInfo.paywallPrice(
                                monthly,
                                storeCountryCode: pricing.storeCountryCode,
                                preferredCurrency: pricing.preferredCurrency,
                                preferredCountryCode:
                                    pricing.preferredCountryCode,
                              ),
                              allFeaturesLabel: tr.proAllFeatures,
                              trialLabel: trialLabelFor(monthly),
                              selected: selected?.id == monthly.id,
                              busy: pro.purchasing,
                              onTap: () => setState(() => _selected = monthly),
                            ),
                          if (semiAnnual != null) ...[
                            const SizedBox(height: 10),
                            _PaywallPlanCard(
                              title: tr.proSemiAnnual,
                              price: ProductOfferInfo.paywallPrice(
                                semiAnnual,
                                storeCountryCode: pricing.storeCountryCode,
                                preferredCurrency: pricing.preferredCurrency,
                                preferredCountryCode:
                                    pricing.preferredCountryCode,
                              ),
                              allFeaturesLabel: tr.proAllFeatures,
                              trialLabel: trialLabelFor(semiAnnual),
                              comparePrice: ProductOfferInfo.comparePrice(
                                base: monthly,
                                multiplier: 6,
                                storeCountryCode: pricing.storeCountryCode,
                                preferredCurrency: pricing.preferredCurrency,
                                preferredCountryCode:
                                    pricing.preferredCountryCode,
                              ),
                              badge: () {
                                final pct = ProductOfferInfo.semiAnnualSavePercent(
                                  monthly: monthly,
                                  semiAnnual: semiAnnual,
                                  storeCountryCode: pricing.storeCountryCode,
                                  preferredCurrency: pricing.preferredCurrency,
                                  preferredCountryCode:
                                      pricing.preferredCountryCode,
                                );
                                return pct != null
                                    ? tr.proDiscountBadge(pct)
                                    : null;
                              }(),
                              selected: selected?.id == semiAnnual.id,
                              busy: pro.purchasing,
                              onTap: () =>
                                  setState(() => _selected = semiAnnual),
                            ),
                          ],
                          if (yearly != null) ...[
                            const SizedBox(height: 10),
                            _PaywallPlanCard(
                              title: tr.proYearly,
                              price: ProductOfferInfo.paywallPrice(
                                yearly,
                                storeCountryCode: pricing.storeCountryCode,
                                preferredCurrency: pricing.preferredCurrency,
                                preferredCountryCode:
                                    pricing.preferredCountryCode,
                              ),
                              allFeaturesLabel: tr.proAllFeatures,
                              trialLabel: trialLabelFor(yearly),
                              comparePrice: ProductOfferInfo.comparePrice(
                                base: monthly,
                                multiplier: 12,
                                storeCountryCode: pricing.storeCountryCode,
                                preferredCurrency: pricing.preferredCurrency,
                                preferredCountryCode:
                                    pricing.preferredCountryCode,
                              ),
                              badge: () {
                                final pct = ProductOfferInfo.yearlySavePercent(
                                  monthly: monthly,
                                  yearly: yearly,
                                  storeCountryCode: pricing.storeCountryCode,
                                  preferredCurrency: pricing.preferredCurrency,
                                  preferredCountryCode:
                                      pricing.preferredCountryCode,
                                );
                                return pct != null
                                    ? tr.proDiscountBadge(pct)
                                    : null;
                              }(),
                              selected: selected?.id == yearly.id,
                              busy: pro.purchasing,
                              onTap: () => setState(() => _selected = yearly),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr.proFeaturesHeading,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: context.isDark
                        ? context.mutedText
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _ProFeaturesCard(features: tr.proFeatureBullets),
              const SizedBox(height: 20),
              if (!showPinnedCta) paywallCta(),
              if (!showPinnedCta) const SizedBox(height: 8),
              ScaledTextButton(
                onPressed: pro.purchasing
                    ? null
                    : () => _restore(context, ref, tr),
                child: Text(tr.proRestore),
              ),
              if (pro.error != null && !showPinnedCta)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorText(tr, pro.error!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                tr.proLegalNotice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: context.faintText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  ScaledTextButton(
                    onPressed: () => openAppLink(context, AppInfo.termsUri),
                    child: Text(tr.termsOfUse),
                  ),
                  ScaledTextButton(
                    onPressed: () =>
                        openAppLink(context, AppInfo.privacyUri),
                    child: Text(tr.privacyPolicy),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const MadeInSpainTagline(),
              if (!pro.loading &&
                  (pro.products.isEmpty || !pro.storeAvailable))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      Text(
                        tr.proStoreEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.faintText,
                        ),
                      ),
                      ScaledTextButton(
                        onPressed: pro.purchasing
                            ? null
                            : () => ref
                                .read(proControllerProvider.notifier)
                                .refresh(),
                        child: Text(tr.retry),
                      ),
                    ],
                  ),
                ),
            ],
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(tr.proDebugUnlock),
                value: pro.debugUnlock,
                onChanged: (v) => ref
                    .read(proControllerProvider.notifier)
                    .setDebugUnlock(v),
              ),
            ],
              ],
            ),
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  floatingControl(
                    icon: LucideIcons.arrowLeft,
                    onTap: closePaywall,
                  ),
                  floatingControl(
                    icon: LucideIcons.x,
                    onTap: closePaywall,
                  ),
                ],
              ),
            ),
            if (showPinnedCta)
              Positioned(
                left: 24,
                right: 24,
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    paywallCta(),
                    if (pro.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText(tr, pro.error!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    Tr tr,
    ProductDetails? product,
  ) async {
    if (ref.read(authUserProvider).valueOrNull == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.proSignInRequired)),
      );
      context.push('/settings/account');
      return;
    }
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.proStoreEmpty)),
      );
      return;
    }
    final ok = await ref.read(proControllerProvider.notifier).buy(product);
    if (!context.mounted) return;
    if (ok && ref.read(proControllerProvider).isPro) {
      Navigator.pop(context);
    }
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Tr tr,
  ) async {
    if (ref.read(authUserProvider).valueOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.proSignInRequired)),
      );
      context.push('/settings/account');
      return;
    }
    final restored =
        await ref.read(proControllerProvider.notifier).restore();
    if (!context.mounted) return;
    final err = ref.read(proControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? tr.proRestoreOk
              : (err?.contains('sign_in_required') == true
                  ? tr.proSignInRequired
                  : tr.proRestoreEmpty),
        ),
      ),
    );
    if (restored) {
      Navigator.pop(context);
    }
  }

  String _ctaLabel(Tr tr, ProductDetails? product) {
    if (product == null) return tr.proGo;
    final days = ProductOfferInfo.trialDaysForPaywall(product);
    if (days != null && days > 0) return tr.proStartFreeTrial;
    return tr.proGo;
  }

  String _errorText(Tr tr, String error) {
    if (error.contains('sign_in_required')) return tr.proSignInRequired;
    return tr.proBuyFailed;
  }
}
