import 'package:flutter/material.dart';

/// Modal push with a soft slide-up + fade (paywall, full-screen flows).
class SmoothModalRoute<T> extends PageRouteBuilder<T> {
  SmoothModalRoute({
    required WidgetBuilder builder,
    super.settings,
    this.openDuration = const Duration(milliseconds: 420),
    this.closeDuration = const Duration(milliseconds: 320),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: openDuration,
          reverseTransitionDuration: closeDuration,
          fullscreenDialog: true,
          opaque: true,
          barrierDismissible: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.045),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );

  final Duration openDuration;
  final Duration closeDuration;
}
