import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/app_info.dart';
import '../../core/currencies.dart';
import '../../core/l10n/tr.dart';
import '../../core/open_link.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/seed/seed_categories.dart';
import '../../widgets/common.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';
import '../../widgets/reset_scroll_when_obscured.dart';
import '../auth/cloud_auth.dart';
import 'reminder_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final pro = ref.watch(proControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ResetScrollWhenObscured(
          tabPath: '/settings',
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(
              first: tr.settings,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 20),

            if (!pro.isPro)
              _ProUpgradeCard(
                title: tr.proGo,
                subtitle: tr.proCtaSubtitle,
                onTap: () => openPaywall(context, ProGate.generic),
              ),
            if (!pro.isPro) const SizedBox(height: 12),

            _Section(
              children: [
                _SettingsRow(
                  icon: LucideIcons.user,
                  iconBg: const Color(0xFFD4F5E0),
                  title: tr.name,
                  subtitle: tr.shownInApp,
                  trailing: settings.userName,
                  onTap: () => _openEditName(context, ref, tr),
                ),
                _SettingsRow(
                  icon: LucideIcons.shield,
                  iconBg: const Color(0xFFE0F2FE),
                  title: tr.security,
                  onTap: () => context.push('/settings/security'),
                ),
                _SettingsRow(
                  icon: LucideIcons.dollarSign,
                  iconBg: AppColors.bgFood,
                  title: tr.baseCurrency,
                  subtitle: tr.forTotalsReports,
                  trailing: '${currencyForCountry(settings.baseCurrencyCountry)?.localizedCountry(settings.locale) ?? settings.baseCurrencyCountry} · ${settings.baseCurrency}',
                  onTap: () => context.push('/settings/currency'),
                ),
                _SettingsRow(
                  icon: LucideIcons.globe,
                  iconBg: const Color(0xFFE0F2FE),
                  title: tr.language,
                  subtitle: tr.interfaceLanguage,
                  trailing: _langLabel(settings.locale),
                  onTap: () => context.push('/settings/language'),
                ),
                _SettingsRow(
                  icon: LucideIcons.moon,
                  iconBg: const Color(0xFFE8E4FF),
                  title: tr.themeDarkMode,
                  subtitle: tr.themeDarkHint,
                  trailingWidget: Switch.adaptive(
                    value: context.isDark,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .setTheme(v ? 'dark' : 'light'),
                  ),
                ),
                _SettingsRow(
                  icon: LucideIcons.bellRing,
                  iconBg: AppColors.lime.withValues(alpha: 0.35),
                  title: tr.smartReminders,
                  subtitle: tr.smartRemindersHint,
                  proLocked: !pro.isPro,
                  trailingWidget: Switch.adaptive(
                    value: settings.smartRemindersEnabled,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) =>
                        toggleSmartReminders(context, ref, tr, v),
                  ),
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReminderCtaButton(
              enabled: settings.dailyReminderEnabled,
              title: tr.dailyReminderCta,
              subtitle: settings.dailyReminderEnabled
                  ? tr.dailyReminderCtaOn(formatReminderTime(
                      settings.dailyReminderHour,
                      settings.dailyReminderMinute,
                    ))
                  : tr.dailyReminderCtaOff,
              onTap: () => openReminderSheet(context, ref, tr),
            ),
            const SizedBox(height: 12),

            _Section(
              children: [
                _SettingsRow(
                  icon: LucideIcons.layers,
                  iconBg: const Color(0xFFD4F5E0),
                  title: tr.categories,
                  onTap: () => context.push('/categories'),
                ),
                _SettingsRow(
                  icon: LucideIcons.database,
                  iconBg: const Color(0xFFF2F2F2),
                  title: tr.dataBackups,
                  onTap: () => context.push('/settings/backups'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _Section(
              children: [
                _SettingsRow(
                  icon: LucideIcons.info,
                  iconBg: const Color(0xFFF2F2F2),
                  title: tr.about,
                  subtitle: '${tr.version} ${AppInfo.version}',
                  onTap: () => context.push('/settings/about'),
                ),
                _SettingsRow(
                  icon: LucideIcons.shield,
                  iconBg: const Color(0xFFE0F2FE),
                  title: tr.privacyPolicy,
                  onTap: () => openAppLink(context, AppInfo.privacyUri),
                ),
                _SettingsRow(
                  icon: LucideIcons.fileText,
                  iconBg: const Color(0xFFFFF3D6),
                  title: tr.termsOfUse,
                  onTap: () => openAppLink(context, AppInfo.termsUri),
                ),
                _SettingsRow(
                  icon: LucideIcons.lifeBuoy,
                  iconBg: const Color(0xFFD4F5E0),
                  title: tr.contactSupport,
                  onTap: () => openAppLink(context, AppInfo.supportUri),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _Section(
              children: [
                _SettingsRow(
                  icon: LucideIcons.trash2,
                  iconBg: const Color(0xFFFFE4E1),
                  title: tr.resetAllData,
                  subtitle: tr.resetAllDataSubtitle,
                  danger: true,
                  onTap: () => _confirmReset(context, ref, tr),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                tr.offlineFirstTag,
                style: TextStyle(
                  color: context.faintText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _langLabel(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }

  Future<void> _openEditName(
      BuildContext context, WidgetRef ref, Tr tr) async {
    await openNameSheet(context, ref, tr);
  }

  Future<void> _confirmReset(
      BuildContext context, WidgetRef ref, Tr tr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.resetAllDataTitle),
        content: Text(tr.resetAllDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53E3E),
            ),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    await db.resetAllData();
    await seedCategoriesIfEmpty(db);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr.resetSuccess)));
      context.go('/');
    }
  }
}

class _ProUpgradeCard extends StatelessWidget {
  const _ProUpgradeCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.limeDark,
              AppColors.lime,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.lime.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.rocket,
                size: 22,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink.withValues(alpha: 0.7),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.ink.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openNameSheet(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
) async {
  final current = ref.read(settingsControllerProvider).userName;
  final ctrl = TextEditingController(text: current);
  ctrl.selection =
      TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);

  await showAppBottomSheet(
    context: context,
    transparent: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.24)
                        : const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ctx.wellBg(const Color(0xFFD4F5E0)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(LucideIcons.user,
                        color: ctx.wellFg(const Color(0xFFD4F5E0))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.yourName,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(ctx).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr.howToCall,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx).colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(ctx).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    hintText: tr.enterName,
                    hintStyle: TextStyle(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                        fontSize: 15),
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(ctx).dividerColor, width: 1.5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tr.cancel,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(ctx).colorScheme.onSurface),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Pressable(
                      onTap: () async {
                        final name = ctrl.text.trim();
                        if (name.isEmpty) return;
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .setUserName(name);
                        await ref
                            .read(cloudAuthProvider)
                            .updateDisplayName(name);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tr.save,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
    this.proLocked = false,
  });
  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;
  final bool proLocked;

  @override
  Widget build(BuildContext context) {
    final titleColor = proLocked
        ? proLockedTextColor(context, danger: danger)
        : (danger ? const Color(0xFFE53E3E) : context.primaryText);
    final iconWell = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.wellBg(iconBg),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 18,
        color: context.wellFg(iconBg).withValues(alpha: proLocked ? 0.55 : 1),
      ),
    );
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              enabled: onTap != null,
              onTap: onTap,
              scale: 0.98,
              child: Row(
                children: [
                  if (proLocked) ProIconMark(child: iconWell) else iconWell,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: titleColor)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: proLocked
                                      ? proLockedMutedColor(context)
                                      : context.faintText)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(trailing!,
                          style: TextStyle(
                              fontSize: 13,
                              color: proLocked
                                  ? proLockedMutedColor(context)
                                  : context.mutedText)),
                    ),
                  if (onTap != null && !danger && showChevron)
                    Icon(LucideIcons.chevronRight,
                        size: 16,
                        color: proLocked
                            ? proLockedMutedColor(context)
                            : context.faintText),
                ],
              ),
            ),
          ),
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
    return row;
  }
}
