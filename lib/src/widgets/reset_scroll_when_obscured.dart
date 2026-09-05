import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Resets scroll (and optional local state) whenever a tab page becomes visible
/// again after the user left it — another bottom tab or a pushed route on top.
///
/// Set [preserveScrollOnPush] to `true` to keep scroll position when the user
/// navigates to a pushed sub-route and returns — scroll only resets on a tab
/// switch in that case.
class ResetScrollWhenObscured extends StatefulWidget {
  const ResetScrollWhenObscured({
    super.key,
    required this.tabPath,
    required this.builder,
    this.onBecameVisible,
    this.preserveScrollOnPush = false,
  });

  final String tabPath;
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  /// Called when the user returns to [tabPath] — reset tabs, filters, etc.
  final VoidCallback? onBecameVisible;

  /// When true, scroll is only reset on tab switches, not on push/pop.
  final bool preserveScrollOnPush;

  @override
  State<ResetScrollWhenObscured> createState() =>
      _ResetScrollWhenObscuredState();
}

class _ResetScrollWhenObscuredState extends State<ResetScrollWhenObscured> {
  final _scroll = ScrollController(keepScrollOffset: false);
  GoRouterDelegate? _delegate;
  Timer? _delay;
  var _visible = false;
  var _leftViaTabSwitch = false;

  static const _tabPaths = {
    '/',
    '/reports',
    '/management',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.of(context).routerDelegate;
    if (!identical(_delegate, delegate)) {
      _delegate?.removeListener(_onRouteChange);
      _delegate = delegate;
      _delegate!.addListener(_onRouteChange);
    }
    _onRouteChange();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _delegate?.removeListener(_onRouteChange);
    _scroll.dispose();
    super.dispose();
  }

  void _jump() {
    if (!_scroll.hasClients) return;
    if (_scroll.offset <= 0) return;
    _scroll.jumpTo(0);
  }

  void _scheduleReset({required bool notifyVisible}) {
    void run() {
      _jump();
      if (notifyVisible) widget.onBecameVisible?.call();
    }

    if (_scroll.hasClients) {
      run();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) run();
      });
    }
  }

  void _onRouteChange() {
    _delay?.cancel();
    _delay = null;
    if (!mounted) return;

    final path = GoRouter.of(context).state.uri.path;
    final isVisible = path == widget.tabPath;

    if (isVisible) {
      if (!_visible) {
        _visible = true;
        final shouldReset =
            !widget.preserveScrollOnPush || _leftViaTabSwitch;
        _leftViaTabSwitch = false;
        if (shouldReset) {
          _scheduleReset(notifyVisible: true);
        } else {
          widget.onBecameVisible?.call();
        }
      }
      return;
    }

    _visible = false;

    // Other tabs are Offstage — jump immediately. Pushed pages fade over
    // this one, so wait until the cover is fully on screen.
    if (_tabPaths.contains(path)) {
      _leftViaTabSwitch = true;
      _jump();
    } else {
      _leftViaTabSwitch = false;
      if (!widget.preserveScrollOnPush) {
        _delay = Timer(const Duration(milliseconds: 360), () {
          if (mounted) _jump();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _scroll);
}
