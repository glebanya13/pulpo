import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/tr.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/transaction_repository.dart';
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
  CsvParseResult? _parsed;
  int? _accountId;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final base = ref.watch(settingsControllerProvider).baseCurrency;
    _accountId ??= accounts.isEmpty ? null : accounts.first.id;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PageHeader(first: tr.importCsv, onBack: () => context.pop()),
            const SizedBox(height: 12),
            Text(
              tr.importCsvHint,
              style: TextStyle(fontSize: 14, color: context.mutedText),
            ),
            const SizedBox(height: 20),
            if (accounts.isNotEmpty) ...[
              Text(
                tr.account,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _accountId,
                items: [
                  for (final a in accounts)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} · ${a.currency}'),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _accountId = v),
              ),
              const SizedBox(height: 16),
            ],
            ScaledFilledButton(
              onPressed: _busy ? null : () => _pick(base),
              child: Text(tr.importPickFile),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Text(
                _fileName!,
                style: TextStyle(fontSize: 13, color: context.mutedText),
              ),
            ],
            if (_parsed != null) ...[
              const SizedBox(height: 16),
              Text(
                tr.importPreview(_parsed!.rows.length, _parsed!.skipped),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ScaledElevatedButton(
                onPressed: _busy || _parsed!.rows.isEmpty || _accountId == null
                    ? null
                    : _commit,
                child: Text(tr.importConfirm),
              ),
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

  Future<void> _pick(String fallbackCurrency) async {
    final ok = await requirePro(context, ref, ProGate.importCsv);
    if (!ok || !mounted) return;
    const group = XTypeGroup(
      label: 'CSV',
      extensions: ['csv', 'txt'],
    );
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final text = _decode(bytes);
      final parsed = parseTransactionCsv(text, fallbackCurrency: fallbackCurrency);
      setState(() {
        _fileName = file.name;
        _parsed = parsed;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.of(context).importFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commit() async {
    final parsed = _parsed;
    final accountId = _accountId;
    if (parsed == null || accountId == null) return;
    final ok = await requirePro(context, ref, ProGate.importCsv);
    if (!ok || !mounted) return;
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
