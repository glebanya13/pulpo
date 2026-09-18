import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/pro/pro_guard.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/quick_actions_sheet.dart';

bool get _useFloatingNav {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return false;
    default:
      return true;
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _scrolling = false;
  Timer? _scrollIdle;

  Future<void> _openAssistant(BuildContext context) async {
    if (!await requireAi(context, ref, allowFreeEnergy: true)) return;
    if (context.mounted) context.push('/assistant');
  }

  void _goTab(int index) {
    widget.navigationShell.goBranch(
      index,
      // Customer wants no state "remembering" between pages:
      // always re-open the target branch at its initial location.
      initialLocation: true,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      if (!_scrolling) setState(() => _scrolling = true);
      _scrollIdle?.cancel();
      _scrollIdle = Timer(const Duration(milliseconds: 140), () {
        if (mounted) setState(() => _scrolling = false);
      });
    }
    return false;
  }

  @override
  void dispose() {
    _scrollIdle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: _useFloatingNav,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 700) {
              return widget.navigationShell;
            }
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: widget.navigationShell,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BudgetBottomNav(
        // 0 home · 1 reports · 2 management
        currentIndex: widget.navigationShell.currentIndex,
        lightGlass: _scrolling,
        onTap: _goTab,
        onAddTap: () => showQuickActionsSheet(context, ref),
        onManagementTap: () => _goTab(2),
        onChatTap: () => _openAssistant(context),
      ),
    );
  }
}
