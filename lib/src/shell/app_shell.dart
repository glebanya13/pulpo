import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/bottom_nav.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexFor(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  static const _routes = ['/', '/transactions', '/reports', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFor(location);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: BudgetBottomNav(
        currentIndex: index,
        onTap: (i) => context.go(_routes[i]),
        onFabTap: () => context.push('/add'),
      ),
    );
  }
}
