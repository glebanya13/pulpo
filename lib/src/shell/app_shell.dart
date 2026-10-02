import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/pro/pro_guard.dart';
import '../data/repositories/assistant_chat_repository.dart';
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
  @override
  void initState() {
    super.initState();
    // Prefetch local chat so /assistant opens without a cold stream hitch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assistantMessagesProvider);
      // ignore: discarded_futures
      ref.read(assistantChatSyncProvider.future);
    });
  }

  Future<void> _openAssistant(BuildContext context) async {
    ref.read(assistantMessagesProvider);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: _useFloatingNav,
      body: LayoutBuilder(
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
      bottomNavigationBar: RepaintBoundary(
        child: BudgetBottomNav(
          // 0 home · 1 reports · 2 management
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _goTab,
          onAddTap: () => showQuickActionsSheet(context, ref),
          onManagementTap: () => _goTab(2),
          onChatTap: () => _openAssistant(context),
        ),
      ),
    );
  }
}
