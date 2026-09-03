import 'package:flutter/material.dart';

import '../core/l10n/tr.dart';
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.viewInsets.bottom;
    final doneH = inset > 0 ? 48.0 : 0.0;
    final topSafe = media.padding.top;
    // Card grows from the bottom; leave room for status bar + keyboard + Done.
    final maxH = (media.size.height - inset - doneH - topSafe - 12)
        .clamp(200.0, media.size.height * 0.92);

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
              fillColor: context.scaffoldBg,
            ),
          ),
          child: Material(
            color: context.surface,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.rXxl),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.handleBar,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: padding,
                    child: child,
                  ),
                ),
                if (inset > 0)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        child: Text(
                          Tr.of(context).done,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
