import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/tr.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class GoalProgressScreen extends ConsumerStatefulWidget {
  const GoalProgressScreen({super.key, required this.goalId});
  final int goalId;

  @override
  ConsumerState<GoalProgressScreen> createState() =>
      _GoalProgressScreenState();
}

class _GoalProgressScreenState extends ConsumerState<GoalProgressScreen> {
  final _amountCtrl = TextEditingController();
  int? _accountId;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accountId == null) {
      final goal = (ref.read(goalsProvider).valueOrNull ?? [])
          .where((g) => g.id == widget.goalId)
          .firstOrNull;
      final accounts = ref.read(accountsProvider).valueOrNull ?? [];
      _accountId = goal?.accountId ??
          (accounts.isNotEmpty ? accounts.first.id : null);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (v == null || v <= 0 || _accountId == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(goalRepositoryProvider).addProgress(
            id: widget.goalId,
            amount: v,
            accountId: _accountId!,
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: tr.addToGoal,
          onBack: () => context.pop(),
        ),
        children: [
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(labelText: tr.amount),
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _accountId,
              decoration: InputDecoration(labelText: tr.transferFrom),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
          ],
          const SizedBox(height: 28),
          ScaledElevatedButton(
            expand: true,
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : tr.save),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
