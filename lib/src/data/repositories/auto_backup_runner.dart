import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';

class AutoBackupKeys {
  static const enabled = 'auto_backup_enabled';
  static const cloudEnabled = 'auto_cloud_backup_enabled';
  static const lastLocal = 'last_local_backup_at';
  static const lastCloud = 'last_cloud_sync_at';
}

Future<void> runAutoLocalBackupIfDue({
  required SharedPreferences prefs,
  required BackupService backup,
}) async {
  if (!(prefs.getBool(AutoBackupKeys.enabled) ?? true)) return;
  final lastRaw = prefs.getString(AutoBackupKeys.lastLocal);
  final last = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
  final now = DateTime.now();
  if (last != null && now.difference(last).inHours < 20) return;
  await backup.writeBackup();
  await prefs.setString(
    AutoBackupKeys.lastLocal,
    now.toUtc().toIso8601String(),
  );
  await pruneLocalBackups(maxFiles: 14);
}

Future<void> pruneLocalBackups({int maxFiles = 14}) async {
  final dir = await getApplicationDocumentsDirectory();
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('backup-') && f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));
  if (files.length <= maxFiles) return;
  for (final f in files.skip(maxFiles)) {
    try {
      await f.delete();
    } catch (_) {}
  }
}
