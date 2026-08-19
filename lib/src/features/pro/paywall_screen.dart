import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key, this.gate = ProGate.generic});

  final ProGate gate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final pro = ref.watch(proControllerProvider);
    final yearly = pro.yearly;
    final monthly = pro.monthly;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Spacer(),
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.x,
                          size: 18, color: context.primaryText),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  const Center(child: BrandLogo(size: 72)),
                  const SizedBox(height: 16),
                  Text(
                    tr.proTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: context.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.proSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: context.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tr.paywallBody(gate),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                  if (pro.isPro) ...[
                    const SizedBox(height: 20),
                    Text(
                      tr.proActive,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    _PlanCard(
                      title: tr.proYearly,
                      price: yearly?.price ?? '19,99 €',
                      badge: tr.proYearlySave,
                      subtitle: tr.proTrial,
                      highlighted: true,
                      busy: pro.purchasing,
                      onTap: () => _buy(context, ref, tr, yearly),
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      title: tr.proSemiAnnual,
                      price: pro.semiAnnual?.price ?? '12,99 €',
                      subtitle: tr.proTrial,
                      busy: pro.purchasing,
                      onTap: () => _buy(context, ref, tr, pro.semiAnnual),
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      title: tr.proMonthly,
                      price: monthly?.price ?? '2,99 €',
                      subtitle: tr.proTrial,
                      busy: pro.purchasing,
                      onTap: () => _buy(context, ref, tr, monthly),
                    ),
                    const SizedBox(height: 16),
                    ScaledElevatedButton(
                      onPressed: pro.purchasing
                          ? null
                          : () => _buy(context, ref, tr, yearly),
                      child: Text(tr.proGo),
                    ),
                    const SizedBox(height: 8),
                    ScaledTextButton(
                      onPressed: pro.purchasing
                          ? null
                          : () =>
                              ref.read(proControllerProvider.notifier).restore(),
                      child: Text(tr.proRestore),
                    ),
                    if (pro.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          tr.proBuyFailed,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    if (!pro.loading &&
                        pro.storeAvailable &&
                        pro.products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          tr.proStoreEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.faintText,
                          ),
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
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.onTap,
    this.badge,
    this.subtitle,
    this.highlighted = false,
    this.busy = false,
  });

  final String title;
  final String price;
  final String? badge;
  final String? subtitle;
  final bool highlighted;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: !busy,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.lime.withValues(alpha: 0.22)
              : context.surface,
          borderRadius: BorderRadius.circular(20),
          border: highlighted
              ? Border.all(color: AppColors.lime, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
