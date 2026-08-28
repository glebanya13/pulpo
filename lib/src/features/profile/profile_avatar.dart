import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/pressable.dart';
import '../auth/cloud_auth.dart';

const _avatarSize = 48.0;
const _avatarFileName = 'profile_avatar.jpg';

Future<File> profileAvatarFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, _avatarFileName));
}

Future<void> openProfileAvatarSheet(BuildContext context, WidgetRef ref) async {
  final tr = Tr.of(context);
  final settings = ref.read(settingsControllerProvider);
  final hasLocal = _localAvatarExists(settings.profileAvatarPath);
  final hasRemote =
      (ref.read(authUserProvider).valueOrNull?.photoURL?.trim().isNotEmpty ??
          false);

  final action = await showModalBottomSheet<_AvatarSheetAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.image),
            title: Text(tr.profileAvatarChoose),
            onTap: () => Navigator.pop(ctx, _AvatarSheetAction.choose),
          ),
          if (hasLocal || hasRemote)
            ListTile(
              leading: Icon(
                LucideIcons.trash2,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                tr.profileAvatarRemove,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.pop(ctx, _AvatarSheetAction.remove),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case _AvatarSheetAction.choose:
      await _pickAndApplyAvatar(context, ref);
    case _AvatarSheetAction.remove:
      await _removeAvatar(context, ref);
  }
}

enum _AvatarSheetAction { choose, remove }

bool _localAvatarExists(String? path) {
  if (path == null || path.trim().isEmpty) return false;
  return File(path).existsSync();
}

Future<void> _pickAndApplyAvatar(BuildContext context, WidgetRef ref) async {
  final tr = Tr.of(context);
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 768,
    maxHeight: 768,
    imageQuality: 85,
  );
  if (picked == null || !context.mounted) return;

  final dest = await profileAvatarFile();
  await File(picked.path).copy(dest.path);

  final settings = ref.read(settingsServiceProvider);
  await settings.setProfileAvatarPath(dest.path);
  ref.read(settingsControllerProvider.notifier).setProfileAvatarPath(dest.path);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr.profileAvatarUpdating)),
  );

  try {
    if (FirebaseAuth.instance.currentUser != null) {
      await ref.read(cloudAuthProvider).uploadProfilePhoto(dest);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.profileAvatarUpdated)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.profileAvatarUpdatedLocal)),
    );
  }
}

Future<void> _removeAvatar(BuildContext context, WidgetRef ref) async {
  final tr = Tr.of(context);
  final settings = ref.read(settingsServiceProvider);
  final path = settings.profileAvatarPath;
  if (path != null && path.isNotEmpty) {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
  await settings.setProfileAvatarPath(null);
  ref.read(settingsControllerProvider.notifier).setProfileAvatarPath(null);

  try {
    if (FirebaseAuth.instance.currentUser != null) {
      await ref.read(cloudAuthProvider).removeProfilePhoto();
    }
  } catch (_) {}

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr.profileAvatarRemoved)),
  );
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.localPath,
    this.photoUrl,
    this.onTap,
    this.size = _avatarSize,
    this.showEditBadge = false,
  });

  final String name;
  final String? localPath;
  final String? photoUrl;
  final VoidCallback? onTap;
  final double size;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar(context);
    if (onTap == null) return avatar;

    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (showEditBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: context.isDark ? AppColors.lime : AppColors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  LucideIcons.camera,
                  size: 10,
                  color: context.isDark ? AppColors.ink : Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    Widget fallback() => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.lime, AppColors.limeAccent],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

    final local = localPath?.trim();
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(local),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback(),
          ),
        ),
      );
    }

    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) return fallback();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          _avatarPhotoUrl(url),
          width: size,
          height: size,
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
