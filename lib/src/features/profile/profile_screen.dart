import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/app_info.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../export/export_sheet.dart';
import '../settings/settings_screen.dart' show openNameSheet;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../auth/cloud_auth.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final authUser = ref.watch(authUserProvider).valueOrNull;
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
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 120),
      children: [
        // Заголовок
        Text(
          tr.profile,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: context.primaryText,
          ),
        ),
        const SizedBox(height: 12),

        // Аватар + имя
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                    fontSize: 20,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authUser?.email ??
                          '${accounts.length} ${tr.accountsCountLabel} · $currency',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.mutedText,
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
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.pencil,
                      size: 16, color: context.primaryText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Общий баланс
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: context.emphasized,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.emphasizedBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.totalBalance,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(total, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

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
            color: context.surface,
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
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText),
                    ),
                    Text(
                      '$monthCount ${tr.transactionsCount}',
                      style: TextStyle(
                          fontSize: 11, color: context.faintText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _SectionLabel(tr.accountSection),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: LucideIcons.logIn,
              iconBg: const Color(0xFFE0F2FE),
              label: authUser != null ? tr.signedInAs : tr.signIn,
              onTap: () => context.push('/settings/account'),
            ),
            if (authUser != null)
              _MenuRow(
                icon: LucideIcons.logOut,
                iconBg: const Color(0xFFFFE4E6),
                label: tr.signOut,
                onTap: () => ref.read(cloudAuthProvider).signOut(),
              ),
            _MenuRow(
              icon: LucideIcons.shield,
              iconBg: const Color(0xFFD4F5E0),
              label: tr.security,
              onTap: () => context.push('/settings/security'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionLabel(tr.sectionSettings),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: LucideIcons.layers,
              iconBg: const Color(0xFFD4F5E0),
              label: tr.categories,
              onTap: () => context.push('/categories'),
            ),
            _MenuRow(
              icon: LucideIcons.dollarSign,
              iconBg: AppColors.bgFood,
              label: tr.baseCurrency,
              trailing: currency,
              onTap: () => context.push('/settings/currency'),
            ),
            _MenuRow(
              icon: LucideIcons.globe,
              iconBg: const Color(0xFFE0F2FE),
              label: tr.language,
              onTap: () => context.push('/settings/language'),
            ),
            _MenuRow(
              icon: LucideIcons.moon,
              iconBg: const Color(0xFFE8E4FF),
              label: tr.theme,
              trailing: tr.themeLabel(settings.themeMode),
              onTap: () => context.push('/settings/theme'),
            ),
            _MenuRow(
              icon: LucideIcons.database,
              iconBg: const Color(0xFFF2F2F2),
              label: tr.dataBackups,
              onTap: () => context.push('/settings/backups'),
            ),
            _MenuRow(
              icon: LucideIcons.download,
              iconBg: const Color(0xFFFFF3D6),
              label: tr.exportCsv,
              onTap: () => showExportSheet(context, ref),
            ),
            _MenuRow(
              icon: LucideIcons.info,
              iconBg: const Color(0xFFF2F2F2),
              label: tr.about,
              onTap: () => context.push('/settings/about'),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Center(
          child: Text(
            'Pulpo · v${AppInfo.version}',
            style: TextStyle(
              fontSize: 11,
              color: context.faintText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.mutedText,
                      letterSpacing: 0.4,
                    )),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: color,
                    height: 1.2,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.mutedText,
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
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 66, right: 16),
                child: Divider(height: 1, color: context.divider),
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
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.primaryText),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: context.faintText),
          ],
        ),
      ),
    );
  }
}
