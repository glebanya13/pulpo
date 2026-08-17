import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/backup_service.dart';
import '../../widgets/common.dart';
import '../auth/cloud_auth.dart';
import '../export/export_sheet.dart';

class BackupsScreen extends ConsumerStatefulWidget {
  const BackupsScreen({super.key});

  @override
  ConsumerState<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends ConsumerState<BackupsScreen> {
  bool _autoBackup = true;
  List<File> _backups = const [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('backup-') && f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    setState(() => _backups = files);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(
              first: tr.backupsShort,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.shieldCheck,
                        size: 18, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr.autoBackup,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.primaryText)),
                        const SizedBox(height: 2),
                        Text(tr.autoBackupDesc,
                            style: TextStyle(
                                fontSize: 11, color: context.faintText)),
                      ],
                    ),
                  ),
                  BudgetToggle(
                    value: _autoBackup,
                    onChanged: (v) => setState(() => _autoBackup = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Action(
              icon: LucideIcons.plus,
              label: tr.createNow,
              filled: true,
              onTap: () async {
                await ref.read(backupServiceProvider).writeBackup();
                await _loadBackups();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr.backupCreated)),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.cloud,
              label: tr.cloudBackup,
              filled: false,
              onTap: () async {
                final user = ref.read(authUserProvider).valueOrNull;
                if (user == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr.signInToSync)),
                    );
                    context.push('/settings/account');
                  }
                  return;
                }
                try {
                  await ref.read(cloudAuthProvider).uploadMoney();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr.cloudBackupOk)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.download,
              label: tr.cloudRestore,
              filled: false,
              onTap: () async {
                final user = ref.read(authUserProvider).valueOrNull;
                if (user == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr.signInToSync)),
                    );
                    context.push('/settings/account');
                  }
                  return;
                }
                try {
                  final ok = await ref.read(cloudAuthProvider).downloadMoney();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? tr.cloudRestoreOk : tr.cloudEmpty),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.download,
              label: tr.exportCsv,
              filled: false,
              onTap: () => showExportSheet(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(tr.localBackupsUpper,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: context.mutedText,
                  )),
            ),
            if (_backups.isEmpty)
              EmptyState(
                icon: LucideIcons.database,
                title: tr.noBackupsTitle,
                description: tr.noBackupsDesc,
              )
            else
              for (final f in _backups)
                _BackupRow(
                  file: f,
                  onDeleted: _loadBackups,
                  onRestore: () async {
                    try {
                      await ref.read(backupServiceProvider).restoreFromFile(f);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr.dataRestored)),
                        );
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr.restoreFailed)),
                        );
                      }
                    }
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.lime : context.surface,
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: filled ? AppColors.ink : context.primaryText),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? AppColors.ink : context.primaryText)),
          ],
        ),
      ),
    );
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({
    required this.file,
    required this.onDeleted,
    required this.onRestore,
  });
  final File file;
  final VoidCallback onDeleted;
  final VoidCallback onRestore;

  String get _name => file.path.split(RegExp(r'[/\\]')).last;

  String _prettyDate(BuildContext ctx) {
    final match = RegExp(r'backup-(.+)\.json').firstMatch(_name);
    if (match == null) return _name;
    final raw = match.group(1)!.replaceAll('-', ':').replaceRange(10, 11, ' ');
    try {
      final parsed = DateTime.parse(
        raw.substring(0, 19).replaceAll(' ', 'T').replaceAll(':', '-'),
      );
      return DateFormat('d MMM y · HH:mm',
              Localizations.localeOf(ctx).languageCode)
          .format(parsed);
    } catch (_) {
      return _name;
    }
  }

  String _size() {
    final s = file.lengthSync();
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB';
    return '${(s / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.fileJson,
                size: 16, color: context.primaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_prettyDate(context),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.primaryText)),
                Text(_size(),
                    style: TextStyle(
                        fontSize: 11, color: context.faintText)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.rotateCcw,
                size: 16, color: context.primaryText),
            onPressed: onRestore,
          ),
          IconButton(
            icon: const Icon(LucideIcons.share,
                size: 16, color: AppColors.limeAccent),
            onPressed: () => Share.shareXFiles([XFile(file.path)]),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2,
                size: 16, color: AppColors.danger),
            onPressed: () async {
              await file.delete();
              onDeleted();
            },
          ),
        ],
      ),
    );
  }
}
