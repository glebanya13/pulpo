import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import '../repositories/providers.dart';
import '../repositories/settings_service.dart';

class _DemoCopy {
  const _DemoCopy({
    required this.cash,
    required this.card,
    required this.salary,
    required this.freelance,
    required this.groceries,
    required this.coffee,
    required this.cinema,
    required this.internet,
    required this.pharmacy,
    required this.foodBudget,
    required this.userName,
  });

  final String cash;
  final String card;
  final String salary;
  final String freelance;
  final String groceries;
  final String coffee;
  final String cinema;
  final String internet;
  final String pharmacy;
  final String foodBudget;
  final String userName;
}

_DemoCopy _copyFor(String locale) {
  switch (locale) {
    case 'ru':
      return const _DemoCopy(
        cash: 'Наличные',
        card: 'Карта',
        salary: 'Зарплата',
        freelance: 'Фриланс',
        groceries: 'Продукты',
        coffee: 'Кофе',
        cinema: 'Кино',
        internet: 'Интернет',
        pharmacy: 'Аптека',
        foodBudget: 'Еда',
        userName: 'Алекс',
      );
    case 'en':
      return const _DemoCopy(
        cash: 'Cash',
        card: 'Card',
        salary: 'Salary',
        freelance: 'Freelance',
        groceries: 'Groceries',
        coffee: 'Coffee',
        cinema: 'Cinema',
        internet: 'Internet',
        pharmacy: 'Pharmacy',
        foodBudget: 'Food',
        userName: 'Alex',
      );
    default:
      return const _DemoCopy(
        cash: 'Efectivo',
        card: 'Tarjeta',
        salary: 'Salario',
        freelance: 'Freelance',
        groceries: 'Supermercado',
        coffee: 'Café',
        cinema: 'Cine',
        internet: 'Internet',
        pharmacy: 'Farmacia',
        foodBudget: 'Comida',
        userName: 'Alex',
      );
  }
}

/// Локальная демка для модерации App Store / Google Play: счета и операции
/// без облачного аккаунта. Не трогает данные, если счета уже есть.
Future<void> seedDemoData(
  AppDatabase db, {
  required String currency,
  String locale = 'es',
}) async {
  final existing = await db.select(db.accounts).get();
  if (existing.isNotEmpty) return;

  final copy = _copyFor(locale);
  final cats = await db.select(db.categories).get();
  final bySlug = {for (final c in cats) c.name: c.id};
  int? cat(String slug) => bySlug[slug];

  await db.transaction(() async {
    final cashId = await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: copy.cash,
            type: AccountType.cash.index,
            currency: currency,
            initialBalance: const Value(420),
            icon: const Value('wallet'),
            color: const Value(0xFF3DDC84),
          ),
        );
    final cardId = await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: copy.card,
            type: AccountType.card.index,
            currency: currency,
            initialBalance: const Value(1860),
            icon: const Value('credit-card'),
            color: const Value(0xFF7C6CFF),
          ),
        );

    final now = DateTime.now();
    DateTime d(int day, [int hour = 12]) =>
        DateTime(now.year, now.month, day.clamp(1, 28), hour, 10);

    Future<void> tx({
      required int accountId,
      required double amount,
      required TxType type,
      required DateTime date,
      String? slug,
      String? note,
    }) {
      return db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              categoryId: Value(slug == null ? null : cat(slug)),
              amount: amount,
              currency: currency,
              type: type.index,
              date: date,
              note: Value(note),
            ),
          );
    }

    await tx(
      accountId: cardId,
      amount: 2850,
      type: TxType.income,
      date: d(1, 9),
      slug: 'salary',
      note: copy.salary,
    );
    await tx(
      accountId: cardId,
      amount: 420,
      type: TxType.income,
      date: d(8, 11),
      slug: 'freelance',
      note: copy.freelance,
    );
    await tx(
      accountId: cardId,
      amount: 48.50,
      type: TxType.expense,
      date: d(3, 13),
      slug: 'food',
      note: copy.groceries,
    );
    await tx(
      accountId: cashId,
      amount: 12.90,
      type: TxType.expense,
      date: d(5, 19),
      slug: 'food',
      note: copy.coffee,
    );
    await tx(
      accountId: cardId,
      amount: 36,
      type: TxType.expense,
      date: d(7, 21),
      slug: 'entertainment',
      note: copy.cinema,
    );
    await tx(
      accountId: cardId,
      amount: 22.40,
      type: TxType.expense,
      date: d(10, 8),
      slug: 'transport',
    );
    await tx(
      accountId: cardId,
      amount: 64.99,
      type: TxType.expense,
      date: d(12, 16),
      slug: 'communication',
      note: copy.internet,
    );
    await tx(
      accountId: cashId,
      amount: 18,
      type: TxType.expense,
      date: d(15, 12),
      slug: 'food',
    );
    await tx(
      accountId: cardId,
      amount: 89,
      type: TxType.expense,
      date: d(now.day.clamp(2, 28), 14),
      slug: 'health',
      note: copy.pharmacy,
    );

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final foodId = cat('food');
    await db.into(db.budgets).insert(
          BudgetsCompanion.insert(
            name: copy.foodBudget,
            period: BudgetPeriod.month.index,
            amount: 350,
            currency: currency,
            startDate: monthStart,
            endDate: Value(monthEnd),
            categoryIdsJson: Value(foodId == null ? '[]' : '[$foodId]'),
            color: const Value(0xFF8BD44A),
          ),
        );
  });
}

/// Онбординг без логина: имя, EUR и готовые операции для модерации.
Future<void> startLocalDemo(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsControllerProvider);
  final locale = settings.locale;
  final copy = _copyFor(locale);
  await ref.read(settingsControllerProvider.notifier).completeOnboarding(
        name: copy.userName,
        currency: 'EUR',
        themeMode: settings.themeMode,
        locale: locale,
      );
  await seedDemoData(
    ref.read(databaseProvider),
    currency: 'EUR',
    locale: locale,
  );
  if (context.mounted) context.go('/');
}
