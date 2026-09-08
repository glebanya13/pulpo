import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class SubscriptionEditorScreen extends ConsumerStatefulWidget {
  const SubscriptionEditorScreen({super.key, this.existingId});
  final int? existingId;
  bool get isEdit => existingId != null;

  @override
  ConsumerState<SubscriptionEditorScreen> createState() =>
      _SubscriptionEditorScreenState();
}

class _SubscriptionEditorScreenState
    extends ConsumerState<SubscriptionEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _cycle = 'monthly';
  DateTime _next = DateTime.now().add(const Duration(days: 30));
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.isEdit) {
      final subs = ref.read(subscriptionsProvider).valueOrNull ?? [];
      final existing =
          subs.where((s) => s.id == widget.existingId).firstOrNull;
      if (existing != null) {
        _nameCtrl.text = existing.name;
        _amountCtrl.text = existing.amount.toString();
        _cycle = existing.cycle;
        _next = existing.nextPayment;
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
    final name = _nameCtrl.text.trim();
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (name.isEmpty || amount <= 0 || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(
          id: widget.existingId!,
          name: name,
          amount: amount,
          cycle: _cycle,
          nextPayment: _next,
        );
      } else {
        final currency = ref.read(settingsControllerProvider).baseCurrency;
        await repo.add(
          name: name,
          amount: amount,
          currency: currency,
          cycle: _cycle,
          nextPayment: _next,
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
        title: Text(tr.deleteSubTitle),
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
    await ref.read(subscriptionRepositoryProvider).delete(widget.existingId!);
    if (mounted) context.pop();
  }

  Widget _cycleChip(String value, String label) {
    final active = _cycle == value;
    return Expanded(
      child: Pressable(
        onTap: () => setState(() => _cycle = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.lime : context.scaffoldBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.ink : context.primaryText,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: widget.isEdit ? tr.editSubscription : tr.newSubscription,
          onBack: () => context.pop(),
        ),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: !widget.isEdit,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: tr.serviceName),
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
          const SizedBox(height: 16),
          Text(
            tr.periodicity,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.mutedText),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _cycleChip('monthly', tr.monthlyLabel),
              const SizedBox(width: 8),
              _cycleChip('yearly', tr.yearlyLabel),
            ],
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _next,
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate:
                    DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null) setState(() => _next = picked);
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
                  Text(
                    '${tr.nextPaymentPrefix}${DateFormat('d MMM y', locale).format(_next)}',
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
