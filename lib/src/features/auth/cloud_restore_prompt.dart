import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../data/repositories/auto_backup_runner.dart';
import '../../data/repositories/settings_service.dart';
import 'cloud_auth.dart';

/// Set after sign-in when a cloud snapshot exists and the user should choose.
final pendingCloudRestoreProvider = StateProvider<bool>((ref) => false);

/// One-shot flag for auto cloud backup failure snackbar per app session.
final cloudBackupFailedProvider = StateProvider<bool>((ref) => false);

enum CloudRestoreChoice { useCloud, keepLocal }

Future<void> showCloudRestoreDialog(BuildContext context, WidgetRef ref) async {
  final tr = Tr.of(context);
  final choice = await showDialog<CloudRestoreChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr.cloudRestoreTitle),
      content: Text(tr.cloudRestoreBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, CloudRestoreChoice.keepLocal),
          child: Text(tr.cloudRestoreKeepLocal),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, CloudRestoreChoice.useCloud),
          child: Text(tr.cloudRestoreUseCloud),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return;

  final cloud = ref.read(cloudAuthProvider);
  try {
    if (choice == CloudRestoreChoice.useCloud) {
      final ok = await cloud.downloadMoney();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? tr.cloudRestoreOk : tr.cloudEmpty)),
        );
      }
    } else {
      await cloud.uploadMoney();
      final now = DateTime.now();
      await ref.read(sharedPreferencesProvider).setString(
            AutoBackupKeys.lastCloud,
            now.toUtc().toIso8601String(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.cloudBackupOk)),
        );
      }
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.errorTitle)),
      );
    }
  }
}

class CloudLoginSyncBinder extends ConsumerStatefulWidget {
  const CloudLoginSyncBinder({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CloudLoginSyncBinder> createState() =>
      _CloudLoginSyncBinderState();
}

class _CloudLoginSyncBinderState extends ConsumerState<CloudLoginSyncBinder> {
  var _promptOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(pendingCloudRestoreProvider, (prev, next) {
      if (!next || _promptOpen || !mounted) return;
      _promptOpen = true;
      ref.read(pendingCloudRestoreProvider.notifier).state = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showCloudRestoreDialog(context, ref);
        _promptOpen = false;
      });
    });
    return widget.child;
  }
}

class CloudSyncFeedbackListener extends ConsumerStatefulWidget {
  const CloudSyncFeedbackListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CloudSyncFeedbackListener> createState() =>
      _CloudSyncFeedbackListenerState();
}

class _CloudSyncFeedbackListenerState
    extends ConsumerState<CloudSyncFeedbackListener> {
  var _shownBackupError = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(cloudBackupFailedProvider, (prev, next) {
      if (!next || _shownBackupError || !mounted) return;
      _shownBackupError = true;
      ref.read(cloudBackupFailedProvider.notifier).state = false;
      final tr = Tr.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.cloudBackupFailed)),
      );
    });
    return widget.child;
  }
}
