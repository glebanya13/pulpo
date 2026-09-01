import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/pro/pro_guard.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/management_menu.dart';
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

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _openAssistant(BuildContext context, WidgetRef ref) async {
    if (!await requireAi(context, ref, allowFreeEnergy: true)) return;
    if (context.mounted) context.push('/assistant');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: _useFloatingNav,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) return navigationShell;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: navigationShell,
            ),
          );
        },
      ),
      bottomNavigationBar: BudgetBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          // Customer wants no state "remembering" between pages:
          // always re-open the target branch at its initial location.
          initialLocation: true,
        ),
        onAddTap: () => showQuickActionsSheet(context),
        onManagementTap: () => showManagementMenu(context, ref),
        onChatTap: () => _openAssistant(context, ref),
      ),
    );
  }
}
