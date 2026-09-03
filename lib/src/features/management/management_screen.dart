import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';

typedef ManagementMenuItem = (IconData, String, String, Color, bool);

List<ManagementMenuItem> managementMenuItems(Tr tr) => [
      (LucideIcons.wallet, tr.accounts, '/accounts', const Color(0xFF8BD44A), false),
      (LucideIcons.pieChart, tr.budgets, '/budgets', const Color(0xFFFFB020), false),
      (
        LucideIcons.usersRound,
        tr.sharedBudgetTitle,
        '/shared-budget',
        const Color(0xFF7C6CFF),
        true,
      ),
      (LucideIcons.users, tr.debts, '/debts', const Color(0xFFFF5C5C), false),
      (LucideIcons.tv, tr.subscriptions, '/subscriptions', const Color(0xFF7C6CFF), false),
      (LucideIcons.repeat, tr.recurringOps, '/recurring', const Color(0xFF2EB5FF), false),
      (LucideIcons.target, tr.goals, '/goals', const Color(0xFFCDFF3A), false),
      (LucideIcons.layers, tr.categories, '/categories', const Color(0xFFD4F5E0), false),
    ];

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final isPro = ref.watch(proControllerProvider).isPro;
    final items = managementMenuItems(tr);
    final bottomClearance = AppSpacing.tabScrollBottomInset(context);

    return Scaffold(
      body: StickyScrollPage(
        useSafeArea: false,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          MediaQuery.viewPaddingOf(context).top + AppSpacing.xs,
          AppSpacing.lg,
          bottomClearance,
        ),
        headerGap: 16,
        header: PageHeader(
          first: tr.management,
          onBack: () => context.pop(),
        ),
        children: [
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(
                  icon: LucideIcons.user,
                  label: tr.myAccount,
                  color: AppColors.lime,
                  showPro: false,
                  onTap: () => context.push('/profile'),
                ),
                Divider(height: 1, color: context.divider),
                for (var i = 0; i < items.length; i++) ...[
                  _MenuTile(
                    icon: items[i].$1,
                    label: items[i].$2,
                    color: items[i].$4,
                    showPro: items[i].$5 && !isPro,
                    onTap: () => context.push(items[i].$3),
                  ),
                  if (i != items.length - 1)
                    Divider(height: 1, color: context.divider),
                ],
              ],
            ),
          ),
          if (!isPro) ...[
            const SizedBox(height: 16),
            Pressable(
              onTap: () => openPaywall(context, ProGate.generic),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
                      color: AppColors.lime.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.rocket,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr.proGo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.ink.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.showPro,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool showPro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWell = ColorWellIcon(
      color: color,
      icon: icon,
      size: 36,
      iconSize: 18,
      radius: 12,
    );
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (showPro) ProIconMark(size: 36, child: iconWell) else iconWell,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: showPro
                      ? proLockedTextColor(context)
                      : context.primaryText,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: context.faintText),
          ],
        ),
      ),
    );
  }
}
