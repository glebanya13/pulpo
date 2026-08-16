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
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'setup',
            builder: (context, state) => const OnboardingSetupScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => AddTransactionScreen(
          initialType: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/transfer',
        builder: (context, state) => const TransferScreen(),
      ),
      GoRoute(
        path: '/tx/:id',
        builder: (context, state) => TransactionDetailScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => AddTransactionScreen(
              editId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => AccountDetailScreen(
              accountId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/debts',
        builder: (context, state) => const DebtsScreen(),
      ),
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: '/recurring',
        builder: (context, state) => const RecurringScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'currency',
            builder: (context, state) => const CurrencyPickerScreen(),
          ),
          GoRoute(
            path: 'language',
            builder: (context, state) => const LanguagePickerScreen(),
          ),
          GoRoute(
            path: 'backups',
            builder: (context, state) => const BackupsScreen(),
          ),
        ],
      ),
    ],
  );
});
