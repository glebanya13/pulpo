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
import '../settings/reminder_settings.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../auth/cloud_auth.dart';
import '../auth/cloud_restore_prompt.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_upgrade_card.dart';

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
      body: StickyScrollPage(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        headerGap: 16,
        header: PageHeader(
          first: tr.profile,
          onBack: () => context.pop(),
        ),
        children: [

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

        if (!isPro) ...[
          ProUpgradeCard(
            title: tr.proGo,
            subtitle: tr.proCtaSubtitle,
            onTap: () => openPaywall(context, ProGate.generic),
          ),
          const SizedBox(height: 20),
        ] else ...[
          ProUpgradeCard(
            title: tr.proTitle,
            subtitle: tr.proActive,
            onTap: () => openPaywall(context, ProGate.generic),
          ),
          const SizedBox(height: 20),
        ],

        _SectionLabel(tr.sectionSettings),
        _MenuGroup(
          children: [
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
              label: tr.theme,
              subtitle: tr.themeLabel(settings.themeMode),
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
              onTap: () => context.push('/settings/export'),
            ),
            _MenuRow(
              icon: LucideIcons.upload,
              iconBg: const Color(0xFFE0F2FE),
              label: tr.importCsv,
              onTap: () => context.push('/settings/import'),
            ),
            _MenuRow(
              icon: LucideIcons.info,
              iconBg: const Color(0xFFF2F2F2),
              label: tr.about,
              onTap: () => context.push('/settings/about'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReminderCtaButton(
          enabled: settings.dailyReminderEnabled ||
              (isPro && settings.smartRemindersEnabled),
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
  if (confirmed != true || !context.mounted) return;

  final cloud = ref.read(cloudAuthProvider);
  final provider = cloud.primaryAuthProviderId();

  // Soft notice before Apple/Google sheet or password prompt.
  if (provider == 'apple.com' || provider == 'google.com') {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.deleteCloudAccountTitle),
        content: Text(tr.deleteCloudConfirmIdentity),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(tr.confirm),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;
  }

  String? password;
  if (provider == 'password') {
    password = await _askDeletePassword(context, tr);
    if (password == null || !context.mounted) return;
  }

  try {
    await cloud.deleteCloudAccount(emailPassword: password);
    if (!context.mounted) return;
    final wipeLocal = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.deleteCloudAccountTitle),
        content: Text(tr.deleteCloudResetLocal),
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
    if (wipeLocal == true && context.mounted) {
      await ref.read(databaseProvider).resetAllData();
      refreshUiAfterMoneyRestore(ref);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.deleteCloudAccountOk)),
    );
    context.go('/');
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_deleteAccountError(tr, e))),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.deleteCloudAccountFailed)),
    );
  }
}

String _deleteAccountError(Tr tr, FirebaseAuthException e) {
  switch (e.code) {
    case 'canceled':
    case 'aborted':
      return tr.authCanceled;
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return tr.authWrongPassword;
    case 'requires-recent-login':
    case 'password-required':
    case 'no-reauth-provider':
      return tr.deleteCloudAccountRelogin;
    default:
      return tr.deleteCloudAccountFailed;
  }
}

Future<String?> _askDeletePassword(BuildContext context, Tr tr) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(tr.deleteCloudAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.deleteCloudEnterPassword),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: tr.password),
            onSubmitted: (v) => Navigator.pop(dctx, v.trim()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx),
          child: Text(tr.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dctx, controller.text.trim()),
          child: Text(tr.confirm),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
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

    return SizedBox(
      width: 48,
      height: 48,
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          _avatarPhotoUrl(url),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return fallback();
          },
        ),
      ),
    );
  }
}

/// Google profile URLs need an explicit square crop (`sNNN-c`), otherwise
/// the photo may letterbox or look uncropped inside a circle.
String _avatarPhotoUrl(String url) {
  var u = url.trim();
  if (!u.contains('googleusercontent.com')) return u;
  u = u
      .replaceAll(RegExp(r'=s\d+-c?\b'), '=s256-c')
      .replaceAll(RegExp(r'/s\d+-c?/'), '/s256-c/');
  if (!RegExp(r'[=/]s\d').hasMatch(u)) {
    u = u.contains('?') ? '$u&sz=256' : '$u=s256-c';
  }
  return u;
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
    this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        danger ? const Color(0xFFE53E3E) : context.primaryText;
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
        color: context.wellFg(iconBg),
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
            iconWell,
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
                        color: context.faintText,
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
                    color: context.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (onTap != null && !danger)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: context.faintText,
              ),
          ],
        ),
      ),
    );
  }
}
