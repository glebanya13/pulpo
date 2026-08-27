import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/tr.dart';
import '../../data/repositories/auto_backup_runner.dart';
import '../../data/repositories/backup_service.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/subscription_repository.dart';
import 'cloud_auth.dart';

/// Set after sign-in when a cloud snapshot exists and the user should choose.
final pendingCloudRestoreProvider = StateProvider<bool>((ref) => false);

/// Blocks auto cloud upload while the restore dialog / restore is in flight.
final cloudUploadHoldProvider = StateProvider<bool>((ref) => false);

/// One-shot flag for auto cloud backup failure snackbar per app session.
final cloudBackupFailedProvider = StateProvider<bool>((ref) => false);

enum CloudRestoreChoice { useCloud, keepLocal, merge }

void refreshUiAfterMoneyRestore(WidgetRef ref) {
  _refreshMoneyUi(
    reloadFromDisk: () =>
        ref.read(settingsControllerProvider.notifier).reloadFromDisk(),
    invalidate: ref.invalidate,
  );
}

/// Same as [refreshUiAfterMoneyRestore] for non-widget [Ref] (e.g. CloudAuth).
void refreshUiAfterMoneyRestoreRef(Ref ref) {
  _refreshMoneyUi(
    reloadFromDisk: () =>
        ref.read(settingsControllerProvider.notifier).reloadFromDisk(),
    invalidate: ref.invalidate,
  );
}

void _refreshMoneyUi({
  required void Function() reloadFromDisk,
  required void Function(ProviderOrFamily provider) invalidate,
}) {
  reloadFromDisk();
  invalidate(accountsProvider);
  invalidate(categoriesProvider);
  invalidate(allTransactionsProvider);
  invalidate(budgetsProvider);
  invalidate(goalsProvider);
  invalidate(debtsProvider);
  invalidate(recurringRulesProvider);
  invalidate(subscriptionsProvider);
}

Future<void> showCloudRestoreDialog(BuildContext context, WidgetRef ref) async {
  final tr = Tr.of(context);
  ref.read(cloudUploadHoldProvider.notifier).state = true;
  try {
    final cloud = ref.read(cloudAuthProvider);
    final backup = ref.read(backupServiceProvider);
    final results = await Future.wait([
      cloud.peekCloudSnapshotMeta(),
      backup.localCounts(),
    ]);
    final remote = results[0] as CloudSnapshotMeta?;
    final local = results[1] as ({int accounts, int transactions});

    if (!context.mounted) return;

    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();
    final remoteDate = remote?.updatedAt != null
        ? dateFmt.format(remote!.updatedAt!.toLocal())
        : '—';

    final choice = await showDialog<CloudRestoreChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(tr.cloudRestoreTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.cloudRestoreBody),
            const SizedBox(height: 12),
            Text(
              tr.cloudRestoreRemoteMeta(
                remoteDate,
                remote?.accounts ?? 0,
                remote?.transactions ?? 0,
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              tr.cloudRestoreLocalMeta(local.accounts, local.transactions),
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              tr.cloudRestoreMergeHint,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).textTheme.bodySmall?.color,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, CloudRestoreChoice.keepLocal),
            child: Text(tr.cloudRestoreKeepLocal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, CloudRestoreChoice.merge),
            child: Text(tr.cloudRestoreMerge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, CloudRestoreChoice.useCloud),
            child: Text(tr.cloudRestoreUseCloud),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;

    try {
      if (choice == CloudRestoreChoice.useCloud) {
        final ok = await cloud.downloadMoney();
        if (ok) refreshUiAfterMoneyRestore(ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? tr.cloudRestoreOk : tr.cloudEmpty)),
          );
        }
      } else if (choice == CloudRestoreChoice.merge) {
        final kept = await cloud.mergeMoney();
        if (kept >= 0) refreshUiAfterMoneyRestore(ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                kept >= 0 ? tr.cloudRestoreMergedOk : tr.cloudEmpty,
              ),
            ),
          );
        }
      } else {
        final hasLocal = await backup.hasLocalMoneyData();
        if (hasLocal) {
          await cloud.uploadMoney(bypassHold: true);
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
        } else {
          debugPrint('keepLocal: local empty — skipping upload to protect cloud');
        }
      }
    } catch (e, st) {
      debugPrint('showCloudRestoreDialog: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.restoreFailed)),
        );
      }
    }
  } finally {
    ref.read(cloudUploadHoldProvider.notifier).state = false;
    ref.read(pendingCloudRestoreProvider.notifier).state = false;
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await showCloudRestoreDialog(context, ref);
        } finally {
          _promptOpen = false;
        }
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
