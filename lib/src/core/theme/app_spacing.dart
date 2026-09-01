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
    const navBarExtent = 62.0;
    return navBarExtent + MediaQuery.paddingOf(context).bottom + sm;
  }

  static EdgeInsets tabPagePadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      lg,
      MediaQuery.viewPaddingOf(context).top + xs,
      lg,
      tabBodyBottom(context),
    );
  }

  /// Root modal sheets (`useRootNavigator`) cover the floating nav —
  /// only clear the home-indicator / system inset, not the tab pill height.
  static EdgeInsets sheetOnTabScreen(BuildContext context) {
    return EdgeInsets.fromLTRB(
      8,
      10,
      8,
      md + MediaQuery.viewPaddingOf(context).bottom,
    );
  }
}
