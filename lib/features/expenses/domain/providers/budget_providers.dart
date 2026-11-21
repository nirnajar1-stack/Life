import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../income/domain/providers/income_providers.dart'
    show incomesRawProvider;
import '../../data/models/monthly_budget_model.dart';
import '../../data/repositories/monthly_budget_repository.dart';
import '../models/variable_pace_forecast.dart';
import 'expense_providers.dart';

final monthlyBudgetRepositoryProvider =
    Provider<MonthlyBudgetRepository>((ref) {
  return MonthlyBudgetRepository(ref.watch(supabaseClientProvider));
});

/// Selected budget month (defaults to current calendar month).
final budgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthlyBudgetsProvider =
    FutureProvider<List<MonthlyBudgetModel>>((ref) async {
  final month = ref.watch(budgetMonthProvider);
  return ref.watch(monthlyBudgetRepositoryProvider).getBudgetsForMonth(
        year: month.year,
        month: month.month,
      );
});

Map<String, double> _budgetMap(List<MonthlyBudgetModel> rows) => {
      for (final row in rows) row.category: row.budgetAmount,
    };

/// Variable pace forecast for the selected budget/analysis month.
final variablePaceForecastProvider =
    Provider<AsyncValue<VariablePaceForecast>>((ref) {
  final month = ref.watch(budgetMonthProvider);
  final budgetsAsync = ref.watch(monthlyBudgetsProvider);
  final expensesAsync = ref.watch(expensesRawProvider);

  return expensesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (expenses) {
      return budgetsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (budgets) {
          // Use end-of-selected-month if viewing a past/future month,
          // otherwise "today" within the current month.
          final now = DateTime.now();
          final anchor = (month.year == now.year && month.month == now.month)
              ? now
              : DateTime(month.year, month.month,
                  daysInMonth(month.year, month.month));
          return AsyncValue.data(
            buildVariablePaceForecast(
              expenses,
              now: anchor,
              budgetsByCategory: _budgetMap(budgets),
            ),
          );
        },
      );
    },
  );
});

final dailyVariableTrendProvider =
    Provider<AsyncValue<List<({DateTime date, double total})>>>((ref) {
  final month = ref.watch(budgetMonthProvider);
  return ref.watch(expensesRawProvider).whenData((expenses) {
    final now = DateTime.now();
    final anchor = (month.year == now.year && month.month == now.month)
        ? now
        : DateTime(month.year, month.month, daysInMonth(month.year, month.month));
    return buildDailyVariableTrend(expenses, now: anchor);
  });
});

final monthlyBalanceProvider = Provider<AsyncValue<MonthlyBalance>>((ref) {
  final month = ref.watch(budgetMonthProvider);
  final expensesAsync = ref.watch(expensesRawProvider);
  final incomesRaw = ref.watch(incomesRawProvider);

  return expensesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (expenses) {
      return incomesRaw.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (incomes) {
          final start = DateTime(month.year, month.month);
          final end = DateTime(month.year, month.month + 1);
          final incomeTotal = incomes
              .where((i) =>
                  !i.createdAt.isBefore(start) && i.createdAt.isBefore(end))
              .fold<double>(0, (s, i) => s + i.amount);
          final now = DateTime.now();
          final anchor = (month.year == now.year && month.month == now.month)
              ? now
              : DateTime(month.year, month.month,
                  daysInMonth(month.year, month.month));
          return AsyncValue.data(
            MonthlyBalance.fromExpenses(
              expenses: expenses,
              totalIncome: incomeTotal,
              now: anchor,
            ),
          );
        },
      );
    },
  );
});

Future<void> refreshBudgets(WidgetRef ref) async {
  ref.invalidate(monthlyBudgetsProvider);
}
