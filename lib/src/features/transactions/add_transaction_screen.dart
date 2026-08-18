import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../widgets/pressable.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/transaction_repository.dart';
import 'transfer_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.initialMode,
    this.editId,
  });

  final String? initialType;
  final String? initialMode;
  final int? editId;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late TxType _type;
  bool _external = false;
  final _amountCtrl = TextEditingController();
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _external = widget.initialMode == 'external';
    switch (widget.initialType) {
      case 'income':
        _type = TxType.income;
        _external = false;
        break;
      case 'transfer':
        _type = TxType.transfer;
        _external = false;
        break;
      default:
        _type = TxType.expense;
    }
  }
  db.Category? _category;
  db.Account? _account;
  DateTime _date = DateTime.now();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

  Future<void> _save() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final selectedAccount =
        _account ?? (accounts.isNotEmpty ? accounts.first : null);
    if (selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.of(context).addAccountFirst)),
      );
      return;
    }
    if (_amount <= 0) return;

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final repo = ref.read(transactionRepositoryProvider);
    if (widget.editId != null) {
      await repo.update(
        id: widget.editId!,
        amount: _amount,
        categoryId: _category?.id,
        accountId: selectedAccount.id,
        date: _date,
        note: note,
      );
      if (mounted) context.pop();
    } else {
      await repo.add(
        accountId: selectedAccount.id,
        categoryId: _category?.id,
        amount: _amount,
        currency: selectedAccount.currency,
        type: _type,
        date: _date,
        note: note,
      );
      if (mounted) context.go('/');
    }
  }

  void _hydrateFromEdit() {
    if (_hydrated || widget.editId == null) return;
    final txs = ref.read(allTransactionsProvider).valueOrNull;
    if (txs == null) return;
    final tx = txs.where((t) => t.id == widget.editId).firstOrNull;
    if (tx == null) return;
    _hydrated = true;
    _type = TxType.values[tx.type];
    _amountCtrl.text = tx.amount == tx.amount.roundToDouble()
        ? tx.amount.toStringAsFixed(0)
        : tx.amount.toString();
    _date = tx.date;
    _noteCtrl.text = tx.note ?? '';
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    _category = cats.where((c) => c.id == tx.categoryId).firstOrNull;
    final accs = ref.read(accountsProvider).valueOrNull ?? [];
    _account = accs.where((a) => a.id == tx.accountId).firstOrNull;
  }

  Future<void> _pickCategory() async {
    await ref.read(categoriesProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<db.Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _CategoryPicker(type: _type),
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickAccount() async {
    await ref.read(accountsProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<db.Account>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const _AccountPicker(),
    );
    if (picked != null) setState(() => _account = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirmDelete(Tr tr) async {
    final id = widget.editId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.deleteTxTitle),
        content: Text(tr.deleteTxBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53E3E),
            ),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(transactionRepositoryProvider).delete(id);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    ref.watch(categoriesProvider);
    ref.watch(accountsProvider);
    if (widget.editId != null && !_hydrated) {
      ref.watch(allTransactionsProvider);
      _hydrateFromEdit();
    }
    final currency = widget.editId != null && _account != null
        ? _account!.currency
        : ref.watch(settingsControllerProvider).baseCurrency;
    final sign = _type == TxType.expense
        ? '−'
        : (_type == TxType.income ? '+' : '');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.viewPaddingOf(context).top + 6,
          20,
          8 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconBtn(
                  icon: LucideIcons.arrowLeft,
                  onTap: () =>
                      widget.editId != null ? context.pop() : context.go('/'),
                ),
                Text(
                  widget.editId != null
                      ? '${tr.edit} ${tr.transactionSingular}'
                      : tr.newTransaction,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.primaryText,
                  ),
                ),
                widget.editId != null
                    ? _IconBtn(
                        icon: LucideIcons.trash2,
                        onTap: () => _confirmDelete(tr),
                      )
                    : const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.editId == null)
              _TypeTabs(
                type: _type,
                external: _external,
                onSelect: (t, {required bool external}) {
                  if (t == TxType.transfer) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                  setState(() {
                    _type = t;
                    _external = external;
                    if (t != TxType.transfer) _category = null;
                  });
                },
              ),
            Expanded(
              child: IndexedStack(
                index: _type == TxType.transfer ? 1 : 0,
                children: [
                  _txForm(
                    tr: tr,
                    currency: currency,
                    sign: sign,
                  ),
                  const TransferScreen(embedded: true),
                ],
              ),
            ),
            if (_type != TxType.transfer)
              SizedBox(
                width: double.infinity,
                child: ScaledElevatedButton(
                  onPressed: _save,
                  child: Text(tr.save),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _txForm({
    required Tr tr,
    required String currency,
    required String sign,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        children: [
          _AmountInput(
            controller: _amountCtrl,
            sign: sign,
            currency: currency,
          ),
          const SizedBox(height: 20),
          _FormBlock(
            rows: [
              _FormRow(
                icon: _category != null
                    ? lucideByKey(_category!.icon)
                    : LucideIcons.tag,
                well: _category != null ? Color(_category!.color) : null,
                label: tr.category,
                value: _category != null
                    ? tr.categoryName(_category!.name)
                    : tr.select,
                onTap: _pickCategory,
              ),
              _FormRow(
                icon: LucideIcons.creditCard,
                label: tr.account,
                value: _account?.name ??
                    (ref
                            .watch(accountsProvider)
                            .valueOrNull
                            ?.firstOrNull
                            ?.name ??
                        tr.selectShort),
                onTap: _pickAccount,
              ),
              _FormRow(
                icon: LucideIcons.calendar,
                label: tr.date,
                value: DateFormat('d MMM, HH:mm',
                        Localizations.localeOf(context).languageCode)
                    .format(_date),
                onTap: _pickDate,
              ),
              _FormRow(
                icon: LucideIcons.pencil,
                label: tr.note,
                value: _noteCtrl.text.isEmpty ? tr.add : _noteCtrl.text,
                onTap: _openNote,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openNote() async {
    final tr = Tr.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _noteCtrl.text);
        return AlertDialog(
          title: Text(tr.note),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(hintText: tr.enterNoteHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(tr.save),
            ),
          ],
        );
      },
    );
    if (result != null) setState(() => _noteCtrl.text = result);
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18,
            color: context.isDark ? Colors.white : AppColors.ink),
      ),
    );
  }
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs({
    required this.type,
    required this.external,
    required this.onSelect,
  });
  final TxType type;
  final bool external;
  final void Function(TxType type, {required bool external}) onSelect;

  int get _index => type == TxType.income
      ? 0
      : (type == TxType.expense && !external)
          ? 1
          : type == TxType.transfer
              ? 2
              : 3;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final labels = <String>[
      tr.income,
      tr.expense,
      tr.transferBetweenTab,
      tr.transferExternalTab,
    ];

    Widget pill(int a, int b) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            for (final i in [a, b])
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    switch (i) {
                      case 0:
                        onSelect(TxType.income, external: false);
                        return;
                      case 1:
                        onSelect(TxType.expense, external: false);
                        return;
                      case 2:
                        onSelect(TxType.transfer, external: false);
                        return;
                      default:
                        onSelect(TxType.expense, external: true);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: i == _index
                          ? (context.isDark ? AppColors.ink3 : AppColors.ink)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == _index
                            ? Colors.white
                            : context.mutedText,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        pill(0, 1),
        const SizedBox(height: 6),
        pill(2, 3),
      ],
    );
  }
}

