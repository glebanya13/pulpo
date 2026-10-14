import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/pressable.dart';

/// Bottom sheet «облачко» — выбор дня, месяца и года для календаря.
Future<DateTime?> showCalendarDatePicker(
  BuildContext context, {
  required DateTime initial,
}) {
  return showAppBottomSheet<DateTime>(
    context: context,
    transparent: true,
    builder: (ctx) => _CalendarDatePickerSheet(initial: initial),
  );
}

class _CalendarDatePickerSheet extends StatefulWidget {
  const _CalendarDatePickerSheet({required this.initial});

  final DateTime initial;

  @override
  State<_CalendarDatePickerSheet> createState() =>
      _CalendarDatePickerSheetState();
}

class _CalendarDatePickerSheetState extends State<_CalendarDatePickerSheet> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
    _day = widget.initial.day;
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  DateTime get _selected => DateTime(_year, _month, _day.clamp(1, _daysInMonth));

  void _setMonth(int m) {
    setState(() {
      _month = m;
      if (_day > DateTime(_year, m + 1, 0).day) {
        _day = DateTime(_year, m + 1, 0).day;
      }
    });
  }

  void _shiftYear(int delta) => setState(() => _year += delta);

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final locale = Localizations.localeOf(context).toString();
    final cloudLabel = DateFormat.yMMMMd(locale).format(_selected);
    final monthNames = List.generate(
      12,
      (i) => DateFormat.MMM(locale).format(DateTime(_year, i + 1)),
    );
    final labels = tr.weekdayShort;
    final firstWeekday = DateTime(_year, _month, 1).weekday;
    final leading = firstWeekday - 1;
    final today = DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr.calendarPickDate,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.mutedText,
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.lime.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      cloudLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoundIconBtn(
                      icon: LucideIcons.chevronLeft,
                      onTap: () => _shiftYear(-1),
                    ),
                    Expanded(
                      child: Text(
                        '$_year',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.primaryText,
                        ),
                      ),
                    ),
                    _RoundIconBtn(
                      icon: LucideIcons.chevronRight,
                      onTap: () => _shiftYear(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 2.1,
                  ),
                  itemBuilder: (context, i) {
                    final m = i + 1;
                    final active = m == _month;
                    // Current real month gets the same soft lime wash as
                    // today's date in the day grid below.
                    final isCurrent =
                        today.year == _year && today.month == m;
                    return Pressable(
                      onTap: () => _setMonth(m),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.lime
                              : (isCurrent
                                  ? AppColors.lime.withValues(alpha: 0.25)
                                  : context.scaffoldBg),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          monthNames[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? AppColors.ink : context.primaryText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final l in labels)
                      Expanded(
                        child: Center(
                          child: Text(
                            l,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.faintText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 42,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, i) {
                    final dayIndex = i - leading + 1;
                    if (dayIndex < 1 || dayIndex > _daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final isSelected = dayIndex == _day;
                    final isToday = today.year == _year &&
                        today.month == _month &&
                        today.day == dayIndex;
                    return Pressable(
                      onTap: () => setState(() => _day = dayIndex),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.lime
                              : (isToday
                                  ? AppColors.lime.withValues(alpha: 0.25)
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$dayIndex',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.ink
                                : context.primaryText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Pressable(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.scaffoldBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tr.cancel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Pressable(
                        onTap: () => Navigator.pop(context, _selected),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tr.ok,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: context.primaryText),
          ),
        ),
      ),
    );
  }
}
