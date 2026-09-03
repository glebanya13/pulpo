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

  /// Clearance for scroll content above the floating tab bar.
  ///
  /// With [Scaffold.extendBody], Flutter already puts the bottom-nav height
  /// into [MediaQuery.padding.bottom] — do not add the pill height again.
  static double tabScrollBottomInset(BuildContext context) {
    const gap = 8.0;
    return MediaQuery.paddingOf(context).bottom + gap;
  }

  /// Space so the last item sits just above the floating tab bar.
  static double tabBodyBottom(BuildContext context) => tabScrollBottomInset(context);

  /// Bottom inset for full-screen pushes (nav is covered / hidden).
  static double pushedScrollBottomInset(BuildContext context) {
    return md + MediaQuery.viewPaddingOf(context).bottom;
  }

  static EdgeInsets tabPagePadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      lg,
      MediaQuery.viewPaddingOf(context).top + xs,
      lg,
      tabBodyBottom(context),
    );
  }

  /// Pushed routes outside the shell — same side/top rhythm as tabs,
  /// but only clear the home indicator (no floating pill).
  static EdgeInsets pushedPagePadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      lg,
      MediaQuery.viewPaddingOf(context).top + xs,
      lg,
      pushedScrollBottomInset(context),
    );
  }

  /// Floating snackbars on tab screens sit above the pill.
  static EdgeInsets snackBarMargin(BuildContext context) {
    return EdgeInsets.fromLTRB(16, 0, 16, tabScrollBottomInset(context));
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
