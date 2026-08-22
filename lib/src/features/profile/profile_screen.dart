import 'package:firebase_auth/firebase_auth.dart';
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
import '../settings/settings_screen.dart' show openNameSheet;
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../auth/cloud_auth.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final authUser = ref.watch(authUserProvider).valueOrNull;
    final currency = settings.baseCurrency;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final isPro = ref.watch(proControllerProvider).isPro;

    return Scaffold(
      body: SafeArea(
        child: ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        PageHeader(
          first: tr.profile,
          onBack: () => context.pop(),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _ProfileAvatar(
                name: settings.userName,
                photoUrl: authUser?.photoURL,
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
                          '${tr.accountsCount(accounts.length)} · $currency',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
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
        const SizedBox(height: 20),

        _SectionLabel(tr.sectionSettings),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: LucideIcons.sparkles,
              iconBg: AppColors.lime.withValues(alpha: 0.4),
              label: tr.proTitle,
              trailing: isPro ? tr.proActiveShort : tr.proGo,
              onTap: () => openPaywall(context, ProGate.generic),
            ),
            if (authUser == null)
              _MenuRow(
                icon: LucideIcons.logIn,
                iconBg: const Color(0xFFE0F2FE),
                label: tr.signIn,
                onTap: () => context.push('/settings/account'),
              ),
            _MenuRow(
              icon: LucideIcons.shield,
              iconBg: const Color(0xFFD4F5E0),
              label: tr.security,
              onTap: () => context.push('/settings/security'),
            ),
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
              label: tr.themeDarkMode,
              subtitle: tr.themeDarkHint,
              trailingWidget: Switch.adaptive(
                value: context.isDark,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) => ref
                    .read(settingsControllerProvider.notifier)
                    .setTheme(v ? 'dark' : 'light'),
              ),
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
              onTap: () => context.push('/settings/export'),
            ),
            _MenuRow(
              icon: LucideIcons.upload,
              iconBg: const Color(0xFFE0F2FE),
              label: tr.importCsv,
              proLocked: !isPro,
              onTap: () async {
                final ok = await requirePro(context, ref, ProGate.importCsv);
                if (!ok || !context.mounted) return;
                context.push('/settings/import');
              },
            ),
            _MenuRow(
              icon: LucideIcons.info,
              iconBg: const Color(0xFFF2F2F2),
              label: tr.about,
              onTap: () => context.push('/settings/about'),
            ),
          ],
        ),
        if (authUser != null) ...[
          const SizedBox(height: 28),
          _MenuGroup(
            children: [
              _MenuRow(
                icon: LucideIcons.trash2,
                iconBg: const Color(0xFFFFE4E1),
                label: tr.deleteCloudAccount,
                danger: true,
                onTap: () => _confirmDeleteAccount(context, ref, tr),
              ),
            ],
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
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Monedero · v${AppInfo.version}',
            style: TextStyle(
              fontSize: 11,
              color: context.faintText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(tr.deleteCloudAccountTitle),
      content: Text(tr.deleteCloudAccountBody),
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
  try {
    await ref.read(cloudAuthProvider).deleteCloudAccount();
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'requires-recent-login'
              ? tr.deleteCloudAccountRelogin
              : tr.deleteCloudAccountFailed,
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.deleteCloudAccountFailed)),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, this.photoUrl});
  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    Widget fallback() => Container(
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
            letter,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) return fallback();

    return ClipOval(
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback();
        },
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
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.onTap,
    this.danger = false,
    this.proLocked = false,
  });
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool danger;
  final bool proLocked;

  @override
  Widget build(BuildContext context) {
    final labelColor = proLocked
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
    return Pressable(
      enabled: onTap != null,
      onTap: onTap ?? () {},
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (proLocked) ProIconMark(child: iconWell) else iconWell,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: proLocked
                            ? proLockedMutedColor(context)
                            : context.faintText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 13,
                    color: proLocked
                        ? proLockedMutedColor(context)
                        : context.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (trailingWidget != null) trailingWidget!,
            if (onTap != null && !danger)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: proLocked
                    ? proLockedMutedColor(context)
                    : context.faintText,
              ),
          ],
        ),
      ),
    );
  }
}
