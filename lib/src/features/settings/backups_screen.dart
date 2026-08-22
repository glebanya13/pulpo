import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auto_backup_runner.dart';
import '../../data/repositories/backup_service.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pro_badge.dart';
import '../auth/cloud_auth.dart';
import '../auth/cloud_restore_prompt.dart';

class BackupsScreen extends ConsumerStatefulWidget {
  const BackupsScreen({super.key});

  @override
  ConsumerState<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends ConsumerState<BackupsScreen> {
  bool _autoBackup = true;
  bool _autoCloud = false;
  List<File> _backups = const [];
  DateTime? _lastCloud;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _autoBackup = prefs.getBool(AutoBackupKeys.enabled) ?? true;
    _autoCloud = prefs.getBool(AutoBackupKeys.cloudEnabled) ?? false;
    final raw = prefs.getString(AutoBackupKeys.lastCloud);
    _lastCloud = raw != null ? DateTime.tryParse(raw) : null;
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

  Future<void> _setAutoBackup(bool v) async {
    await ref.read(sharedPreferencesProvider).setBool(AutoBackupKeys.enabled, v);
    setState(() => _autoBackup = v);
  }

  Future<void> _setAutoCloud(bool v) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(AutoBackupKeys.cloudEnabled, v);
    setState(() => _autoCloud = v);
  }

  Future<void> _cloudRestore() async {
    final tr = Tr.of(context);
    if (!await requirePro(context, ref, ProGate.sync)) return;
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

    final cloud = ref.read(cloudAuthProvider);
    final hasRemote = await cloud.hasCloudSnapshot();
    if (!hasRemote) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.cloudEmpty)),
        );
      }
      return;
    }

    await showCloudRestoreDialog(context, ref);
  }

  Future<void> _importBackupFile() async {
    final tr = Tr.of(context);
    const group = XTypeGroup(label: 'JSON', extensions: ['json']);
    final picked = await openFile(acceptedTypeGroups: const [group]);
    if (picked == null || !mounted) return;
    try {
      await ref.read(backupServiceProvider).restoreFromFile(File(picked.path));
      await _loadBackups();
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
  }

  String _syncLabel(Tr tr) {
    if (_lastCloud == null) return tr.neverSynced;
    final fmt = DateFormat('d MMM y · HH:mm',
        Localizations.localeOf(context).languageCode);
    return '${tr.lastSyncPrefix}${fmt.format(_lastCloud!.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final isPro = ref.watch(proControllerProvider).isPro;
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
                    onChanged: _setAutoBackup,
                  ),
                ],
              ),
            ),
            if (isPro) ...[
              const SizedBox(height: 10),
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
                      child: const Icon(LucideIcons.cloud,
                          size: 18, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr.autoCloudBackup,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.primaryText)),
                          const SizedBox(height: 2),
                          Text(tr.autoCloudBackupDesc,
                              style: TextStyle(
                                  fontSize: 11, color: context.faintText)),
                          const SizedBox(height: 4),
                          Text(
                            _syncLabel(tr),
                            style: TextStyle(
                                fontSize: 10, color: context.mutedText),
                          ),
                        ],
                      ),
                    ),
                    BudgetToggle(
                      value: _autoCloud,
                      onChanged: _setAutoCloud,
                    ),
                  ],
                ),
              ),
            ],
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
              showPro: !isPro,
              onTap: () async {
                if (!await requirePro(context, ref, ProGate.cloud)) return;
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
                  final now = DateTime.now();
                  await ref.read(sharedPreferencesProvider).setString(
                        AutoBackupKeys.lastCloud,
                        now.toUtc().toIso8601String(),
                      );
                  if (mounted) {
                    setState(() => _lastCloud = now);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr.cloudBackupOk)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr.errorTitle)),
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
              showPro: !isPro,
              onTap: _cloudRestore,
            ),
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.upload,
              label: tr.importBackupJson,
              filled: false,
              onTap: _importBackupFile,
            ),
            const SizedBox(height: 10),
            _Action(
              icon: LucideIcons.download,
              label: tr.exportCsv,
              filled: false,
              onTap: () => context.push('/settings/export'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
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
    this.showPro = false,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  final bool showPro;

  @override
  Widget build(BuildContext context) {
    return Pressable(
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
            if (showPro) ...[
              const SizedBox(width: 8),
              const ProBadge(dense: true),
            ],
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
          Pressable(
            onTap: onRestore,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(LucideIcons.rotateCcw,
                  size: 16, color: context.primaryText),
            ),
          ),
          Pressable(
            onTap: () => Share.shareXFiles([XFile(file.path)]),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(LucideIcons.share,
                  size: 16, color: AppColors.limeAccent),
            ),
          ),
          Pressable(
            onTap: () async {
              await file.delete();
              onDeleted();
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(LucideIcons.trash2,
                  size: 16, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
