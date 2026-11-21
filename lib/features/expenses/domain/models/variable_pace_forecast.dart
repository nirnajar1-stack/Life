import '../../data/models/expense_model.dart';
import 'expense_amounts.dart';
import 'expense_behavior.dart';
import 'expense_category_taxonomy.dart';

/// Config thresholds for budget status (not hardcoded in UI).
class BudgetStatusThresholds {
  const BudgetStatusThresholds({
    this.onTrackMax = 0.95,
    this.watchMax = 1.0,
  });

  /// Forecast <= budget * onTrackMax → on track.
  final double onTrackMax;

  /// Forecast <= budget * watchMax → watch; above → over budget.
  final double watchMax;

  static const BudgetStatusThresholds defaults = BudgetStatusThresholds();
}

enum BudgetStatus {
  onTrack,
  watch,
  overBudget,
  noBudget,
}

extension BudgetStatusX on BudgetStatus {
  String get label {
    switch (this) {
      case BudgetStatus.onTrack:
        return 'במסלול';
      case BudgetStatus.watch:
        return 'לשים לב';
      case BudgetStatus.overBudget:
        return 'חריגה';
      case BudgetStatus.noBudget:
        return 'ללא תקציב';
    }
  }
}

BudgetStatus resolveBudgetStatus({
  required double? budget,
  required double forecast,
  BudgetStatusThresholds thresholds = BudgetStatusThresholds.defaults,
}) {
  if (budget == null || budget <= 0) return BudgetStatus.noBudget;
  if (forecast <= budget * thresholds.onTrackMax) return BudgetStatus.onTrack;
  if (forecast <= budget * thresholds.watchMax) return BudgetStatus.watch;
  return BudgetStatus.overBudget;
}

/// Pace-based end-of-month forecast for variable expenses only.
class CategoryPaceForecast {
  const CategoryPaceForecast({
    required this.category,
    required this.actualMtd,
    required this.dailyPace,
    required this.forecastEom,
    this.budget,
  });

  final String category;
  final double actualMtd;
  final double dailyPace;
  final double forecastEom;
  final double? budget;

  double? get remainingBudget =>
      budget == null ? null : budget! - actualMtd;

  double? get utilizationPercent =>
      (budget == null || budget! <= 0) ? null : (actualMtd / budget!) * 100;

  /// Positive = expected overrun; negative = expected leftover.
  double? get forecastVariance =>
      budget == null ? null : forecastEom - budget!;

  BudgetStatus get status => resolveBudgetStatus(
        budget: budget,
        forecast: forecastEom,
      );
}

class VariablePaceForecast {
  const VariablePaceForecast({
    required this.year,
    required this.month,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.variableSpendMtd,
    required this.dailyPace,
    required this.forecastEom,
    required this.byCategory,
    required this.isEarlyMonth,
  });

  final int year;
  final int month;
  final int daysElapsed;
  final int daysInMonth;
  final double variableSpendMtd;
  final double dailyPace;
  final double forecastEom;
  final List<CategoryPaceForecast> byCategory;
  final bool isEarlyMonth;

