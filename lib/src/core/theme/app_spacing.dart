import 'package:flutter/widgets.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // Radius
  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 20;
  static const double rXl = 24;
  static const double rXxl = 28;
  static const double rPill = 100;

  /// Space so the last item sits just above the floating tab bar.
  static double tabBodyBottom(BuildContext context) {
    final home = MediaQuery.paddingOf(context).bottom;
    return 82 + (home * 0.2).clamp(0, 8);
  }

  static EdgeInsets tabPagePadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      lg,
      MediaQuery.viewPaddingOf(context).top + xs,
      lg,
      tabBodyBottom(context),
    );
  }

  /// Bottom sheets on tab screens must clear the floating nav pill.
  static EdgeInsets sheetOnTabScreen(BuildContext context) {
    return EdgeInsets.fromLTRB(8, 10, 8, md + tabBodyBottom(context));
  }
}
