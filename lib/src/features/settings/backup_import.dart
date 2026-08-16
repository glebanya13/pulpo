import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../data/repositories/backup_service.dart';
import '../../data/repositories/settings_service.dart';

Future<File?> pickBackupJsonFile() async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  final path = res?.files.single.path;
  if (path == null) return null;
  return File(path);
}

/// Returns true when a backup was restored successfully.
Future<bool> restoreBackupFromPicker({
  required BuildContext context,
  required WidgetRef ref,
  bool completeOnboarding = false,
}) async {
  final tr = Tr.of(context);
  final file = await pickBackupJsonFile();
  if (file == null) return false;
  try {
    await ref.read(backupServiceProvider).restoreFromFile(file);
    if (completeOnboarding) {
      await ref.read(settingsControllerProvider.notifier).markOnboardingDone();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.dataRestored)),
      );
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.restoreFailed)),
      );
    }
    return false;
  }
}
