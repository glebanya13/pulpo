part of 'monthly_calendar.dart';

/// 0 = day list, 1 = calendar grid, 2 = months of year.
const _kViewDay = 0;
const _kViewCalendar = 1;
const _kViewMonths = 2;

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.viewIndex,
    required this.onShift,
    required this.onTitleTap,
  });
  final DateTime month;
  final int viewIndex;
  final ValueChanged<int> onShift;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final title = viewIndex == _kViewMonths
        ? DateFormat('y', locale).format(month)
        : DateFormat('LLLL y', locale).format(month);
    final titleCapitalized =
        title.isEmpty ? title : title[0].toUpperCase() + title.substring(1);
    return Row(
      children: [
        _RoundNav(icon: LucideIcons.chevronLeft, onTap: () => onShift(-1)),
        const SizedBox(width: 8),
        Expanded(
          child: Pressable(
            onTap: onTitleTap,
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      titleCapitalized,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: context.mutedText,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _RoundNav(icon: LucideIcons.chevronRight, onTap: () => onShift(1)),
      ],
    );
  }
}

/// Segmented control — lime pill for active, icons like the mockup.
class _ViewTabs extends StatelessWidget {
  const _ViewTabs({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final tabs = <({IconData icon, String label})>[
      (icon: LucideIcons.sun, label: tr.calendarViewDay),
      (icon: LucideIcons.calendarDays, label: tr.calendarViewCalendar),
      (icon: LucideIcons.calendarRange, label: tr.calendarViewMonth),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 34,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.lime : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tabs[i].icon,
                            size: 15,
                            color: i == index
                                ? AppColors.ink
                                : context.primaryText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tabs[i].label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: i == index
                                  ? AppColors.ink
                                  : context.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Three outlined summary cards — income / expense / total.
class _MonthTotals extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: tr.income,
            value: formatMoney(income, currency),
            color: context.accent,
            icon: LucideIcons.arrowUpRight,
            hidden: settings.hideSummaryIncome,
            onToggleHide: () => notifier.setHideSummaryIncome(
              !settings.hideSummaryIncome,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: tr.expense,
            value: formatMoney(expense, currency),
            color: AppColors.danger,
            icon: LucideIcons.arrowDownRight,
            hidden: settings.hideSummaryExpense,
            onToggleHide: () => notifier.setHideSummaryExpense(
              !settings.hideSummaryExpense,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: tr.monthNet,
            value: formatMoney(net, currency, showSign: true),
            color: AppColors.totalBlue,
            icon: LucideIcons.equal,
            hidden: settings.hideSummaryNet,
            onToggleHide: () =>
                notifier.setHideSummaryNet(!settings.hideSummaryNet),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.hidden,
    required this.onToggleHide,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool hidden;
  final VoidCallback onToggleHide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 8, 7, 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Pressable(
                onTap: onToggleHide,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    // Visible → eye-off (tap to hide); hidden → eye (tap to show).
                    hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 15,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Scale down long amounts — never truncate with "…".
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                hidden ? kMaskedMoney : value,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundNav extends StatelessWidget {
  const _RoundNav({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: context.primaryText),
      ),
    );
  }
}
