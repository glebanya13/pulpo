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
  });

  final List<TransactionDraftFromAi> drafts;
  final List<db.Account> accounts;
}

Future<AssistantConfirmResult?> confirmAssistantDrafts({
  required BuildContext context,
  required List<TransactionDraftFromAi> drafts,
  required db.Account account,
  required List<db.Category> categories,
  required Tr tr,
}) {
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
  String? receiptPath,
}) async {
  assert(drafts.length == accounts.length);
  final cats = ref.read(categoriesProvider).valueOrNull ?? [];
  final repo = ref.read(transactionRepositoryProvider);
  var i = 0;
  for (final draft in drafts) {
    final account = accounts[i];
    final type = draft.type == 'income' ? TxType.income : TxType.expense;
    final cat = matchAiCategory(draft.categoryHint, cats, tr, type);
    final note = draft.note?.trim().isNotEmpty == true
        ? draft.note!.trim()
        : draft.merchant?.trim();
    await repo.add(
      accountId: account.id,
      categoryId: cat?.id,
      amount: draft.amount!,
      currency: draft.currency ?? account.currency,
      type: type,
      date: draft.date ?? DateTime.now(),
      note: note,
      receiptPath: i == 0 ? receiptPath : null,
    );
    i++;
  }
  return drafts.length;
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
  return showModalBottomSheet<db.Account>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      final tr = Tr.of(ctx);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                tr.selectAccount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ctx.primaryText,
                ),
              ),
            ),
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
  });

  final List<TransactionDraftFromAi> drafts;
  final db.Account account;
  final List<db.Category> categories;
  final db.Category? Function(String? hint, TxType type) matchCategory;

  @override
  ConsumerState<AssistantConfirmSheet> createState() =>
      _AssistantConfirmSheetState();
}

class _AssistantConfirmSheetState extends ConsumerState<AssistantConfirmSheet> {
  late List<TransactionDraftFromAi> _drafts;
  late List<db.Account> _accounts;

  @override
  void initState() {
    super.initState();
    _drafts = List<TransactionDraftFromAi>.from(widget.drafts);
    _accounts = List<db.Account>.filled(
      widget.drafts.length,
      widget.account,
      growable: true,
    );
  }

  Future<void> _pickAccount(int index) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    if (accounts.isEmpty) return;
    final picked = await showAccountPickerSheet(context, accounts);
    if (picked == null || !mounted) return;
    setState(() => _accounts[index] = picked);
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
                final type =
                    d.type == 'income' ? TxType.income : TxType.expense;
                final cat = widget.matchCategory(d.categoryHint, type);
                final note = d.note?.trim().isNotEmpty == true
                    ? d.note!
                    : (d.merchant ?? '');
                final amount = d.amount ?? 0;
                final sign = type == TxType.income ? '+' : '−';
                final color = type == TxType.income
                    ? AppColors.income
                    : AppColors.expense;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      ColorWellIcon(
                        color: cat != null
                            ? Color(cat.color)
                            : AppColors.violet,
                        icon: cat != null
                            ? lucideByKey(cat.icon)
                            : LucideIcons.circle,
                        size: 40,
                        iconSize: 18,
                        radius: 12,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat != null
                                  ? tr.categoryName(cat.name)
                                  : (d.categoryHint ?? tr.other),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _Chip(
                                  text: account.name,
                                  onTap: () => _pickAccount(i),
                                ),
                                if (note.isNotEmpty) _Chip(text: note),
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
                      Text(
                        '$sign${formatMoney(amount, d.currency ?? account.currency)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
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
              onPressed: () => Navigator.pop(
                context,
                AssistantConfirmResult(
                  drafts: List.unmodifiable(_drafts),
                  accounts: List.unmodifiable(_accounts),
                ),
              ),
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
