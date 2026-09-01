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
import '../../widgets/pressable.dart';
import '../../widgets/common.dart';
import '../../core/open_link.dart';
import '../../core/pro/subscription_links.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                showPinnedCta ? 132 : 32,
              ),
              children: [
            Align(
              alignment: Alignment.centerRight,
              child: Pressable(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: context.primaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                              price: ProductOfferInfo.displayPrice(monthly),
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
                              price: ProductOfferInfo.displayPrice(semiAnnual),
                              allFeaturesLabel: tr.proAllFeatures,
                              trialLabel: trialLabelFor(semiAnnual),
                              comparePrice: ProductOfferInfo.comparePrice(
                                base: monthly,
                                multiplier: 6,
                              ),
                              badge: () {
                                final pct = ProductOfferInfo.semiAnnualSavePercent(
                                  monthly: monthly,
                                  semiAnnual: semiAnnual,
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
                              price: ProductOfferInfo.displayPrice(yearly),
                              allFeaturesLabel: tr.proAllFeatures,
                              trialLabel: trialLabelFor(yearly),
                              comparePrice: ProductOfferInfo.comparePrice(
                                base: monthly,
                                multiplier: 12,
                              ),
                              badge: () {
                                final pct = ProductOfferInfo.yearlySavePercent(
                                  monthly: monthly,
                                  yearly: yearly,
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
                    const SizedBox(height: 10),
                    const MadeInSpainTagline(),
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

class _PaywallPlansSkeleton extends StatelessWidget {
  const _PaywallPlansSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _PaywallPlanSkeleton(hasBadge: i > 0),
        ],
      ],
    );
  }
}

class _PaywallPlanSkeleton extends StatelessWidget {
  const _PaywallPlanSkeleton({this.hasBadge = false});

  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    final fill = context.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF0F0F0);
    return Container(
      height: hasBadge ? 98 : 88,
      padding: EdgeInsets.fromLTRB(16, hasBadge ? 22 : 16, 16, 16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 88,
                  height: 14,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 18,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallProHero extends StatelessWidget {
  const _PaywallProHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4FF00),
            AppColors.lime,
            Color(0xFFF0FF7A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.55),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.rocket, size: 44, color: AppColors.ink),
          const SizedBox(height: 6),
          Text(
            Tr.of(context).proBadge,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProFeaturesCard extends StatelessWidget {
  const _ProFeaturesCard({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 12,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    features[i],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProActiveSection extends ConsumerStatefulWidget {
  const _ProActiveSection({required this.pro});

  final ProState pro;

  @override
  ConsumerState<_ProActiveSection> createState() => _ProActiveSectionState();
}

class _ProActiveSectionState extends ConsumerState<_ProActiveSection> {
  @override
  void initState() {
    super.initState();
    if (widget.pro.subscriptionExpiresAt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(proControllerProvider.notifier).refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final pro = ref.watch(proControllerProvider);
    final expiresAt = pro.subscriptionExpiresAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.badgeCheck, size: 28, color: AppColors.lime),
          const SizedBox(height: 10),
          Text(
            tr.proActive,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          if (expiresAt != null) ...[
            Text(
              tr.proValidUntil(formatProExpiryDate(context, expiresAt)),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: context.primaryText,
              ),
            ),
            if (pro.daysUntilExpiry != null && pro.daysUntilExpiry! <= 14) ...[
              const SizedBox(height: 6),
              Text(
                tr.proDaysLeft(pro.daysUntilExpiry!),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ] else
            Text(
              tr.proExpiresLoading,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaywallPlanCard extends StatelessWidget {
  const _PaywallPlanCard({
    required this.title,
    required this.price,
    required this.allFeaturesLabel,
    required this.onTap,
    this.trialLabel,
    this.badge,
    this.comparePrice,
    this.selected = false,
    this.busy = false,
  });

  final String title;
  final String price;
  final String allFeaturesLabel;
  final String? trialLabel;
  final String? badge;
  final String? comparePrice;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    // На light neon-lime текст на lime-фоне не читается — белая карточка + тёмная рамка.
    final cardFill = selected
        ? (isDark
            ? AppColors.lime.withValues(alpha: 0.18)
            : context.surface)
        : context.surface;
    final cardBorder = selected
        ? (isDark ? AppColors.lime : AppColors.limeAccent)
        : context.divider;
    final secondaryText =
        isDark ? context.mutedText : AppColors.textSecondary;
    final trialColor = selected
        ? (isDark ? AppColors.lime : context.primaryText)
        : context.primaryText;

    return Pressable(
      enabled: !busy,
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(16, badge != null ? 22 : 16, 16, 16),
        decoration: BoxDecoration(
          color: cardFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (badge != null)
              Positioned(
                top: -30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? AppColors.lime : AppColors.limeAccent)
                          : AppColors.ink,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: selected ? AppColors.ink : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.zap,
                            size: 12,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            allFeaturesLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                      if (trialLabel != null && trialLabel!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          trialLabel!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: trialColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                    if (comparePrice != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        comparePrice!,
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: isDark
                              ? context.faintText
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