  static VariablePaceForecast empty({
    required int year,
    required int month,
    required int daysElapsed,
    required int daysInMonth,
  }) {
    return VariablePaceForecast(
      year: year,
      month: month,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
      variableSpendMtd: 0,
      dailyPace: 0,
      forecastEom: 0,
      byCategory: const [],
      isEarlyMonth: daysElapsed <= 5,
    );
  }
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Days elapsed from month start through [now] (inclusive), min 1.
int daysElapsedInMonth(DateTime now) {
  final day = now.day;
  return day < 1 ? 1 : day;
}

/// Builds variable-only pace forecast for the calendar month of [now].
VariablePaceForecast buildVariablePaceForecast(
  List<ExpenseModel> expenses, {
  DateTime? now,
  Map<String, double> budgetsByCategory = const {},
}) {
  final n = now ?? DateTime.now();
  final year = n.year;
  final month = n.month;
  final elapsed = daysElapsedInMonth(n);
  final inMonth = daysInMonth(year, month);
  final monthStart = DateTime(year, month);
  final monthEndExclusive = DateTime(year, month + 1);

  final byParent = <String, double>{};
  double total = 0;

  for (final e in expenses) {
    // Daily pace: variable_discretionary only.
    // Installments / fixed / recurring_variable / one_time are excluded.
    final behavior = deriveExpenseBehavior(e);
    if (!behavior.countsInDailyPace) continue;

    final tx = transactionDate(e);
    if (tx.isBefore(monthStart) || !tx.isBefore(monthEndExclusive)) continue;

    final amount = effectiveAmount(e);
    total += amount;
    final parent = ExpenseCategoryTaxonomy.resolveParent(e.category);
    byParent[parent] = (byParent[parent] ?? 0) + amount;
  }

  final pace = total / elapsed;
  final forecast = pace * inMonth;

  final categories = byParent.entries.map((entry) {
    final catPace = entry.value / elapsed;
    return CategoryPaceForecast(
      category: entry.key,
      actualMtd: entry.value,
      dailyPace: catPace,
      forecastEom: catPace * inMonth,
      budget: budgetsByCategory[entry.key],
    );
  }).toList()
    ..sort((a, b) => b.actualMtd.compareTo(a.actualMtd));

  // Include budget-only categories with zero spend so UI can show them.
  for (final entry in budgetsByCategory.entries) {
    if (byParent.containsKey(entry.key)) continue;
    categories.add(CategoryPaceForecast(
      category: entry.key,
      actualMtd: 0,
      dailyPace: 0,
      forecastEom: 0,
      budget: entry.value,
    ));
  }
  categories.sort((a, b) => b.actualMtd.compareTo(a.actualMtd));

  return VariablePaceForecast(
    year: year,
    month: month,
    daysElapsed: elapsed,
    daysInMonth: inMonth,
    variableSpendMtd: total,
    dailyPace: pace,
    forecastEom: forecast,
    byCategory: categories,
    isEarlyMonth: elapsed <= 5,
  );
}

/// Variable-only daily spend series for the current month (through today).
///
/// Returns lightweight maps — UI charts on Soft UI use [ExpenseDashboard.dailyTrend].
List<({DateTime date, double total})> buildDailyVariableTrend(
  List<ExpenseModel> expenses, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final monthStart = DateTime(n.year, n.month);
  final today = DateTime(n.year, n.month, n.day);
  final totals = <String, double>{};

  for (final e in expenses) {
    final behavior = deriveExpenseBehavior(e);
    if (!behavior.countsInDailyPace) continue;

    final tx = transactionDate(e);
    if (tx.isBefore(monthStart) || tx.isAfter(today)) continue;

    final key =
        '${tx.year}-${tx.month.toString().padLeft(2, '0')}-${tx.day.toString().padLeft(2, '0')}';
    totals[key] = (totals[key] ?? 0) + effectiveAmount(e);
  }

  final days = <({DateTime date, double total})>[];
  for (var d = monthStart;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))) {
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    days.add((date: d, total: totals[key] ?? 0));
  }
  return days;
}

/// Monthly balance = income − (fixed + variable + installment) actuals.
class MonthlyBalance {
  const MonthlyBalance({
    required this.totalIncome,
    required this.totalExpenses,
    required this.fixedExpenses,
    required this.variableExpenses,
    required this.installmentExpenses,
  });

  final double totalIncome;
  final double totalExpenses;
  final double fixedExpenses;
  final double variableExpenses;
  final double installmentExpenses;

  double get balance => totalIncome - totalExpenses;

  static MonthlyBalance fromExpenses({
    required List<ExpenseModel> expenses,
    required double totalIncome,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final monthStart = DateTime(n.year, n.month);
    final monthEndExclusive = DateTime(n.year, n.month + 1);

    double fixed = 0;
    double variable = 0;
    double installment = 0;

    for (final e in expenses) {
      final tx = transactionDate(e);
      if (tx.isBefore(monthStart) || !tx.isBefore(monthEndExclusive)) {
        continue;
      }
      final amount = effectiveAmount(e);
      // Monthly cashflow includes installments + all behavior types.
      // Keep installment breakout for UI; otherwise bucket by behavior.
      final mid = e.installmentGroupId?.trim();
      if (mid != null && mid.isNotEmpty) {
        installment += amount;
        continue;
      }
      switch (deriveExpenseBehavior(e)) {
        case ExpenseBehaviorType.fixedCommitment:
          fixed += amount;
        case ExpenseBehaviorType.recurringVariable:
        case ExpenseBehaviorType.variableDiscretionary:
        case ExpenseBehaviorType.oneTime:
          variable += amount;
      }
    }

    return MonthlyBalance(
      totalIncome: totalIncome,
      totalExpenses: fixed + variable + installment,
      fixedExpenses: fixed,
      variableExpenses: variable,
      installmentExpenses: installment,
    );
  }
}
