import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// SoftCard-style floating toast — used by [AppTheme] and [showAppSnackBar].
abstract final class AppSnackBarStyle {
  static const double radius = 16;

  static SnackBarThemeData theme({required bool dark}) {
    final bg = dark ? const Color(0xFF333333) : AppColors.surface;
    final fg = dark ? Colors.white : AppColors.ink;
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: bg,
      contentTextStyle: TextStyle(
        color: fg,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      actionTextColor: dark ? AppColors.lime : AppColors.limeAccent,
      disabledActionTextColor: fg.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.6,
        ),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}

/// Shows a themed floating snackbar (above the tab pill when present).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
  bool aboveTabBar = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      margin: aboveTabBar ? AppSpacing.snackBarMargin(context) : null,
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction),
    ),
  );
}
