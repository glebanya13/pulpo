import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import 'profile_avatar.dart' show ProfileAvatar, openProfileAvatarSheet;
import '../settings/settings_screen.dart' show openNameSheet;
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
    final isPro = ref.watch(proControllerProvider).isPro;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: LucideIcons.arrowLeft,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ScreenTitlePill(
                      title: tr.myProfile,
                      subtitle: tr.personalData,
                      large: true,
                      expand: true,
                      trailing: const WhatsAppSupportChip(dense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AvatarSection(
                settings: settings,
                authUser: authUser,
                tr: tr,
                ref: ref,
              ),
              const SizedBox(height: 14),
              _FormGroup(
                children: [
                  _FormRow(
                    label: tr.firstName,
                    value: settings.userName,
                    onTap: () => openNameSheet(context, ref, tr),
                  ),
                  _FormRow(
                    label: tr.lastName,
                    value: settings.lastName,
                    onTap: () =>
                        _editLastName(context, ref, tr, settings.lastName),
                  ),
                ],
              ),
              if (authUser != null) ...[
                const SizedBox(height: 10),
                _FormGroup(
                  children: [
                    _FormRow(
                      label: 'Email',
                      value: authUser.email ?? '',
                      readOnly: true,
                      valueFull: true,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              _FormGroup(
                children: [
                  _FormRow(
                    label: tr.birthday,
                    value: _formatBirthday(
                      context,
                      settings.birthday,
                    ),
                    placeholder: tr.notSpecified,
                    onTap: () =>
                        _editBirthday(context, ref, tr, settings.birthday),
                  ),
                  _FormRow(
                    label: tr.gender,
                    value: _genderLabel(tr, settings.gender),
                    placeholder: tr.notSpecified,
                    onTap: () =>
                        _editGender(context, ref, tr, settings.gender),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ProUpgradeCard(
                title: isPro ? tr.proTitle : tr.proGo,
                subtitle: isPro ? tr.proActive : tr.proCtaSubtitle,
                onTap: () => openPaywall(context, ProGate.generic),
              ),
              if (authUser == null) ...[
                const SizedBox(height: 14),
                _FormGroup(
                  children: [
                    _FormRow(
                      label: tr.signIn,
                      onTap: () => context.push('/settings/account'),
                      leading: LucideIcons.logIn,
                      leadingColor: const Color(0xFFE0F2FE),
                    ),
                  ],
                ),
              ],
              if (authUser != null) ...[
                const SizedBox(height: 14),
                _FormGroup(
                  children: [
                    _FormRow(
                      label: tr.deleteCloudAccount,
                      onTap: () => _confirmDeleteAccount(context, ref, tr),
                      leading: LucideIcons.trash2,
                      leadingColor: const Color(0xFFFFE4E1),
                      danger: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Pressable(
                  onTap: () => ref.read(cloudAuthProvider).signOut(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
              const SizedBox(height: 12),
              const MadeInSpainTagline(),
            ],
          ),
        ),
      ),
    );
  }
}

String? _formatBirthday(BuildContext context, String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final parts = raw.split('-');
    if (parts.length != 3) return raw;
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  } catch (_) {
    return raw;
  }
}

String _genderLabel(Tr tr, String? gender) {
  switch (gender) {
    case 'male':
      return tr.male;
    case 'female':
      return tr.female;
    default:
      return '';
  }
}

Future<void> _editLastName(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
  String? current,
) async {
  final controller = TextEditingController(text: current ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(tr.lastName),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: tr.lastName),
        onSubmitted: (v) => Navigator.pop(dctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx),
          child: Text(tr.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dctx, controller.text.trim()),
          child: Text(tr.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || !context.mounted) return;
  await ref.read(settingsControllerProvider.notifier).setLastName(
        result.isEmpty ? null : result,
      );
}

Future<void> _editBirthday(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
  String? current,
) async {
  DateTime initial = DateTime.now();
  if (current != null) {
    try {
      final parts = current.split('-');
      if (parts.length == 3) {
        initial = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
  }

  DateTime? picked = initial;
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (pctx) => Container(
      height: 300,
      color: pctx.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: Text(tr.cancel),
                onPressed: () {
                  picked = null;
                  Navigator.pop(pctx);
                },
              ),
              CupertinoButton(
                child: Text(tr.save),
                onPressed: () => Navigator.pop(pctx),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial,
              maximumDate: DateTime.now(),
              minimumYear: 1900,
              onDateTimeChanged: (d) => picked = d,
            ),
          ),
        ],
      ),
    ),
  );

  if (picked == null || !context.mounted) return;
  final formatted =
      '${picked!.year}-${picked!.month.toString().padLeft(2, '0')}-${picked!.day.toString().padLeft(2, '0')}';
  await ref.read(settingsControllerProvider.notifier).setBirthday(formatted);
}

Future<void> _editGender(
  BuildContext context,
  WidgetRef ref,
  Tr tr,
  String? current,
) async {
  final result = await showCupertinoModalPopup<String?>(
    context: context,
    builder: (pctx) => CupertinoActionSheet(
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(pctx, 'male'),
          isDefaultAction: current == 'male',
          child: Text(tr.male),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(pctx, 'female'),
          isDefaultAction: current == 'female',
          child: Text(tr.female),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(pctx, ''),
          child: Text(tr.notSpecified),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(pctx),
        child: Text(tr.cancel),
      ),
    ),
  );

  if (result == null || !context.mounted) return;
  await ref.read(settingsControllerProvider.notifier).setGender(
        result.isEmpty ? null : result,
      );
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.settings,
    required this.authUser,
    required this.tr,
    required this.ref,
  });

  final SettingsState settings;
  final dynamic authUser;
  final Tr tr;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ProfileAvatar(
            name: authUser != null ? settings.userName : tr.guestName,
            localPath: settings.profileAvatarPath,
            photoUrl: authUser?.photoURL as String?,
            size: 72,
          ),
          const SizedBox(height: 8),
          Pressable(
            onTap: () => openProfileAvatarSheet(context, ref),
            child: Text(
              tr.editPhoto,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.lime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormGroup extends StatelessWidget {
  const _FormGroup({required this.children});
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
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, color: context.divider),
              ),
          ],
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    this.value,
    this.placeholder,
    this.onTap,
    this.readOnly = false,
    this.danger = false,
    this.leading,
    this.leadingColor,
    this.valueFull = false,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool danger;
  final IconData? leading;
  final Color? leadingColor;
  final bool valueFull;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        danger ? const Color(0xFFE53E3E) : context.primaryText;
    final displayValue = (value != null && value!.isNotEmpty)
        ? value!
        : (placeholder ?? '');
    final well = leadingColor;

    return Pressable(
      enabled: onTap != null,
      onTap: onTap ?? () {},
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null && well != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.wellBg(well),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  leading,
                  size: 16,
                  color: context.wellFg(well),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (valueFull) ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayValue,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    color: (value == null || value!.isEmpty)
                        ? context.faintText
                        : context.mutedText,
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
              if (displayValue.isNotEmpty)
                Flexible(
                  child: Text(
                    displayValue,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: (value == null || value!.isEmpty)
                          ? context.faintText
                          : context.mutedText,
                    ),
                  ),
                ),
              if (!readOnly && !danger) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight,
                    size: 16, color: context.faintText),
              ],
            ],
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
  if (confirmed != true || !context.mounted) return;

  final cloud = ref.read(cloudAuthProvider);
  final provider = cloud.primaryAuthProviderId();

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
