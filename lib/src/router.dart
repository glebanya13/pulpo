import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/repositories/settings_service.dart';
import 'features/accounts/account_detail_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/budgets/budgets_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/debts/debts_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_setup_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/backups_screen.dart';
import 'features/settings/currency_picker_screen.dart';
import 'features/settings/language_picker_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/transactions/transfer_screen.dart';
import 'shell/app_shell.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsControllerProvider);

  return GoRouter(
    initialLocation: settings.onboardingDone ? '/' : '/onboarding',
    redirect: (context, state) {
      final path = state.uri.path;
      if (!settings.onboardingDone && !path.startsWith('/onboarding')) {
        return '/onboarding';
      }
      if (settings.onboardingDone && path.startsWith('/onboarding')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadePage(state, const OnboardingScreen()),
        routes: [
          GoRoute(
            path: 'setup',
            pageBuilder: (context, state) =>
                _fadePage(state, const OnboardingSetupScreen()),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        pageBuilder: (context, state) => _fadePage(
          state,
          AddTransactionScreen(initialType: state.uri.queryParameters['type']),
        ),
      ),
      GoRoute(
        path: '/transfer',
        pageBuilder: (context, state) =>
            _fadePage(state, const TransferScreen()),
      ),
      GoRoute(
        path: '/tx/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          TransactionDetailScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) => _fadePage(
              state,
              AddTransactionScreen(
                editId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts',
        pageBuilder: (context, state) =>
            _fadePage(state, const AccountsScreen()),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (context, state) => _fadePage(
              state,
              AccountDetailScreen(
                accountId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        pageBuilder: (context, state) =>
            _fadePage(state, const CategoriesScreen()),
      ),
      GoRoute(
        path: '/budgets',
        pageBuilder: (context, state) =>
            _fadePage(state, const BudgetsScreen()),
      ),
      GoRoute(
        path: '/debts',
        pageBuilder: (context, state) => _fadePage(state, const DebtsScreen()),
      ),
      GoRoute(
        path: '/subscriptions',
        pageBuilder: (context, state) =>
            _fadePage(state, const SubscriptionsScreen()),
      ),
      GoRoute(
        path: '/recurring',
        pageBuilder: (context, state) =>
            _fadePage(state, const RecurringScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadePage(state, const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'currency',
            pageBuilder: (context, state) =>
                _fadePage(state, const CurrencyPickerScreen()),
          ),
          GoRoute(
            path: 'language',
            pageBuilder: (context, state) =>
                _fadePage(state, const LanguagePickerScreen()),
          ),
          GoRoute(
            path: 'backups',
            pageBuilder: (context, state) =>
                _fadePage(state, const BackupsScreen()),
          ),
          GoRoute(
            path: 'about',
            pageBuilder: (context, state) =>
                _fadePage(state, const AboutScreen()),
          ),
        ],
      ),
    ],
  );
});