class _AmountInput extends StatelessWidget {
  const _AmountInput({
    required this.controller,
    required this.sign,
    required this.currency,
  });

  final TextEditingController controller;
  final String sign;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(currency,
            style: TextStyle(fontSize: 14, color: context.faintText)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: context.isDark
                ? AppColors.lime
                : AppColors.limeAccent,
            letterSpacing: -2,
            height: 1,
          ),
          decoration: InputDecoration(
            hintText: '${sign.isEmpty ? '' : sign}0.00',
            hintStyle: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: context.primaryText.withValues(alpha: 0.25),
              letterSpacing: -2,
            ),
            prefixText: sign.isNotEmpty ? sign : null,
            prefixStyle: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: context.primaryText,
              letterSpacing: -2,
              height: 1,
            ),
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            filled: false,
          ),
        ),
      ],
    );
  }
}

class _FormBlock extends StatelessWidget {
  const _FormBlock({required this.rows});
  final List<_FormRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 1, color: context.divider),
          ],
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.icon,
    this.well,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color? well;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            if (well != null)
              ColorWellIcon(
                color: well!,
                icon: icon,
                size: 32,
                iconSize: 14,
                radius: 10,
              )
            else
              NeutralWellIcon(icon: icon),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 13, color: context.mutedText)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 16, color: context.faintText),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({required this.type});
  final TxType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    final cats = (async.valueOrNull ?? const <db.Category>[]).where((c) {
      final catType = CategoryType.values[c.type];
      if (type == TxType.expense) return catType != CategoryType.income;
      if (type == TxType.income) return catType != CategoryType.expense;
      return true;
    }).toList();
    final maxH = MediaQuery.sizeOf(context).height * 0.65;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.handleBar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Tr.of(context).category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              if (async.isLoading && cats.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final c in cats)
                      GestureDetector(
                        onTap: () => Navigator.pop(context, c),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorWellIcon(
                              color: Color(c.color),
                              icon: lucideByKey(c.icon),
                              size: 52,
                              iconSize: 22,
                              radius: 16,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Tr.of(context).categoryName(c.name),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: context.primaryText),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPicker extends ConsumerWidget {
  const _AccountPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accountsProvider);
    final accounts = async.valueOrNull ?? const <db.Account>[];
    final maxH = MediaQuery.sizeOf(context).height * 0.65;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.handleBar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Tr.of(context).account,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              if (async.isLoading && accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final a in accounts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ColorWellIcon(
                      color: Color(a.color),
                      icon: lucideByKey(a.icon),
                      size: 40,
                      iconSize: 18,
                      radius: 12,
                    ),
                    title: Text(a.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.primaryText)),
                    subtitle: Text(a.currency,
                        style: TextStyle(color: context.mutedText)),
                    onTap: () => Navigator.pop(context, a),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
