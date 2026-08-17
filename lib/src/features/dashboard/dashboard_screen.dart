import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

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
    final net = income - expense;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 130),
      children: [
        Row(
          children: [
            Image.asset('assets/logo.png',
                height: 32, filterQuality: FilterQuality.high),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.greetingMorning,
                    style: TextStyle(fontSize: 13, color: context.mutedText),
                  ),
                  Text(
                    settings.userName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: context.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BalanceCard(total: total, currency: currency),
        const SizedBox(height: 6),
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
            const SizedBox(width: 6),
            _QuickChip(
              icon: LucideIcons.arrowLeftRight,
              label: tr.transferBetweenAccounts,
              onTap: () => context.push('/transfer'),
            ),
            const SizedBox(width: 6),
            _QuickChip(
              icon: LucideIcons.send,
              label: tr.transferExternal,
              onTap: () => context.push('/add?type=expense&mode=external'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _MonthBalance(
          income: income,
          expense: expense,
          net: net,
          currency: currency,
        ),
        const SizedBox(height: 6),
        _HomeLinks(),
        const SizedBox(height: 10),
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
            GestureDetector(
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
        const SizedBox(height: 6),
        const MonthlyCalendar(),
      ],
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: context.primaryText),
              const SizedBox(height: 4),
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
  const _BalanceCard({required this.total, required this.currency});
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: context.emphasized,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.emphasizedBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.totalBalance,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBalance extends StatelessWidget {
  const _MonthBalance({
    required this.income,
    required this.expense,
    required this.net,
    required this.currency,
  });
  final double income;
  final double expense;
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Mini(
              label: tr.income,
              value: formatMoney(income, currency),
              color: AppColors.limeAccent),
          Container(width: 1, height: 28, color: context.divider),
          _Mini(
              label: tr.expense,
              value: formatMoney(expense, currency),
              color: AppColors.danger),
          Container(width: 1, height: 28, color: context.divider),
          _Mini(
              label: tr.monthNet,
              value: formatMoney(net, currency),
              color: context.primaryText),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: context.mutedText)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final items = [
      (LucideIcons.wallet, tr.accounts, '/accounts', AppColors.bgFood),
      (LucideIcons.pieChart, tr.budgets, '/budgets', const Color(0xFFFFF3D6)),
      (LucideIcons.repeat, tr.recurringOps, '/recurring', const Color(0xFFE0F2FE)),
      (LucideIcons.tv, tr.subscriptions, '/subscriptions', const Color(0xFFE8E4FF)),
      (LucideIcons.users, tr.debts, '/debts', const Color(0xFFFFE4E1)),
    ];
    Widget tile((IconData, String, String, Color) i) {
      return GestureDetector(
        onTap: () => context.push(i.$3),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: i.$4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(i.$1, size: 14, color: AppColors.ink),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
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
        tile(items[4]),
      ],
    );
  }
}
