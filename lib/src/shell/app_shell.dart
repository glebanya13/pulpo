import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
          initialLocation: i == navigationShell.currentIndex,
        ),
        onFabTap: () => showQuickActionsSheet(context),
      ),
    );
  }
}
