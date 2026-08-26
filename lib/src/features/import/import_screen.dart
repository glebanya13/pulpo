import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/file_pick.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import 'csv_import.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _busy = false;
  String? _fileName;
  String? _rawText;
  CsvInspectResult? _inspect;
  CsvColumnMapping? _mapping;
  CsvParseResult? _parsed;
  int? _accountId;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final base = ref.watch(settingsControllerProvider).baseCurrency;
    final accounts = accountsAsync.valueOrNull ?? const [];
    _accountId ??= accounts.isEmpty ? null : accounts.first.id;

    return Scaffold(
      body: AsyncValueView(
          value: accountsAsync,
          onRetry: () => ref.invalidate(accountsProvider),
          data: (_) => StickyScrollPage(
            header: PageHeader(first: tr.importCsv, onBack: () => context.pop()),
            headerGap: 16,
            children: [
            Text(
              tr.importCsvHint,
              style: TextStyle(fontSize: 14, color: context.mutedText),
            ),
            const SizedBox(height: 20),
            if (accounts.isEmpty) ...[
              EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: tr.importNoAccounts,
                description: tr.addAccountFirst,
              ),
              const SizedBox(height: 12),
              ScaledFilledButton(
                onPressed: () => context.push('/accounts'),
                child: Text(tr.accounts),
              ),
            ] else ...[
              Text(
                tr.account,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.mutedText,
                ),
              ),
              const SizedBox(height: 12),
              _AccountDropdownButton(
                label: _accountLabel(tr, accounts),
                onTap: _busy
                    ? null
                    : () => _openAccountPicker(
                          context: context,
                          accounts: accounts,
                        ),
              ),
              const SizedBox(height: 16),
              ScaledFilledButton(
                onPressed: _busy ? null : () => _pick(base),
                child: Text(tr.importPickFile),
              ),
            ],
            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Text(
                _fileName!,
                style: TextStyle(fontSize: 13, color: context.mutedText),
              ),
            ],
            if (_parsed != null) ...[
              const SizedBox(height: 16),
              if (_inspect != null && _mapping != null) ...[
                Text(
                  tr.importMapColumns,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                _ColumnMapRow(
                  label: tr.importColDate,
                  headers: _inspect!.headers,
                  value: _mapping!.indices[CsvField.date],
                  allowNone: false,
                  noneLabel: tr.importColNone,
                  onChanged: (v) => _reparse(base, CsvField.date, v),
                ),
                _ColumnMapRow(
                  label: tr.importColAmount,
                  headers: _inspect!.headers,
                  value: _mapping!.indices[CsvField.amount],
                  allowNone: false,
                  noneLabel: tr.importColNone,
                  onChanged: (v) => _reparse(base, CsvField.amount, v),
                ),
                _ColumnMapRow(
                  label: tr.importColType,
                  headers: _inspect!.headers,
                  value: _mapping!.indices[CsvField.type],
                  allowNone: true,
                  noneLabel: tr.importColNone,
                  onChanged: (v) => _reparse(base, CsvField.type, v),
                ),
                _ColumnMapRow(
                  label: tr.importColCurrency,
                  headers: _inspect!.headers,
                  value: _mapping!.indices[CsvField.currency],
                  allowNone: true,
                  noneLabel: tr.importColNone,
                  onChanged: (v) => _reparse(base, CsvField.currency, v),
                ),
                _ColumnMapRow(
                  label: tr.importColNote,
                  headers: _inspect!.headers,
                  value: _mapping!.indices[CsvField.note],
                  allowNone: true,
                  noneLabel: tr.importColNone,
                  onChanged: (v) => _reparse(base, CsvField.note, v),
                ),
                const SizedBox(height: 12),
              ],
              if (_parsed!.rows.isEmpty)
                Text(
                  tr.importNoRows,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE53E3E),
                  ),
                )
              else ...[
                Text(
                  tr.importPreview(_parsed!.rows.length, _parsed!.skipped),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr.importSampleRows,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 6),
                for (final row in _parsed!.rows.take(12))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${DateFormat.yMd(Localizations.localeOf(context).toString()).format(row.date)} · '
                      '${row.type.name} · ${row.amount.toStringAsFixed(2)} ${row.currency}'
                      '${row.note == null || row.note!.isEmpty ? '' : ' · ${row.note}'}',
                      style: TextStyle(fontSize: 12, color: context.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),
                ScaledElevatedButton(
                  onPressed:
                      _busy || _parsed!.rows.isEmpty || _accountId == null
                          ? null
                          : _commit,
                  child: Text(tr.importConfirm),
                ),
              ],
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 2),
            ],
            ],
          ),
        ),
    );
  }

  Future<void> _openAccountPicker({
    required BuildContext context,
    required List<Account> accounts,
  }) async {
    final tr = Tr.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.65;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.faintText.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      tr.selectAccount,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final a in accounts)
                    _AccountSheetTile(
                      label: '${a.name} · ${a.currency}',
                      selected: _accountId == a.id,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _accountId = a.id);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _accountLabel(Tr tr, List<Account> accounts) {
    Account? selected;
    for (final a in accounts) {
      if (a.id == _accountId) {
        selected = a;
        break;
      }
    }
    if (selected == null) return tr.selectAccount;
    return '${selected.name} · ${selected.currency}';
  }

  Future<void> _pick(String fallbackCurrency) async {
    final XFile? file;
    try {
      file = await openFile(acceptedTypeGroups: const [csvFileTypeGroup]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.of(context).importFailed)),
      );
      return;
    }
    if (file == null || !mounted) return;
    final picked = file;
    setState(() => _busy = true);
    try {
      final bytes = await picked.readAsBytes();
      final text = _decode(bytes);
      final inspect = inspectCsv(text);
      final mapping = inspect.detected;
      final parsed = parseTransactionCsv(
        text,
        fallbackCurrency: fallbackCurrency,
        mapping: mapping,
      );
      setState(() {
        _fileName = picked.name;
        _rawText = text;
        _inspect = inspect;
        _mapping = mapping;
        _parsed = parsed;
      });
      if (parsed.rows.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.of(context).importNoRows)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.of(context).importFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reparse(String fallbackCurrency, CsvField field, int? index) {
    final raw = _rawText;
    final mapping = _mapping;
    if (raw == null || mapping == null) return;
    final next = mapping.copyWithIndex(field, index);
    final parsed = parseTransactionCsv(
      raw,
      fallbackCurrency: fallbackCurrency,
      mapping: next,
    );
    setState(() {
      _mapping = next;
      _parsed = parsed;
    });
  }

  Future<void> _commit() async {
    final parsed = _parsed;
    final accountId = _accountId;
    if (parsed == null || accountId == null) return;
    setState(() => _busy = true);
    final repo = ref.read(transactionRepositoryProvider);
    final existing = ref.read(allTransactionsProvider).valueOrNull ?? const [];
    var imported = 0;
    var skippedDup = 0;
    try {
      for (final row in parsed.rows) {
        if (row.type == TxType.transfer) continue;
        if (_isDuplicate(existing, accountId, row)) {
          skippedDup++;
          continue;
        }
        await repo.add(
          accountId: accountId,
          amount: row.amount,
          currency: row.currency,
          type: row.type,
          date: row.date,
          note: row.note,
        );
        imported++;
      }
      if (!mounted) return;
      if (imported == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Tr.of(context).importNoRows)),
        );
        return;
      }
      final msg = skippedDup > 0
          ? '${Tr.of(context).importDone(imported)} · ${Tr.of(context).importDuplicatesSkipped(skippedDup)}'
          : Tr.of(context).importDone(imported);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.of(context).importFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }
}

