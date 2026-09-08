import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import '../../widgets/simple_picker_sheet.dart';

class BudgetEditorScreen extends ConsumerStatefulWidget {
  const BudgetEditorScreen({super.key, this.existingId});
  final int? existingId;
  bool get isEdit => existingId != null;

  @override
  ConsumerState<BudgetEditorScreen> createState() =>
      _BudgetEditorScreenState();
}

class _BudgetEditorScreenState extends ConsumerState<BudgetEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int _period = 1;
  bool _rollover = false;
  Set<int> _selectedCats = {};
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.isEdit) {
      final budgets = ref.read(budgetsProvider).valueOrNull ?? [];
      final existing =
          budgets.where((b) => b.id == widget.existingId).firstOrNull;
      if (existing != null) {
        _nameCtrl.text = existing.name;
        _amountCtrl.text = existing.amount.toString();
        _period = existing.period;
        _rollover = existing.rollover;
        _selectedCats =
            (jsonDecode(existing.categoryIdsJson) as List).cast<int>().toSet();
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

  List<db.Category> get _expenseCats =>
      (ref.read(categoriesProvider).valueOrNull ?? [])
          .where((c) =>
              CategoryType.values[c.type] == CategoryType.expense ||
              CategoryType.values[c.type] == CategoryType.both)
          .toList();

  Future<void> _pickCategories() async {
    final picked = await _pickBudgetCategories(
      context,
      selected: _selectedCats,
      expenseCats: _expenseCats,
    );
    if (picked != null) setState(() => _selectedCats = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (_nameCtrl.text.trim().isEmpty || amount <= 0 || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(budgetRepositoryProvider);
      final catList = _selectedCats.toList();
      if (widget.isEdit) {
        await repo.update(
          id: widget.existingId!,
          name: _nameCtrl.text.trim(),
          amount: amount,
          period: _period,
          categoryIds: catList,
          rollover: _rollover,
        );
      } else {
        final currency = ref.read(settingsControllerProvider).baseCurrency;
        await repo.add(
          name: _nameCtrl.text.trim(),
          amount: amount,
          currency: currency,
          period: _period,
          categoryIds: catList,
          rollover: _rollover,
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
        title: Text(tr.deleteBudgetTitle),
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
    await ref.read(budgetRepositoryProvider).delete(widget.existingId!);
    if (mounted) context.pop();
  }

  String _categoryLabel(List<db.Category> cats) {
    final tr = Tr.of(context);
    if (_selectedCats.isEmpty) return tr.budgetCategoriesAll;
    final names = [
      for (final c in cats)
        if (_selectedCats.contains(c.id)) tr.categoryName(c.name),
    ];
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final expenseCats = ref.watch(categoriesProvider).valueOrNull == null
        ? <db.Category>[]
        : _expenseCats;

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: widget.isEdit ? tr.editBudget : tr.newBudget,
          onBack: () => context.pop(),
        ),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: !widget.isEdit,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: tr.budgetName),
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
          DropdownButtonFormField<int>(
            key: ValueKey(_period),
            initialValue: _period,
            decoration: InputDecoration(labelText: tr.periodicity),
            items: [
              DropdownMenuItem(value: 0, child: Text(tr.freqWeekly)),
              DropdownMenuItem(value: 1, child: Text(tr.monthlyLabel)),
              DropdownMenuItem(value: 3, child: Text(tr.yearlyLabel)),
            ],
            onChanged: (v) => setState(() => _period = v ?? 1),
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: _pickCategories,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: tr.budgetCategories,
                suffixIcon: Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: context.faintText,
                ),
              ),
              child: Text(
                _categoryLabel(expenseCats),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: context.primaryText,
                ),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _rollover,
            onChanged: (v) => setState(() => _rollover = v),
            title: Text(tr.budgetRollover),
            subtitle: Text(tr.budgetRolloverDesc),
          ),
          const SizedBox(height: 12),
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

Future<Set<int>?> _pickBudgetCategories(
  BuildContext context, {
  required Set<int> selected,
  required List<db.Category> expenseCats,
}) {
  var local = Set<int>.from(selected);
  final tr = Tr.of(context);

  return showSimpleSheet<Set<int>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => SimplePickerSheet(
        title: tr.budgetCategories,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                itemCount: expenseCats.length + 1,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: ctx.divider),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final all = local.isEmpty;
                    return Pressable(
                      onTap: () => setSt(() => local.clear()),
                      scale: 0.98,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tr.budgetCategoriesAll,
                          style: TextStyle(
                            fontWeight: all
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: ctx.primaryText,
                          ),
                        ),
                        trailing: all
                            ? Icon(LucideIcons.check,
                                color: ctx.accent, size: 20)
                            : null,
                      ),
                    );
                  }
                  final c = expenseCats[i - 1];
                  final on = local.contains(c.id);
                  return Pressable(
                    onTap: () => setSt(() {
                      if (on) {
                        local.remove(c.id);
                      } else {
                        local.add(c.id);
                      }
                    }),
                    scale: 0.98,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tr.categoryName(c.name),
                        style: TextStyle(
                          fontWeight:
                              on ? FontWeight.w700 : FontWeight.w500,
                          color: ctx.primaryText,
                        ),
                      ),
                      trailing: on
                          ? Icon(LucideIcons.check,
                              color: ctx.accent, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ScaledElevatedButton(
                onPressed: () => Navigator.pop(ctx, local),
                child: Text(tr.done),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
