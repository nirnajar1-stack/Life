import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../models/expense_dashboard.dart';
import '../models/expense_ledger.dart';
import '../models/expense_period.dart';
import '../models/expense_summary.dart';

/// Only layer allowed to talk to Supabase directly.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(supabaseClientProvider));
});

/// Aggregated overview for the Expenses dashboard.
final expensesSummaryProvider = FutureProvider<ExpenseSummary>((ref) async {
  return ref.watch(expenseRepositoryProvider).getSummary();
});

/// Latest expenses for quick lists / forms.
final recentExpensesProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getRecentExpenses(limit: 30);
});

/// Raw ledger rows shared by the monthly list and the analytics dashboard.
final expensesRawProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  return ref.watch(expenseRepositoryProvider).getExpensesForLedger();
});

/// Selected analysis window for dashboard + ledger.
final expensePeriodProvider =
    StateProvider<ExpensePeriod>((ref) => ExpensePeriod.thisMonth);

/// Client-side search over the ledger (item name / category).
final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

/// Expenses filtered by the selected [expensePeriodProvider].
///
/// Excludes future months so analytics / period totals stay accurate.
final filteredExpensesProvider = Provider<AsyncValue<List<ExpenseModel>>>((ref) {
  final period = ref.watch(expensePeriodProvider);
  return ref.watch(expensesRawProvider).whenData(
        (all) => filterExpensesByPeriod(all, period),
      );
});

/// Ledger rows: selected period + future months (collapsed in the UI).
final expenseLedgerProvider =
    Provider<AsyncValue<List<ExpenseMonthSection>>>((ref) {
  final period = ref.watch(expensePeriodProvider);
  return ref.watch(expensesRawProvider).whenData((all) {
    final inPeriod = filterExpensesByPeriod(all, period);
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    final future = all.where((e) => !e.createdAt.isBefore(nextMonth)).toList();
    final byId = <int, ExpenseModel>{
      for (final e in inPeriod) e.id: e,
      for (final e in future) e.id: e,
    };
    return buildExpenseLedger(byId.values.toList());
  });
});

/// Personal spend total for the current calendar month (home + cashflow banner).
final monthExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month);
  final end = DateTime(now.year, now.month + 1);
  return ref.watch(expensesRawProvider).whenData(
        (expenses) => expenses
            .where((e) =>
                !e.createdAt.isBefore(start) && e.createdAt.isBefore(end))
            .fold<double>(0, (sum, e) => sum + e.actualAmount),
      );
});

/// Analytics dashboard slices for the selected period.
///
/// Period filter drives category / period totals. Calendar MoM + monthly trend
/// always use the full ledger (excluding future months) so "חודש קודם" and the
/// trend stay correct even when the chip is "החודש".
final expenseDashboardProvider = Provider<AsyncValue<ExpenseDashboard>>((ref) {
  final period = ref.watch(expensePeriodProvider);
  return ref.watch(expensesRawProvider).whenData((all) {
    final filtered = filterExpensesByPeriod(all, period);
    return buildExpenseDashboard(
      filtered,
      period: period,
      calendarExpenses: all,
    );
  });
});
