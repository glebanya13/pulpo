enum ProGate {
  accounts,
  goals,
  budgets,
  debts,
  subscriptions,
  recurring,
  analytics,
  trends,
  flows,
  currencies,
  cloud,
  sync,
  excel,
  pdf,
  reminders,
  importCsv,
  generic,
  sharedBudget,
  ai,
}

class ProLimits {
  const ProLimits._();

  static const accounts = 3;
  static const goals = 2;
  static const budgets = 3;
  static const debts = 2;
  static const subscriptions = 3;
  static const recurring = 3;

  static int? freeLimit(ProGate gate) => switch (gate) {
        ProGate.accounts => accounts,
        ProGate.goals => goals,
        ProGate.budgets => budgets,
        ProGate.debts => debts,
        ProGate.subscriptions => subscriptions,
        ProGate.recurring => recurring,
        _ => null,
      };

  static bool isFreeAnalyticsPeriod(String kindName) =>
      kindName == 'thisMonth' || kindName == 'lastMonth';
}

class ProProducts {
  const ProProducts._();

  /// Must match App Store Connect / Play Console product IDs exactly.
  static const monthlyId = 'monedero_pro_mensual';
  static const semiAnnualId = 'monedero_pro_6meses';
  static const yearlyId = 'monedero_pro_anual';
  static const ids = {monthlyId, semiAnnualId, yearlyId};

  /// App Store Connect subscription group.
  static const subscriptionGroupId = '22339635';

  /// Paywall display amounts (must match ASC / Play / StoreKit config).
  static const catalogAmounts = <String, double>{
    monthlyId: 3.99,
    semiAnnualId: 14.99,
    yearlyId: 24.99,
  };

  /// Store prices for Spain / EU — paywall always shows EUR, not sandbox $.
  static const catalogCurrency = 'EUR';
}

bool isActiveGoal({required bool isCompleted}) => !isCompleted;

bool isActiveBudget({required DateTime? endDate, required DateTime now}) {
  if (endDate == null) return true;
  final today = DateTime(now.year, now.month, now.day);
  return !endDate.isBefore(today);
}

bool isActiveDebt({
  required int status,
  required double amount,
  required double paidAmount,
}) {
  if (status != 0) return false;
  return paidAmount + 0.005 < amount;
}

bool isActiveSubscription({required bool isPaused}) => !isPaused;

bool isActiveRecurring({required bool isPaused}) => !isPaused;
