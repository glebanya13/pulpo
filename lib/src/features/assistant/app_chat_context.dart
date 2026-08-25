import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';

enum AppContextScope {
  /// Balances + accounts only (fast for “what’s my balance?”).
  balances,

  /// Compact: balances + last 8 txs + budgets/goals/debts counts.
  compact,

  /// Full snapshot for open-ended questions.
  full,
}

/// Compact snapshot of local app data for the assistant (facts only).
String buildAppChatContext(
  WidgetRef ref, {
  AppContextScope scope = AppContextScope.full,
}) {
  final settings = ref.read(settingsControllerProvider);
  final base = settings.baseCurrency;
  final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
  final balances = ref.read(accountBalancesProvider);
  final total = ref.read(totalBalanceProvider);
  final df = DateFormat('yyyy-MM-dd');

  final buf = StringBuffer()
    ..writeln('User: ${settings.userName}')
    ..writeln('Base currency: $base')
    ..writeln(
      'Total balance (included accounts): ${total.toStringAsFixed(2)} $base',
    )
    ..writeln('Accounts (${accounts.where((a) => !a.isArchived).length}):');

  for (final a in accounts.where((a) => !a.isArchived)) {
    final bal = balances[a.id] ?? a.initialBalance;
    buf.writeln(
      '- ${a.name}: ${bal.toStringAsFixed(2)} ${a.currency}'
      '${a.includeInTotal ? '' : ' (excluded from total)'}',
    );
  }

  if (scope == AppContextScope.balances) {
    return buf.toString();
  }

  final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
  final catById = {for (final c in categories) c.id: c.name};
  final txs = [...(ref.read(allTransactionsProvider).valueOrNull ?? const [])]
    ..sort((a, b) => b.date.compareTo(a.date));
  final budgets = ref.read(budgetsProvider).valueOrNull ?? const [];
  final goals = ref.read(goalsProvider).valueOrNull ?? const [];
  final debts = ref.read(debtsProvider).valueOrNull ?? const [];

  final txLimit = scope == AppContextScope.compact ? 8 : 20;
  buf.writeln('Recent transactions (up to $txLimit):');
  for (final t in txs.take(txLimit)) {
    final type = TxType.values[t.type].name;
    final cat = t.categoryId == null ? '-' : (catById[t.categoryId] ?? '?');
    final note = (t.note ?? t.counterparty ?? '').trim();
    buf.writeln(
      '- ${df.format(t.date)} | $type | ${t.amount.toStringAsFixed(2)} ${t.currency}'
      ' | cat=$cat${note.isEmpty ? '' : ' | $note'}',
    );
  }
  if (txs.isEmpty) buf.writeln('- (none)');

  if (scope == AppContextScope.compact) {
    buf
      ..writeln('Budgets: ${budgets.length}')
      ..writeln('Goals: ${goals.length}')
      ..writeln('Debts: ${debts.length}')
      ..writeln('Categories: ${categories.length}');
    return buf.toString();
  }

  buf.writeln('Budgets (${budgets.length}):');
  for (final b in budgets) {
    final period = BudgetPeriod.values[b.period].name;
    buf.writeln(
      '- ${b.name}: limit ${b.amount.toStringAsFixed(2)} ${b.currency} ($period)',
    );
  }
  if (budgets.isEmpty) buf.writeln('- (none)');

  buf.writeln('Goals (${goals.length}):');
  for (final g in goals) {
    buf.writeln(
      '- ${g.name}: ${g.currentAmount.toStringAsFixed(2)} / '
      '${g.targetAmount.toStringAsFixed(2)} ${g.currency}'
      '${g.isCompleted ? ' (done)' : ''}',
    );
  }
  if (goals.isEmpty) buf.writeln('- (none)');

  buf.writeln('Debts (${debts.length}):');
  for (final d in debts) {
    final dir = DebtDirection.values[d.direction].name;
    final left = d.amount - d.paidAmount;
    buf.writeln(
      '- ${d.counterparty}: $dir | remaining ${left.toStringAsFixed(2)} ${d.currency}',
    );
  }
  if (debts.isEmpty) buf.writeln('- (none)');

  buf.writeln('Categories: ${categories.length}');
  return buf.toString();
}
