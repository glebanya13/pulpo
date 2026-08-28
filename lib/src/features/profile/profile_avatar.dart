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
import 'profile_avatar_cache.dart';

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
  await ProfileAvatarCache.clear();

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

class ProfileAvatar extends StatefulWidget {
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
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar>
    with SingleTickerProviderStateMixin {
  File? _remoteFile;
  var _loadingRemote = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadingRemote = _shouldLoadRemote;
    _resolveRemote();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.localPath != widget.localPath) {
      _resolveRemote();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _resolveRemote() async {
    if (_hasLocalAvatar) {
      if (_remoteFile != null || _loadingRemote) {
        setState(() {
          _remoteFile = null;
          _loadingRemote = false;
        });
      }
      _fadeController.value = 1;
      return;
    }

    final url = widget.photoUrl?.trim();
    if (url == null || url.isEmpty) {
      if (_remoteFile != null || _loadingRemote) {
        setState(() {
          _remoteFile = null;
          _loadingRemote = false;
        });
      }
      _fadeController.value = 0;
      return;
    }

    final cached = await ProfileAvatarCache.fileForUrl(url);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _remoteFile = cached;
        _loadingRemote = false;
      });
      _fadeController.forward(from: 0);
      return;
    }

    setState(() {
      _remoteFile = null;
      _loadingRemote = true;
    });
    _fadeController.value = 0;

    final file = await ProfileAvatarCache.warm(url);
    if (!mounted) return;
    setState(() {
      _remoteFile = file;
      _loadingRemote = false;
    });
    if (file != null) {
      _fadeController.forward(from: 0);
    }
  }

  bool get _hasLocalAvatar {
    final local = widget.localPath?.trim();
    return local != null && local.isNotEmpty && File(local).existsSync();
  }

  bool get _shouldLoadRemote {
    if (_hasLocalAvatar) return false;
    final url = widget.photoUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar(context);
    if (widget.onTap == null) return avatar;

    return Pressable(
      onTap: widget.onTap,
      scale: 0.96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (widget.showEditBadge)
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
    final letter =
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U';
    final fallback = _AvatarFallback(letter: letter, size: widget.size);

    if (_hasLocalAvatar) {
      final local = widget.localPath!.trim();
      return _AvatarImage(
        size: widget.size,
        child: Image.file(
          File(local),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        ),
        fade: _fade,
        showImage: true,
      );
    }

    if (_remoteFile != null) {
      return _AvatarImage(
        size: widget.size,
        child: Image.file(
          _remoteFile!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        ),
        fade: _fade,
        showImage: true,
      );
    }

    if (_loadingRemote) {
      return _AvatarLoading(letter: letter, size: widget.size);
    }

    return fallback;
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.size,
    required this.child,
    required this.fade,
    required this.showImage,
  });

  final double size;
  final Widget child;
  final Animation<double> fade;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: FadeTransition(
          opacity: fade,
          child: showImage ? child : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.letter, required this.size});

  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}

class _AvatarLoading extends StatefulWidget {
  const _AvatarLoading({required this.letter, required this.size});

  final String letter;
  final double size;

  @override
  State<_AvatarLoading> createState() => _AvatarLoadingState();
}

class _AvatarLoadingState extends State<_AvatarLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Opacity(
          opacity: 0.55 + (_pulse.value * 0.45),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          _AvatarFallback(letter: widget.letter, size: widget.size),
          SizedBox(
            width: widget.size * 0.34,
            height: widget.size * 0.34,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.isDark
                  ? AppColors.lime.withValues(alpha: 0.9)
                  : AppColors.ink.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
