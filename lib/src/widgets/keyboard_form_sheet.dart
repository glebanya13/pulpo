import 'package:flutter/material.dart';

import '../core/l10n/tr.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

const _kDoneBarH = 44.0;

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
    final hasKeyboard = inset > 0;

    // Card height cap: leave room above keyboard (+ done bar if visible)
    final aboveKeyboard = inset + (hasKeyboard ? _kDoneBarH : 0);
    final maxH = (media.size.height - aboveKeyboard - topSafe - 12)
        .clamp(200.0, media.size.height * 0.92);

    final card = Material(
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
            // ── Handle bar + close button ──
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

            // ── Form content ──
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
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
    );

    if (!hasKeyboard) {
      return Align(alignment: Alignment.bottomCenter, child: card);
    }

    // When keyboard is visible: card sits above done bar, done bar sits
    // directly on top of the keyboard — mimics iOS input accessory view.
    return Stack(
      children: [
        // Sheet card pushed above keyboard + done bar
        Padding(
          padding: EdgeInsets.only(bottom: inset + _kDoneBarH),
          child: Align(alignment: Alignment.bottomCenter, child: card),
        ),

        // Done bar — glued to the top edge of the keyboard
        Positioned(
          bottom: inset,
          left: 0,
          right: 0,
          height: _kDoneBarH,
          child: _DoneBar(),
        ),
      ],
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

class _DoneBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: context.divider,
              width: 0.5,
            ),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              Tr.of(context).done,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
