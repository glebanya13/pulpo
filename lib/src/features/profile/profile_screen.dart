import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_format.dart';
import '../settings/settings_screen.dart' show openNameSheet;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final total = ref.watch(totalBalanceProvider);
    final currency = settings.baseCurrency;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final txs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];

    // подсчёт статистики
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    var monthIncome = 0.0;
    var monthExpense = 0.0;
    var monthCount = 0;
    for (final t in txs) {
      if (t.date.isBefore(monthStart)) continue;
      final ty = TxType.values[t.type];
      if (ty == TxType.income) monthIncome += t.amount;
      if (ty == TxType.expense) monthExpense += t.amount;
      monthCount++;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
      children: [
        // Заголовок
        Text(
          tr.profile,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 20),

        // Аватар + имя
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.lime, AppColors.limeAccent],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  settings.userName.isNotEmpty
                      ? settings.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${accounts.length} ${tr.accountsCountLabel} · $currency',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => openNameSheet(context, ref, tr),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.pencil,
                      size: 16, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Общий баланс
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.totalBalance,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(total, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Статы этого месяца
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: tr.income.toUpperCase(),
                value: formatMoney(monthIncome, currency),
                color: AppColors.limeAccent,
                icon: LucideIcons.arrowDownRight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: tr.expense.toUpperCase(),
                value: formatMoney(monthExpense, currency),
                color: AppColors.danger,
                icon: LucideIcons.arrowUpRight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgFood,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.calendar,
                    size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('LLLL yyyy',
                              Localizations.localeOf(context).languageCode)
                          .format(now),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink),
                    ),
                    Text(
                      '$monthCount ${tr.transactionsCount}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Быстрые ссылки
        _SectionLabel(tr.management),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: LucideIcons.wallet,
              iconBg: AppColors.bgFood,
              label: tr.accounts,
              trailing: '${accounts.length}',
              onTap: () => context.push('/accounts'),
            ),
            _MenuRow(
              icon: LucideIcons.layers,
              iconBg: const Color(0xFFD4F5E0),
              label: tr.categories,
              onTap: () => context.push('/categories'),
            ),
            _MenuRow(
              icon: LucideIcons.pieChart,
              iconBg: const Color(0xFFFFF3D6),
              label: tr.budgets,
              onTap: () => context.push('/budgets'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionLabel(tr.recurring),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: LucideIcons.repeat,
              iconBg: const Color(0xFFE0F2FE),
              label: tr.recurringOps,
              onTap: () => context.push('/recurring'),
            ),
            _MenuRow(
              icon: LucideIcons.tv,
              iconBg: const Color(0xFFE8E4FF),
              label: tr.subscriptions,
              onTap: () => context.push('/subscriptions'),
            ),
            _MenuRow(
              icon: LucideIcons.users,
              iconBg: const Color(0xFFFFE4E1),
              label: tr.debts,
              onTap: () => context.push('/debts'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionLabel(tr.sectionSettings),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: LucideIcons.settings,
              iconBg: const Color(0xFFF2F2F2),
              label: tr.allSettings,
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Pulpo · v0.1',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 66, right: 16),
                child: Divider(height: 1, color: AppColors.divider),
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
