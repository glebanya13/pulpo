import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import 'app_bottom_sheet.dart';

/// Opens [child] in a consistent rounded picker sheet with handle bar + X button.
///
/// Use together with [showSimpleSheet] for the simplest call-site.
Future<T?> showSimpleSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showAppBottomSheet<T>(
    context: context,
    transparent: true,
    builder: builder,
  );
}

/// Rounded card for non-form picker/action sheets.
///
/// Provides a unified handle bar + close (×) button header and optional title.
/// The [child] should be a scrollable list, column, or any widget — it is wrapped
/// in [Flexible] so a [ListView] inside it gets a bounded height automatically.
class SimplePickerSheet extends StatelessWidget {
  const SimplePickerSheet({
    super.key,
    required this.child,
    this.title,
    this.maxHeightFraction = 0.72,
  });

  final Widget child;

  /// Optional title shown below the handle row.
  final String? title;

  /// Max fraction of screen height (default 0.72).
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * maxHeightFraction;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: context.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.rXxl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle + × ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: context.handleBar,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    _CloseButton(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
              ),

              // ── Optional title ──
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Content ──
              Flexible(child: child),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = context.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(Icons.close_rounded, size: 17, color: context.mutedText),
      ),
    );
  }
}
