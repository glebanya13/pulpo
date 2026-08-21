import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Keeps a page's scroll at the top whenever it is not the visible route
/// (another tab or a pushed screen). Uses [ScrollController.jumpTo] so the
/// user never sees a scroll animation on the way back.
class ResetScrollWhenObscured extends StatefulWidget {
  const ResetScrollWhenObscured({
    super.key,
    required this.tabPath,
    required this.builder,
  });

  final String tabPath;
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<ResetScrollWhenObscured> createState() =>
      _ResetScrollWhenObscuredState();
}

class _ResetScrollWhenObscuredState extends State<ResetScrollWhenObscured> {
  final _scroll = ScrollController();
  GoRouterDelegate? _delegate;
  Timer? _delay;

  static const _tabPaths = {
    '/',
    '/transactions',
    '/reports',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.of(context).routerDelegate;
    if (!identical(_delegate, delegate)) {
      _delegate?.removeListener(_resetIfObscured);
      _delegate = delegate;
      _delegate!.addListener(_resetIfObscured);
    }
    _resetIfObscured();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _delegate?.removeListener(_resetIfObscured);
    _scroll.dispose();
    super.dispose();
  }

  void _jump() {
    if (!_scroll.hasClients) return;
    if (_scroll.offset <= 0) return;
    _scroll.jumpTo(0);
  }

  void _resetIfObscured() {
    _delay?.cancel();
    _delay = null;
    if (!mounted) return;
    final path = GoRouter.of(context).state.uri.path;
    if (path == widget.tabPath) return;

    void run() {
      if (_scroll.hasClients) {
        _jump();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _jump();
        });
      }
    }

    // Other tabs are Offstage — jump immediately. Pushed pages fade over
    // this one, so wait until the cover is fully on screen.
    if (_tabPaths.contains(path)) {
      run();
    } else {
      _delay = Timer(const Duration(milliseconds: 360), () {
        if (mounted) run();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _scroll);
}