class _ColumnMapRow extends StatelessWidget {
  const _ColumnMapRow({
    required this.label,
    required this.headers,
    required this.value,
    required this.allowNone,
    required this.noneLabel,
    required this.onChanged,
  });

  final String label;
  final List<String> headers;
  final int? value;
  final bool allowNone;
  final String noneLabel;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.mutedText,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: value,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: context.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                if (allowNone)
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(noneLabel),
                  ),
                for (var i = 0; i < headers.length; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Text(
                      headers[i],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isDuplicate(List<dynamic> existing, int accountId, ImportedRow row) {
  for (final t in existing) {
    if (t.accountId != accountId) continue;
    if (t.date.year != row.date.year ||
        t.date.month != row.date.month ||
        t.date.day != row.date.day) {
      continue;
    }
    if ((t.amount - row.amount).abs() > 0.009) continue;
    final a = (t.note ?? '').trim().toLowerCase();
    final b = (row.note ?? '').trim().toLowerCase();
    if (a.isEmpty && b.isEmpty) return true;
    if (a == b) return true;
  }
  return false;
}

class _AccountDropdownButton extends StatelessWidget {
  const _AccountDropdownButton({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.wallet,
                size: 16,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: context.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSheetTile extends StatelessWidget {
  const _AccountSheetTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lime.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
            ),
            if (selected)
              const Icon(LucideIcons.check, size: 18, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
