import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/app_info.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';
import '../../widgets/pro_upgrade_card.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import '../auth/cloud_auth.dart';
import '../settings/reminder_settings.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final isPro = ref.watch(proControllerProvider).isPro;
    final settings = ref.watch(settingsControllerProvider);
    final pro = ref.watch(proControllerProvider);
    final authUser = ref.watch(authUserProvider).valueOrNull;

    return ResetScrollWhenObscured(
      tabPath: '/management',
      preserveScrollOnPush: true,
      builder: (context, scroll) {
        return StickyScrollPage(
          useSafeArea: false,
          controller: scroll,
          padding: AppSpacing.tabPagePadding(context),
          headerGap: 16,
          header: ScreenTitlePill(
            title: tr.management,
            subtitle: tr.managementSubtitle,
            large: true,
            expand: true,
            trailing: const HeaderSupportActions(dense: true),
          ),
          children: [
            ProUpgradeCard(
              title: isPro ? tr.proTitle : tr.proGo,
              subtitle: isPro ? tr.proActive : tr.proCtaSubtitle,
              onTap: () => openPaywall(context, ProGate.generic),
            ),
            const SizedBox(height: 20),

            _SectionLabel(tr.accountSection.toUpperCase()),
            const SizedBox(height: 8),
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
                  _MenuTile(
                    icon: LucideIcons.shield,
                    label: tr.security,
                    color: const Color(0xFF2EB5FF),
                    showPro: false,
                    onTap: () => context.push('/settings/security'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _SectionLabel(tr.sectionFinance),
            const SizedBox(height: 8),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: LucideIcons.wallet,
                    label: tr.accounts,
                    color: const Color(0xFF8BD44A),
                    showPro: false,
                    onTap: () => context.push('/accounts'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.layers,
                    label: tr.categories,
                    color: const Color(0xFFD4F5E0),
                    showPro: false,
                    onTap: () => context.push('/categories'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.pieChart,
                    label: tr.budgets,
                    color: const Color(0xFFFFB020),
                    showPro: false,
                    onTap: () => context.push('/budgets'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.usersRound,
                    label: tr.sharedBudgetTitle,
                    color: const Color(0xFF7C6CFF),
                    showPro: !isPro,
                    onTap: () => context.push('/shared-budget'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.users,
                    label: tr.debts,
                    color: const Color(0xFFFF5C5C),
                    showPro: false,
                    onTap: () => context.push('/debts'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.tv,
                    label: tr.subscriptions,
                    color: const Color(0xFF7C6CFF),
                    showPro: false,
                    onTap: () => context.push('/subscriptions'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.repeat,
                    label: tr.recurringOps,
                    color: const Color(0xFF2EB5FF),
                    showPro: false,
                    onTap: () => context.push('/recurring'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.target,
                    label: tr.goals,
                    color: const Color(0xFFCDFF3A),
                    showPro: false,
                    onTap: () => context.push('/goals'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _SectionLabel(tr.sectionAppSettings),
            const SizedBox(height: 8),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: LucideIcons.globe,
                    label: tr.language,
                    color: const Color(0xFF2EB5FF),
                    showPro: false,
                    onTap: () => context.push('/settings/language'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.dollarSign,
                    label: tr.baseCurrency,
                    color: const Color(0xFFFFB020),
                    showPro: false,
                    trailing: settings.baseCurrency,
                    onTap: () => context.push('/settings/currency'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.moon,
                    label: tr.theme,
                    color: const Color(0xFF8BD44A),
                    showPro: false,
                    trailing: tr.themeLabel(settings.themeMode),
                    onTap: () => context.push('/settings/theme'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.database,
                    label: tr.dataBackups,
                    color: const Color(0xFFD4F5E0),
                    showPro: false,
                    onTap: () => context.push('/settings/backups'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.download,
                    label: tr.exportData,
                    color: const Color(0xFF2EB5FF),
                    showPro: false,
                    onTap: () => context.push('/settings/export'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.upload,
                    label: tr.importCsv,
                    color: const Color(0xFF8BD44A),
                    showPro: !isPro,
                    onTap: () => context.push('/settings/import'),
                  ),
                  Divider(height: 1, color: context.divider),
                  _MenuTile(
                    icon: LucideIcons.info,
                    label: tr.about,
                    color: const Color(0xFFE8E4FF),
                    showPro: false,
                    onTap: () => context.push('/settings/about'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            ReminderCtaButton(
              enabled: settings.dailyReminderEnabled ||
                  (pro.isPro && settings.smartRemindersEnabled),
              title: tr.dailyReminderCta,
              subtitle: settings.dailyReminderEnabled
                  ? tr.dailyReminderCtaOn(formatReminderTime(
                      settings.dailyReminderHour,
                      settings.dailyReminderMinute,
                    ))
                  : tr.dailyReminderCtaOff,
              onTap: () => context.push('/settings/reminders'),
            ),

            if (authUser != null) ...[
              const SizedBox(height: 20),
              SoftCard(
                padding: EdgeInsets.zero,
                child: _MenuTile(
                  icon: LucideIcons.trash2,
                  label: tr.deleteCloudAccount,
                  color: const Color(0xFFFFE4E1),
                  showPro: false,
                  danger: true,
                  onTap: () => context.push('/profile'),
                ),
              ),
              const SizedBox(height: 12),
              Pressable(
                onTap: () => ref.read(cloudAuthProvider).signOut(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: context.emphasized,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.emphasizedBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tr.signOut,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            Text(
              'Monedero · v${AppInfo.version}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.faintText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const MadeInSpainTagline(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: context.mutedText,
        ),
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
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool showPro;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;

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
                  color: danger
                      ? const Color(0xFFE53E3E)
                      : showPro
                          ? proLockedTextColor(context)
                          : context.primaryText,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: TextStyle(fontSize: 13, color: context.mutedText),
              ),
              const SizedBox(width: 4),
            ],
            if (!danger)
              Icon(LucideIcons.chevronRight, size: 16, color: context.faintText),
          ],
        ),
      ),
    );
  }
}
