part of 'monthly_calendar.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.onShift,
    required this.onTitleTap,
    required this.calendarView,
    required this.onToggleCalendar,
  });
  final DateTime month;
  final ValueChanged<int> onShift;
  final VoidCallback onTitleTap;
  final bool calendarView;
  final VoidCallback onToggleCalendar;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).toString();
    // LLLL = stand-alone month (Август), MMMM = genitive in ru (августа).
    final title = DateFormat('LLLL y', locale).format(month);
    final titleCapitalized =
        title.isEmpty ? title : title[0].toUpperCase() + title.substring(1);
    return Row(
      children: [
        _NavBtn(icon: LucideIcons.chevronLeft, onTap: () => onShift(-1)),
        Expanded(
          child: Pressable(
            onTap: onTitleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                titleCapitalized,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
            ),
          ),
        ),
        _NavBtn(icon: LucideIcons.chevronRight, onTap: () => onShift(1)),
        const SizedBox(width: 4),
        Pressable(
          onTap: onToggleCalendar,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: calendarView
                  ? AppColors.lime.withValues(alpha: 0.2)
                  : context.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendarDays,
                  size: 16,
                  color: calendarView
                      ? context.accent
                      : context.mutedText,
                ),
                const SizedBox(width: 6),
                Text(
                  tr.calendar,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: calendarView
                        ? context.accent
                        : context.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthTotals extends StatelessWidget {
  const _MonthTotals({
    required this.income,
    required this.expense,
    required this.net,
    required this.currency,
  });
  final double income;
  final double expense;
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Mini(
              label: tr.income,
              value: formatMoney(income, currency),
              color: context.accent),
          Container(width: 1, height: 28, color: context.divider),
          _Mini(
              label: tr.expense,
              value: formatMoney(expense, currency),
              color: AppColors.danger),
          Container(width: 1, height: 28, color: context.divider),
          _Mini(
              label: tr.monthNet,
              value: formatMoney(net, currency),
              color: context.primaryText),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.mutedText),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: context.primaryText),
          ),
        ),
      ),
    );
  }
}
