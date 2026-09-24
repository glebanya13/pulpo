import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'pressable.dart';

/// A row of pill-shaped toggle options — the selected one is filled with the
/// lime accent. Used instead of dropdowns for short enum-like choices
/// (periodicity, transaction type, …).
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.spacing = 8,
    /// When true, pills size to their label and scroll horizontally instead of
    /// sharing equal width (avoids ellipsis on long localized strings).
    this.scrollable = false,
    /// When > 1, lay out options in a fixed column grid (e.g. 2 → 2×N).
    /// Ignored when [scrollable] is true.
    this.columns = 0,
  });

  final List<SegmentedPillOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double spacing;
  final bool scrollable;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (!scrollable && columns > 1) {
      final rows = <Widget>[];
      for (var i = 0; i < options.length; i += columns) {
        if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
        rows.add(
          Row(
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: spacing),
                Expanded(
                  child: i + c < options.length
                      ? _option(context, options[i + c], expand: true)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      }
      return Column(children: rows);
    }

    final row = Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          scrollable
              ? _option(context, options[i], expand: false)
              : Expanded(child: _option(context, options[i], expand: true)),
        ],
      ],
    );
    if (!scrollable) return row;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: row,
    );
  }

  Widget _option(
    BuildContext context,
    SegmentedPillOption<T> option, {
    required bool expand,
  }) {
    final active = option.value == value;
    return Pressable(
      onTap: () => onChanged(option.value),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 14,
          horizontal: expand ? 8 : 16,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.lime : context.scaffoldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          option.label,
          maxLines: 1,
          softWrap: false,
          overflow: expand ? TextOverflow.ellipsis : TextOverflow.visible,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.ink : context.primaryText,
          ),
        ),
      ),
    );
  }
}

class SegmentedPillOption<T> {
  const SegmentedPillOption({required this.value, required this.label});

  final T value;
  final String label;
}
