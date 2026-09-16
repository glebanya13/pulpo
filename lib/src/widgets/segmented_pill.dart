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
  });

  final List<SegmentedPillOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          _option(context, options[i]),
        ],
      ],
    );
  }

  Widget _option(BuildContext context, SegmentedPillOption<T> option) {
    final active = option.value == value;
    return Expanded(
      child: Pressable(
        onTap: () => onChanged(option.value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.lime : context.scaffoldBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.ink : context.primaryText,
            ),
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
