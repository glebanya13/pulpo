import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/ai/ai_models.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../widgets/pressable.dart';
import '../../widgets/simple_picker_sheet.dart';

db.Category? matchAiCategory(
  String? hint,
  List<db.Category> cats,
  Tr tr,
  TxType type,
) {
  if (hint == null || hint.trim().isEmpty) return null;
  final h = hint.toLowerCase().trim();
  final filtered = cats.where((c) {
    final catType = CategoryType.values[c.type];
    if (type == TxType.expense) return catType != CategoryType.income;
    if (type == TxType.income) return catType != CategoryType.expense;
    return true;
  });
  for (final c in filtered) {
    if (c.name.toLowerCase() == h) return c;
    if (tr.categoryName(c.name).toLowerCase() == h) return c;
  }
  for (final c in filtered) {
    final n = tr.categoryName(c.name).toLowerCase();
    if (n.contains(h) || h.contains(n)) return c;
  }
  return null;
}

db.Account? matchAiAccount(String? hint, List<db.Account> accounts) {
  if (hint == null || hint.trim().isEmpty || accounts.isEmpty) return null;
  final h = hint.toLowerCase().trim();
  final open = accounts.where((a) => !a.isArchived).toList();
  for (final a in open) {
    if (a.name.toLowerCase() == h) return a;
  }
  // Longest partial match first — "карта тинькофф" vs "карта".
  final partial = open.where((a) {
    final n = a.name.toLowerCase();
    return n.contains(h) || h.contains(n);
  }).toList()
    ..sort((a, b) => b.name.length.compareTo(a.name.length));
  return partial.isEmpty ? null : partial.first;
}

List<db.Account> resolveDraftAccounts({
  required List<TransactionDraftFromAi> drafts,
  required List<db.Account> accounts,
  required db.Account fallback,
}) {
  return [
    for (final d in drafts) matchAiAccount(d.accountHint, accounts) ?? fallback,
  ];
}

List<db.Account?> resolveDraftToAccounts({
  required List<TransactionDraftFromAi> drafts,
  required List<db.Account> accounts,
}) {
  return [
    for (final d in drafts)
      d.isTransfer ? matchAiAccount(d.toAccountHint, accounts) : null,
  ];
}

TransactionDraftFromAi receiptToDraft(ReceiptParseResult receipt) {
  return TransactionDraftFromAi(
    amount: receipt.amount,
    currency: receipt.currency,
    dateIso: receipt.dateIso,
    note: receipt.note,
    merchant: receipt.merchant,
    categoryHint: receipt.categoryHint,
    type: receipt.type,
  );
}

class AssistantConfirmResult {
  const AssistantConfirmResult({
    required this.drafts,
    required this.accounts,
    this.toAccounts = const [],
  });

  final List<TransactionDraftFromAi> drafts;
  final List<db.Account> accounts;
  /// Parallel to [drafts]; non-null only for transfers.
  final List<db.Account?> toAccounts;
}

Future<AssistantConfirmResult?> confirmAssistantDrafts({
  required BuildContext context,
  required List<TransactionDraftFromAi> drafts,
  required db.Account account,
  required List<db.Category> categories,
  required Tr tr,
  List<db.Account>? allAccounts,
}) {
  final accounts = allAccounts ?? const <db.Account>[];
  return showModalBottomSheet<AssistantConfirmResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => AssistantConfirmSheet(
      drafts: drafts,
      account: account,
      allAccounts: accounts,
      categories: categories,
      matchCategory: (hint, type) =>
          matchAiCategory(hint, categories, tr, type),
    ),
  );
}

