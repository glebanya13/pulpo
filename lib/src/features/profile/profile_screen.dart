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
import 'profile_avatar.dart';
import '../settings/settings_screen.dart' show openNameSheet;
import '../settings/reminder_settings.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../auth/cloud_auth.dart';
import '../auth/cloud_restore_prompt.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';
import '../../widgets/pro_upgrade_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _headerKey = GlobalKey();
  final _scroll = ScrollController();
  double _headerHeight = 56;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _headerHeight).abs() > 0.5 && mounted) {
      setState(() => _headerHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final authUser = ref.watch(authUserProvider).valueOrNull;
    final currency = settings.baseCurrency;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final isPro = ref.watch(proControllerProvider).isPro;

    const side = AppSpacing.lg;
    const headerGap = 16.0;
    final top = MediaQuery.viewPaddingOf(context).top + AppSpacing.xs;
    final bottomClearance = AppSpacing.pushedScrollBottomInset(context);

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final minBody = (constraints.maxHeight -
                      top -
                      _headerHeight -
                      headerGap -
                      bottomClearance)
                  .clamp(0.0, double.infinity);
              return SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  side,
                  top + _headerHeight + headerGap,
                  side,
                  bottomClearance,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minBody),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                            onTap: () => context.push('/settings/export'),
                          ),
                          _MenuRow(
                            icon: LucideIcons.upload,
                            iconBg: const Color(0xFFE0F2FE),
                            label: tr.importCsv,
                            showProMark: !isPro,
                            proLocked: !isPro,
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
                            ? tr.dailyReminderCtaOn(
                                formatReminderTime(
                                  settings.dailyReminderHour,
                                  settings.dailyReminderMinute,
                                ),
                              )
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
                              onTap: () =>
                                  _confirmDeleteAccount(context, ref, tr),
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
                              border:
                                  Border.all(color: context.emphasizedBorder),
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
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(side, top, side, 12),
                child: KeyedSubtree(
                  key: _headerKey,
                  child: _ProfileStickyHeader(
                    onBack: () => context.pop(),
                    userName: settings.userName,
                    subtitle: authUser?.email ??
                        '${tr.accountsCount(accounts.length)} · $currency',
                    localAvatarPath: settings.profileAvatarPath,
                    photoUrl: authUser?.photoURL,
                    onEditTap: () => openNameSheet(context, ref, tr),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStickyHeader extends StatelessWidget {
  const _ProfileStickyHeader({
    required this.onBack,
    required this.userName,
    required this.subtitle,
    required this.localAvatarPath,
    required this.photoUrl,
    required this.onEditTap,
  });

  final VoidCallback onBack;
  final String userName;
  final String subtitle;
  final String? localAvatarPath;
  final String? photoUrl;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final controlBg = context.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : AppColors.ink.withValues(alpha: 0.06);
    const size = PageHeader.controlSize;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: controlBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                size: 18,
                color: context.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ProfileAvatar(
            name: userName,
            localPath: localAvatarPath,
            photoUrl: photoUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: onEditTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: controlBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.pencil,
                size: 16,
                color: context.primaryText,
              ),
            ),
          ),
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
    this.onTap,
    this.danger = false,
    this.showProMark = false,
    this.proLocked = false,
  });
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showProMark;
  final bool proLocked;

  @override
  Widget build(BuildContext context) {
    final labelColor = danger
        ? const Color(0xFFE53E3E)
        : proLocked
            ? proLockedTextColor(context)
            : context.primaryText;
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
            if (showProMark)
              ProIconMark(size: 36, child: iconWell)
            else
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
