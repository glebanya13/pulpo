import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/tr.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class GoalEditorScreen extends ConsumerStatefulWidget {
  const GoalEditorScreen({super.key, this.existingId});
  final int? existingId;
  bool get isEdit => existingId != null;

  @override
  ConsumerState<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends ConsumerState<GoalEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _targetFocus = FocusNode();
  final _currentFocus = FocusNode();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.isEdit) {
      final goals = ref.read(goalsProvider).valueOrNull ?? [];
      final existing =
          goals.where((g) => g.id == widget.existingId).firstOrNull;
      if (existing != null) {
        _nameCtrl.text = existing.name;
        _targetCtrl.text = existing.targetAmount.toString();
        _currentCtrl.text = existing.currentAmount.toString();
        _initialized = true;
      }
    } else {
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _targetFocus.dispose();
    _currentFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target =
        double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || target == null || target <= 0 || _saving) return;
    final current =
        double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _saving = true);
    try {
      final repo = ref.read(goalRepositoryProvider);
      if (widget.isEdit) {
        final existing =
            (ref.read(goalsProvider).valueOrNull ?? [])
                .where((g) => g.id == widget.existingId)
                .firstOrNull;
        await repo.update(
          id: widget.existingId!,
          name: name,
          targetAmount: target,
          currentAmount: current,
          targetDate: existing?.targetDate,
          clearTargetDate: existing?.targetDate == null,
        );
      } else {
        final currency = ref.read(settingsControllerProvider).baseCurrency;
        await repo.add(
          name: name,
          targetAmount: target,
          currency: currency,
          currentAmount: current,
          targetDate: null,
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: widget.isEdit ? tr.editGoal : tr.newGoal,
          onBack: () => context.pop(),
        ),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: !widget.isEdit,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _targetFocus.requestFocus(),
            decoration: InputDecoration(labelText: tr.goalName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            focusNode: _targetFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _currentFocus.requestFocus(),
            decoration: InputDecoration(labelText: tr.goalTarget),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currentCtrl,
            focusNode: _currentFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(labelText: tr.goalSaved),
          ),
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