Future<int> saveAssistantDrafts({
  required WidgetRef ref,
  required List<TransactionDraftFromAi> drafts,
  required List<db.Account> accounts,
  required Tr tr,
  List<db.Account?> toAccounts = const [],
  String? receiptPath,
}) async {
  assert(drafts.length == accounts.length);
  final cats = ref.read(categoriesProvider).valueOrNull ?? [];
  final repo = ref.read(transactionRepositoryProvider);
  var saved = 0;
  for (var i = 0; i < drafts.length; i++) {
    final draft = drafts[i];
    final amount = draft.amount;
    if (amount == null || amount <= 0) continue;
    final account = accounts[i];
    final to = i < toAccounts.length ? toAccounts[i] : null;
    if (draft.isTransfer) {
      if (to == null || to.id == account.id) {
        throw StateError(tr.aiTransferNeedsDestination);
      }
      await repo.addTransfer(
        fromAccountId: account.id,
        toAccountId: to.id,
        fromAmount: amount,
        toAmount: amount,
        fromCurrency: draft.currency ?? account.currency,
        toCurrency: draft.currency ?? to.currency,
        date: draft.date ?? DateTime.now(),
        note: draft.note?.trim().isNotEmpty == true
            ? draft.note!.trim()
            : draft.merchant?.trim(),
      );
    } else {
      final type = draft.type == 'income' ? TxType.income : TxType.expense;
      final cat = matchAiCategory(draft.categoryHint, cats, tr, type);
      final note = draft.note?.trim().isNotEmpty == true
          ? draft.note!.trim()
          : draft.merchant?.trim();
      await repo.add(
        accountId: account.id,
        categoryId: cat?.id,
        amount: amount,
        currency: draft.currency ?? account.currency,
        type: type,
        date: draft.date ?? DateTime.now(),
        note: note,
        receiptPath: saved == 0 ? receiptPath : null,
      );
    }
    saved++;
  }
  return saved;
}

Future<db.Account?> pickAssistantAccount(
  BuildContext context,
  WidgetRef ref, {
  bool forcePicker = false,
}) async {
  final accounts = ref.read(accountsProvider).valueOrNull ?? [];
  if (accounts.isEmpty) return null;
  if (!forcePicker && accounts.length == 1) return accounts.first;
  return showAccountPickerSheet(context, accounts);
}

Future<db.Account?> showAccountPickerSheet(
  BuildContext context,
  List<db.Account> accounts,
) {
  return showSimpleSheet<db.Account>(
    context: context,
    builder: (ctx) {
      final tr = Tr.of(ctx);
      return SimplePickerSheet(
        title: tr.selectAccount,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            for (final a in accounts)
              ListTile(
                leading: ColorWellIcon(
                  color: Color(a.color),
                  icon: lucideByKey(a.icon),
                  size: 40,
                  iconSize: 18,
                  radius: 12,
                ),
                title: Text(a.name),
                subtitle: Text(a.currency),
                onTap: () => Navigator.pop(ctx, a),
              ),
          ],
        ),
      );
    },
  );
}

class AssistantConfirmSheet extends ConsumerStatefulWidget {
  const AssistantConfirmSheet({
    super.key,
    required this.drafts,
    required this.account,
    required this.categories,
    required this.matchCategory,
    this.allAccounts = const [],
  });

  final List<TransactionDraftFromAi> drafts;
  final db.Account account;
  final List<db.Account> allAccounts;
  final List<db.Category> categories;
  final db.Category? Function(String? hint, TxType type) matchCategory;

  @override
  ConsumerState<AssistantConfirmSheet> createState() =>
      _AssistantConfirmSheetState();
}

class _AssistantConfirmSheetState extends ConsumerState<AssistantConfirmSheet> {
  late List<TransactionDraftFromAi> _drafts;
  late List<db.Account> _accounts;
  late List<db.Account?> _toAccounts;

  @override
  void initState() {
    super.initState();
    _drafts = List<TransactionDraftFromAi>.from(widget.drafts);
    final pool = widget.allAccounts.isNotEmpty
        ? widget.allAccounts
        : [widget.account];
    _accounts = resolveDraftAccounts(
      drafts: _drafts,
      accounts: pool,
      fallback: widget.account,
    );
    _toAccounts = resolveDraftToAccounts(
      drafts: _drafts,
      accounts: pool,
    );
  }

