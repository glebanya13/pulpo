import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class RecurringEditorScreen extends ConsumerStatefulWidget {
  const RecurringEditorScreen({super.key, this.existingId});
  final int? existingId;
  bool get isEdit => existingId != null;

  @override
  ConsumerState<RecurringEditorScreen> createState() =>
      _RecurringEditorScreenState();
}

class _RecurringEditorScreenState
    extends ConsumerState<RecurringEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TxType _type = TxType.expense;
  String _frequency = 'monthly';
  DateTime _next = DateTime.now().add(const Duration(days: 7));
  bool _initialized = false;
  bool _saving = false;

  // Cached template data needed for update
  int? _templateAccountId;
  int? _templateCategoryId;
  String? _templateCurrency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.isEdit) {
      final rules = ref.read(recurringRulesProvider).valueOrNull ?? [];
      final existing =
          rules.where((r) => r.id == widget.existingId).firstOrNull;
      if (existing != null) {
        final template = RecurringTemplate.fromJson(existing.templateJson);
        _nameCtrl.text = template.name;
        _amountCtrl.text = template.amount.toString();
        _type = template.type;
        _frequency = existing.frequency;
        _next = existing.nextRunAt;
        _templateAccountId = template.accountId;
        _templateCategoryId = template.categoryId;
        _templateCurrency = template.currency;
        _initialized = true;
      }
    } else {
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (_nameCtrl.text.trim().isEmpty || amount <= 0 || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(recurringRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(
          id: widget.existingId!,
          name: _nameCtrl.text.trim(),
          accountId: _templateAccountId!,
          categoryId: _templateCategoryId,
          amount: amount,
          currency: _templateCurrency!,
          type: _type,
          frequency: _frequency,
          nextRun: _next,
        );
      } else {
        final accounts = ref.read(accountsProvider).valueOrNull ?? [];
        if (accounts.isEmpty) return;
        await repo.add(
          name: _nameCtrl.text.trim(),
          accountId: accounts.first.id,
          amount: amount,
          currency: accounts.first.currency,
          type: _type,
          frequency: _frequency,
          nextRun: _next,
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final tr = Tr.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.deleteRuleTitle),
        content: Text(tr.deleteTxBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(tr.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53E3E)),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(recurringRepositoryProvider).delete(widget.existingId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: widget.isEdit ? tr.editRule : tr.newRule,
          onBack: () => context.pop(),
        ),
        children: [
          TabsPill(
            tabs: [tr.expense, tr.income],
            index: _type == TxType.expense ? 0 : 1,
            onChanged: (i) =>
                setState(() => _type = i == 0 ? TxType.expense : TxType.income),
            limeActive: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: !widget.isEdit,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: tr.titleLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(labelText: tr.amount),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: InputDecoration(labelText: tr.frequencyLabel),
            items: [
              DropdownMenuItem(value: 'daily', child: Text(tr.freqDaily)),
              DropdownMenuItem(value: 'weekly', child: Text(tr.freqWeekly)),
              DropdownMenuItem(
                  value: 'monthly', child: Text(tr.monthlyLabel)),
              DropdownMenuItem(value: 'yearly', child: Text(tr.yearlyLabel)),
            ],
            onChanged: (v) => setState(() => _frequency = v ?? 'monthly'),
          ),
          const SizedBox(height: 12),
          _DateRow(
            date: _next,
            prefix: tr.nextRunPrefix,
            locale: locale,
            onPick: (d) => setState(() => _next = d),
          ),
          const SizedBox(height: 28),
          ScaledElevatedButton(
            expand: true,
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : tr.save),
          ),
          if (widget.isEdit) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE53E3E)),
                child: Text(tr.delete),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.date,
    required this.prefix,
    required this.locale,
    required this.onPick,
  });
  final DateTime date;
  final String prefix;
  final String locale;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.scaffoldBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar,
                size: 18, color: context.primaryText),
            const SizedBox(width: 10),
            Text('$prefix${DateFormat('d MMM y', locale).format(date)}'),
          ],
        ),
      ),
    );
  }
}
