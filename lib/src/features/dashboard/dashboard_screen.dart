import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/pressable.dart';
import '../../widgets/common.dart';
import '../../widgets/pro_badge.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/money_format.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../core/pro/pro_controller.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import 'monthly_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final total = ref.watch(totalBalanceProvider);
    final currency = settings.baseCurrency;
    final fxApprox = ref.watch(fxApproximateProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final txsAsync = ref.watch(allTransactionsProvider);

    void retryBalance() {
      ref.invalidate(accountsProvider);
      ref.invalidate(allTransactionsProvider);
    }

    return ResetScrollWhenObscured(
      tabPath: '/',
      builder: (context, scroll) {
        final pad = AppSpacing.tabPagePadding(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, 10),
                child: ScreenTitlePill(
                  title: settings.userName,
                  eyebrow: tr.greetingForHour(DateTime.now().hour),
                  large: true,
                  expand: true,
                  trailing: const HeaderSupportActions(dense: true),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                children: [
                  AsyncValuesGate(
                    values: [accountsAsync, txsAsync],
                    onRetry: retryBalance,
                    child: _BalanceCard(
                      total: total,
                      currency: currency,
                      fxApproximate: fxApprox.isNotEmpty,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    children: [
                      Row(
                        children: [
                          _QuickChip(
                            icon: LucideIcons.plus,
                            label: tr.income,
                            onTap: () => context.push('/add?type=income'),
                          ),
                          const SizedBox(width: 6),
                          _QuickChip(
                            icon: LucideIcons.minus,
                            label: tr.expense,
                            onTap: () => context.push('/add?type=expense'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _QuickChip(
                            icon: LucideIcons.arrowLeftRight,
                            label: tr.transferBetweenAccounts,
                            onTap: () => context.push('/add?type=transfer'),
                          ),
                          const SizedBox(width: 6),
                          _QuickChip(
                            icon: LucideIcons.send,
                            label: tr.transferExternal,
                            onTap: () =>
                                context.push('/add?type=expense&mode=external'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _HomeLinks(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr.calendar,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.primaryText,
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: () => context.go('/transactions'),
                        child: Text(
                          tr.viewHistory,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.limeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 6),
                  const MonthlyCalendar(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: context.primaryText),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: context.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.total,
    required this.currency,
    this.fxApproximate = false,
  });
  final double total;
  final String currency;
  final bool fxApproximate;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: context.emphasized,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.emphasizedBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            tr.totalBalance,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(total, currency),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          if (fxApproximate) ...[
            const SizedBox(height: 6),
            Text(
              tr.fxApproximateBalance,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeLinks extends ConsumerWidget {
  const _HomeLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final isPro = ref.watch(proControllerProvider).isPro;
    final items = [
      (LucideIcons.wallet, tr.accounts, '/accounts', const Color(0xFF8BD44A), false),
      (LucideIcons.pieChart, tr.budgets, '/budgets', const Color(0xFFFFB020), false),
      (LucideIcons.usersRound, tr.sharedBudgetTitle, '/shared-budget', const Color(0xFF7C6CFF), true),
      (LucideIcons.users, tr.debts, '/debts', const Color(0xFFFF5C5C), false),
      (LucideIcons.tv, tr.subscriptions, '/subscriptions', const Color(0xFF7C6CFF), false),
      (LucideIcons.repeat, tr.recurringOps, '/recurring', const Color(0xFF2EB5FF), false),
      (LucideIcons.target, tr.goals, '/goals', const Color(0xFFCDFF3A), false),
      (LucideIcons.layers, tr.categories, '/categories', const Color(0xFFD4F5E0), false),
    ];
    Widget tile((IconData, String, String, Color, bool) i) {
      final showPro = i.$5 && !isPro;
      final iconWell = ColorWellIcon(
        color: i.$4,
        icon: i.$1,
        size: 26,
        iconSize: 14,
        radius: 8,
      );
      return Pressable(
        onTap: () => context.push(i.$3),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (showPro)
                ProIconMark(size: 26, child: iconWell)
              else
                iconWell,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i.$2,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: showPro
                        ? proLockedTextColor(context)
                        : context.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: tile(items[0])),
            const SizedBox(width: 6),
            Expanded(child: tile(items[1])),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: tile(items[2])),
            const SizedBox(width: 6),
            Expanded(child: tile(items[3])),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: tile(items[4])),
            const SizedBox(width: 6),
            Expanded(child: tile(items[5])),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: tile(items[6])),
            const SizedBox(width: 6),
            Expanded(child: tile(items[7])),
          ],
        ),
      ],
    );
  }
}
