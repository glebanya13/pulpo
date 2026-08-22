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

Future<bool> confirmAssistantDrafts({
  required BuildContext context,
  required List<TransactionDraftFromAi> drafts,
  required db.Account account,
  required List<db.Category> categories,
  required Tr tr,
}) {
  return showModalBottomSheet<bool>(
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
  ).then((v) => v == true);
}

Future<int> saveAssistantDrafts({
  required WidgetRef ref,
  required List<TransactionDraftFromAi> drafts,
  required db.Account account,
  required Tr tr,
  String? receiptPath,
}) async {
  final cats = ref.read(categoriesProvider).valueOrNull ?? [];
  final repo = ref.read(transactionRepositoryProvider);
  var i = 0;
  for (final draft in drafts) {
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
  WidgetRef ref,
) async {
  final accounts = ref.read(accountsProvider).valueOrNull ?? [];
  if (accounts.isEmpty) return null;
  if (accounts.length == 1) return accounts.first;
  return showModalBottomSheet<db.Account>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final a in accounts)
              ListTile(
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

class AssistantConfirmSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
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
                      tr.aiVoiceConfirmCount(drafts.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: () => Navigator.pop(context, false),
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
              itemCount: drafts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = drafts[i];
                final type =
                    d.type == 'income' ? TxType.income : TxType.expense;
                final cat = matchCategory(d.categoryHint, type);
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
                                _Chip(text: account.name),
                                if (note.isNotEmpty) _Chip(text: note),
                                _Chip(
                                  text: DateFormat(
                                    'd MMM',
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ).format(d.date ?? DateTime.now()),
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
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr.aiVoiceApprove),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
    );
  }
}
