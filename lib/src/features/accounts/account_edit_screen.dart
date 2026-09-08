import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/tr.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class AccountEditScreen extends ConsumerStatefulWidget {
  const AccountEditScreen({super.key, required this.existingId});
  final int existingId;

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  final _nameCtrl = TextEditingController();
  final _creditCtrl = TextEditingController();
  bool _includeInTotal = true;
  bool _isCredit = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final accounts = ref.read(accountsProvider).valueOrNull ?? [];
      final existing =
          accounts.where((a) => a.id == widget.existingId).firstOrNull;
      if (existing != null) {
        _nameCtrl.text = existing.name;
        _creditCtrl.text = existing.creditLimit?.toString() ?? '';
        _includeInTotal = existing.includeInTotal;
        _isCredit = existing.type == AccountType.card.index ||
            existing.type == AccountType.loan.index;
        _initialized = true;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _creditCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final creditRaw = _creditCtrl.text.trim();
      final credit = creditRaw.isEmpty
          ? null
          : double.tryParse(creditRaw.replaceAll(',', '.'));
      await ref.read(accountRepositoryProvider).update(
            id: widget.existingId,
            name: _nameCtrl.text.trim(),
            includeInTotal: _includeInTotal,
            creditLimit: credit,
            clearCreditLimit: _isCredit && creditRaw.isEmpty,
          );
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
        title: Text(tr.deleteAccountTitle),
        content: Text(tr.deleteAccountBody),
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
    await ref.read(accountRepositoryProvider).delete(widget.existingId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: tr.editAccount,
          onBack: () => context.pop(),
        ),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(labelText: tr.accountName),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _includeInTotal,
            onChanged: (v) => setState(() => _includeInTotal = v),
            title: Text(tr.includeInTotal),
          ),
          if (_isCredit) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _creditCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: tr.creditLimit,
                hintText: tr.creditLimitHint,
              ),
            ),
          ],
          const SizedBox(height: 28),
          ScaledElevatedButton(
            expand: true,
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : tr.save),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53E3E)),
              child: Text(tr.delete),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
