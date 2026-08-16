import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import 'monthly_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final total = ref.watch(totalBalanceProvider);
    final currency = settings.baseCurrency;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final monthTxs = ref
            .watch(transactionsInRangeProvider(
                (start: monthStart, end: monthEnd)))
            .valueOrNull ??
        const [];

    var income = 0.0;
    var expense = 0.0;
    for (final t in monthTxs) {
      final type = TxType.values[t.type];
      if (type == TxType.income) income += t.amount;
      if (type == TxType.expense) expense += t.amount;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.greetingMorning,
                    style: TextStyle(fontSize: 13, color: context.mutedText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _BalanceCard(total: total, currency: currency),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: tr.income,
                value: formatMoney(income, currency),
                icon: LucideIcons.arrowDownRight,
                iconBg: AppColors.bgFood,
                barColor: AppColors.lime,
                progress: 0.8,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: tr.expense,
                value: formatMoney(expense, currency),
                icon: LucideIcons.arrowUpRight,
                iconBg: const Color(0xFFFFE4E1),
                barColor: AppColors.danger,
                progress: 0.56,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr.calendar,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.primaryText,
              ),
            ),
            _HistoryPill(
              label: tr.viewHistory,
              onTap: () => context.go('/transactions'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const MonthlyCalendar(),
      ],
    );
  }
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lime,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.total, required this.currency});
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.emphasized,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.emphasizedBorder, width: 1),
        boxShadow: context.isDark
            ? [
                BoxShadow(
                  color: AppColors.lime.withValues(alpha: 0.06),
                  blurRadius: 32,
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.totalBalance,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(total, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => Row(
              children: [
                Expanded(
                  child: _QuickBtn(
                    label: tr.income,
                    filled: true,
                    onTap: () => context.push('/add?type=income'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickBtn(
                    label: tr.transfer,
                    filled: false,
                    onTap: () => context.push('/transfer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? AppColors.lime : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          (filled ? '+ ' : '− ') + label,
          style: TextStyle(
            color: filled ? AppColors.ink : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.barColor,
    required this.progress,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color barColor;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 16,
                color: context.isDark ? Colors.white : AppColors.ink),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: context.mutedText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
