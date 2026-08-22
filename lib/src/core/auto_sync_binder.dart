import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auto_backup_runner.dart';
import '../data/repositories/backup_service.dart';
import '../data/repositories/settings_service.dart';
import '../features/auth/cloud_auth.dart';
import '../features/auth/cloud_restore_prompt.dart';
import '../core/pro/pro_controller.dart';

/// Runs scheduled local/cloud backups when the app resumes.
class AutoSyncBinder extends ConsumerStatefulWidget {
  const AutoSyncBinder({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AutoSyncBinder> createState() => _AutoSyncBinderState();
}

class _AutoSyncBinderState extends ConsumerState<AutoSyncBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run();
  }

  Future<void> _run() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await runAutoLocalBackupIfDue(
      prefs: prefs,
      backup: ref.read(backupServiceProvider),
    );

    if (!ref.read(proControllerProvider).isPro) return;
    if (!(prefs.getBool(AutoBackupKeys.cloudEnabled) ?? false)) return;
    if (ref.read(authUserProvider).valueOrNull == null) return;

    final lastRaw = prefs.getString(AutoBackupKeys.lastCloud);
    final last = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
    final now = DateTime.now();
    if (last != null && now.difference(last).inHours < 20) return;

    try {
      await ref.read(cloudAuthProvider).uploadMoney();
      await prefs.setString(
        AutoBackupKeys.lastCloud,
        now.toUtc().toIso8601String(),
      );
    } catch (_) {
      ref.read(cloudBackupFailedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