  Future<void> _pickAccount(int index, {required bool to}) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    if (accounts.isEmpty) return;
    final picked = await showAccountPickerSheet(context, accounts);
    if (picked == null || !mounted) return;
    setState(() {
      if (to) {
        _toAccounts[index] = picked;
      } else {
        _accounts[index] = picked;
      }
    });
  }

  Future<void> _pickDate(int index) async {
    final current = _drafts[index].date ?? DateTime.now();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null || !mounted) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      _drafts[index] = _drafts[index].copyWith(dateIso: iso);
    });
  }

  Future<void> _editAmount(int index) async {
    final tr = Tr.of(context);
    final current = _drafts[index].amount;
    final ctrl = TextEditingController(
      text: current == null
          ? ''
          : (current == current.roundToDouble()
              ? current.toStringAsFixed(0)
              : current.toStringAsFixed(2)),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.aiEditAmount),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: tr.enterAmount),
          onSubmitted: (v) =>
              Navigator.pop(dctx, double.tryParse(v.replaceAll(',', '.'))),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dctx,
              double.tryParse(ctrl.text.replaceAll(',', '.')),
            ),
            child: Text(tr.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result <= 0 || !mounted) return;
    setState(() {
      _drafts[index] = _drafts[index].copyWith(amount: result);
    });
  }

  Future<void> _editNote(int index) async {
    final tr = Tr.of(context);
    final d = _drafts[index];
    final ctrl = TextEditingController(
      text: d.note?.trim().isNotEmpty == true
          ? d.note!
          : (d.merchant ?? ''),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.aiEditNote),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: tr.note),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, ctrl.text.trim()),
            child: Text(tr.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _drafts[index] = _drafts[index].copyWith(note: result);
    });
  }

  Future<void> _pickCategory(int index) async {
    final d = _drafts[index];
    if (d.isTransfer) return;
    final tr = Tr.of(context);
    final type = d.type == 'income' ? TxType.income : TxType.expense;
    final options = widget.categories.where((c) {
      final catType = CategoryType.values[c.type];
      if (type == TxType.expense) return catType != CategoryType.income;
      return catType != CategoryType.expense;
    }).toList();
    final picked = await showSimpleSheet<db.Category>(
      context: context,
      builder: (ctx) => SimplePickerSheet(
        title: tr.category,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            for (final c in options)
              ListTile(
                leading: ColorWellIcon(
                  color: Color(c.color),
                  icon: lucideByKey(c.icon),
                  size: 40,
                  iconSize: 18,
                  radius: 12,
                ),
                title: Text(tr.categoryName(c.name)),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _drafts[index] = _drafts[index].copyWith(
        categoryHint: tr.categoryName(picked.name),
      );
    });
  }

  Future<void> _pickType(int index) async {
    final tr = Tr.of(context);
    final picked = await showSimpleSheet<String>(
      context: context,
      builder: (ctx) => SimplePickerSheet(
        title: tr.aiVoiceConfirmTitle,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            for (final entry in [
              ('expense', tr.expense),
              ('income', tr.income),
              ('transfer', tr.transfer),
            ])
              ListTile(
                title: Text(entry.$2),
                onTap: () => Navigator.pop(ctx, entry.$1),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _drafts[index] = _drafts[index].copyWith(type: picked);
      if (picked != 'transfer') {
        _toAccounts[index] = null;
      }
    });
  }

  void _removeDraft(int index) {
    if (_drafts.length <= 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _drafts.removeAt(index);
      _accounts.removeAt(index);
      _toAccounts.removeAt(index);
    });
  }

  bool get _canApprove {
    if (_drafts.isEmpty) return false;
    for (var i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      if (d.amount == null || d.amount! <= 0) return false;
      if (d.isTransfer) {
        final to = _toAccounts[i];
        if (to == null || to.id == _accounts[i].id) return false;
      }
    }
    return true;
  }

  void _onApprove() {
    final tr = Tr.of(context);
    if (!_canApprove) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.aiTransferNeedsDestination)),
      );
      return;
    }
    Navigator.pop(
      context,
      AssistantConfirmResult(
        drafts: List.unmodifiable(_drafts),
        accounts: List.unmodifiable(_accounts),
        toAccounts: List.unmodifiable(_toAccounts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.checkCheck,
                    size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.aiVoiceConfirmTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                    Text(
                      tr.aiVoiceConfirmCount(_drafts.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: () => Navigator.pop(context),
                child: Icon(LucideIcons.x, color: context.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _drafts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = _drafts[i];
                final account = _accounts[i];
                final toAccount = _toAccounts[i];
                final isTransfer = d.isTransfer;
                final type = d.type == 'income'
                    ? TxType.income
                    : (isTransfer ? TxType.transfer : TxType.expense);
                final cat = isTransfer
                    ? null
                    : widget.matchCategory(d.categoryHint, type);
                final note = d.note?.trim().isNotEmpty == true
                    ? d.note!
                    : (d.merchant ?? '');
                final amount = d.amount ?? 0;
                final sign = isTransfer
                    ? ''
                    : (type == TxType.income ? '+' : '−');
                final color = isTransfer
                    ? context.primaryText
                    : (type == TxType.income
                        ? AppColors.income
                        : AppColors.expense);
                final typeLabel = isTransfer
                    ? tr.transfer
                    : (type == TxType.income ? tr.income : tr.expense);
                final categoryLabel = isTransfer
                    ? null
                    : (cat != null
                        ? tr.categoryName(cat.name)
                        : (d.categoryHint?.trim().isNotEmpty == true
                            ? d.categoryHint!
                            : tr.other));
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pressable(
                        onTap: isTransfer ? null : () => _pickCategory(i),
                        child: ColorWellIcon(
                          color: cat != null
                              ? Color(cat.color)
                              : AppColors.violet,
                          icon: cat != null
                              ? lucideByKey(cat.icon)
                              : (isTransfer
                                  ? LucideIcons.arrowLeftRight
                                  : LucideIcons.circle),
                          size: 40,
                          iconSize: 18,
                          radius: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _Chip(
                                  text: typeLabel,
                                  onTap: () => _pickType(i),
                                ),
                                if (categoryLabel != null)
                                  _Chip(
                                    text: categoryLabel,
                                    onTap: () => _pickCategory(i),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _Chip(
                                  text: isTransfer
                                      ? '${account.name} →'
                                      : account.name,
                                  onTap: () =>
                                      _pickAccount(i, to: false),
                                ),
                                if (isTransfer)
                                  _Chip(
                                    text: toAccount?.name ??
                                        tr.selectAccount,
                                    onTap: () =>
                                        _pickAccount(i, to: true),
                                  ),
                                _Chip(
                                  text: note.isNotEmpty
                                      ? note
                                      : tr.aiEditNote,
                                  onTap: () => _editNote(i),
                                ),
                                _Chip(
                                  text: DateFormat('d MMM', locale)
                                      .format(d.date ?? DateTime.now()),
                                  onTap: () => _pickDate(i),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Pressable(
                            onTap: () => _editAmount(i),
                            child: Text(
                              '$sign${formatMoney(amount, d.currency ?? account.currency)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: color,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    color.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Pressable(
                            onTap: () => _removeDraft(i),
                            child: Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: context.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ScaledElevatedButton(
              onPressed: _canApprove ? _onApprove : null,
              child: Text(tr.aiVoiceApprove),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(8),
        border: onTap != null
            ? Border.all(color: context.mutedText.withValues(alpha: 0.22))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.mutedText,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: context.mutedText,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return Pressable(onTap: onTap, child: child);
  }
}
