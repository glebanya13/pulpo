import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class DebtEditorScreen extends ConsumerStatefulWidget {
  const DebtEditorScreen({super.key, this.existingId});
  final int? existingId;
  bool get isEdit => existingId != null;

  @override
  ConsumerState<DebtEditorScreen> createState() => _DebtEditorScreenState();
}

class _DebtEditorScreenState extends ConsumerState<DebtEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DebtDirection _direction = DebtDirection.iOwe;
  DateTime? _dueDate;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.isEdit) {
      final debts = ref.read(debtsProvider).valueOrNull ?? [];
      final existing =
          debts.where((d) => d.id == widget.existingId).firstOrNull;
      if (existing != null) {
        _nameCtrl.text = existing.counterparty;
        _amountCtrl.text = existing.amount.toString();
        _direction = DebtDirection.values[existing.direction];
        _dueDate = existing.dueDate;
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
      final repo = ref.read(debtRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(
          id: widget.existingId!,
          counterparty: _nameCtrl.text.trim(),
          amount: amount,
          direction: _direction,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        );
      } else {
        final currency = ref.read(settingsControllerProvider).baseCurrency;
        await repo.add(
          counterparty: _nameCtrl.text.trim(),
          amount: amount,
          currency: currency,
          direction: _direction,
          dueDate: _dueDate,
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
        title: Text(tr.deleteDebtTitle),
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
    await ref.read(debtRepositoryProvider).delete(widget.existingId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: widget.isEdit ? tr.editDebt : tr.newDebt,
          onBack: () => context.pop(),
        ),
        children: [
          TabsPill(
            tabs: [tr.iOwe, tr.owedToMe],
            index: _direction.index,
            onChanged: (i) =>
                setState(() => _direction = DebtDirection.values[i]),
            limeActive: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: !widget.isEdit,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: tr.toFromWhom),
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
          Pressable(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ??
                    DateTime.now().add(const Duration(days: 30)),
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate:
                    DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.scaffoldBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar,
                      size: 18, color: context.primaryText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_dueDate == null
                        ? tr.dueDateLabel
                        : DateFormat('d MMMM y', locale)
                            .format(_dueDate!)),
                  ),
                  if (_dueDate != null)
                    Pressable(
                      onTap: () => setState(() => _dueDate = null),
                      child: Icon(LucideIcons.x,
                          size: 16, color: context.faintText),
                    ),
                ],
              ),
            ),
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
