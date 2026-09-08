import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

/// Scrollable form inside a rounded sheet card.
///
/// Use with [showAppBottomSheet] `transparent: true` so the page behind
/// stays visible and the card sits above the keyboard cleanly.
class KeyboardFormSheet extends StatelessWidget {
  const KeyboardFormSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.showClose = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.viewInsets.bottom;
    final topSafe = media.padding.top;

    // Card height is capped so X is always reachable regardless of keyboard size.
    const handleH = 54.0;
    final availableH = media.size.height - inset - topSafe - 16;
    final maxCardH = availableH.clamp(200.0, media.size.height * 0.62);
    final maxScrollH = (maxCardH - handleH).clamp(80.0, double.infinity);

    void dismiss() => Navigator.of(context).pop();

    return GestureDetector(
      // Tap anywhere outside the card → close.
      behavior: HitTestBehavior.opaque,
      onTap: dismiss,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            // Absorb taps on the card itself so they don't bubble to dismiss.
            onTap: () {},
            child: Material(
              color: context.surface,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.rXxl),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme:
                      Theme.of(context).inputDecorationTheme.copyWith(
                        fillColor: context.scaffoldBg,
                      ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Handle bar + close button (drag down → close) ──
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: (d) {
                        if ((d.primaryVelocity ?? 0) > 200) dismiss();
                      },
                      child: Padding(
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
                            _CloseButton(onTap: dismiss),
                          ],
                        ),
                      ),
                    ),

                    // ── Form content ──
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxScrollH),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: padding,
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
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
