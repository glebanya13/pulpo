part of 'monthly_calendar.dart';

class _DaySheetQuickChip extends StatelessWidget {
  const _DaySheetQuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          button: true,
          child: Pressable(
            onTap: onTap,
            scale: 0.97,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySheet extends ConsumerWidget {
  const _DaySheet({
    required this.day,
    required this.onDeleteTx,
  });

  final DateTime day;
  final ValueChanged<db.Transaction> onDeleteTx;

  void _openAdd(
    BuildContext context, {
    required String type,
    String? mode,
  }) {
    final router = GoRouter.of(context);
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    Navigator.of(context).pop();
    final uri = StringBuffer('/add?date=$y-$m-$d&type=$type');
    if (mode != null) uri.write('&mode=$mode');
    router.push(uri.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMMd(locale).format(day);
    final allTxs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];
    final txs = allTxs
        .where(
          (t) =>
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day,
        )
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: AppSpacing.sheetOnTabScreen(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: context.handleBar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.primaryText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (txs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  tr.noTxThisDay,
                  style: TextStyle(color: context.mutedText),
                ),
              ),
            )
          else
            _DaySheetTxList(
              txs: txs,
              onDeleteTx: onDeleteTx,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              _DaySheetQuickChip(
                icon: LucideIcons.plus,
                label: tr.income,
                onTap: () => _openAdd(context, type: 'income'),
              ),
              const SizedBox(width: 6),
              _DaySheetQuickChip(
                icon: LucideIcons.minus,
                label: tr.expense,
                onTap: () => _openAdd(context, type: 'expense'),
              ),
              const SizedBox(width: 6),
              _DaySheetQuickChip(
                icon: LucideIcons.arrowLeftRight,
                label: tr.transferBetweenShort,
                onTap: () => _openAdd(context, type: 'transfer'),
              ),
              const SizedBox(width: 6),
              _DaySheetQuickChip(
                icon: LucideIcons.send,
                label: tr.transferExternal,
                onTap: () => _openAdd(context, type: 'expense', mode: 'external'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySheetTxList extends StatelessWidget {
  const _DaySheetTxList({
    required this.txs,
    required this.onDeleteTx,
  });

  final List<db.Transaction> txs;
  final ValueChanged<db.Transaction> onDeleteTx;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.45;
    const rowGap = 8.0;
    const estRowHeight = 68.0;
    final contentHeight =
        txs.length * estRowHeight + (txs.length - 1) * rowGap;

    Widget tile(int i) {
      final t = txs[i];
      return Dismissible(
        key: ValueKey(t.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: EdgeInsets.only(bottom: i < txs.length - 1 ? rowGap : 0),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 20,
          ),
        ),
        onDismissed: (_) => onDeleteTx(t),
        child: Pressable(
          onTap: () {
            Navigator.of(context).pop();
            context.push('/tx/${t.id}');
          },
          child: TransactionTile(tx: t),
        ),
      );
    }

    if (contentHeight <= maxHeight) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < txs.length; i++) tile(i)],
      );
    }

    return SizedBox(
      height: maxHeight,
      child: ListView.builder(
        itemCount: txs.length,
        itemBuilder: (ctx, i) => tile(i),
      ),
    );
  }
}

class _TxActionTile extends StatelessWidget {
  const _TxActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : context.primaryText;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Calendar pill amounts — compact number only (no currency symbol).
String _shortMoney(double value) => formatAmountBare(value);
