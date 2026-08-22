import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/recurring_expense_model.dart';
import '../../data/repositories/recurring_expense_repository.dart';
import 'expense_providers.dart';

final recurringExpenseRepositoryProvider =
    Provider<RecurringExpenseRepository>((ref) {
  return RecurringExpenseRepository(ref.watch(supabaseClientProvider));
});

final recurringExpensesProvider =
    FutureProvider<List<RecurringExpenseModel>>((ref) async {
  return ref.watch(recurringExpenseRepositoryProvider).fetchAll();
});

/// Materializes due recurring charges, then refreshes expense lists.
Future<int> refreshRecurringAndExpenses(WidgetRef ref) async {
  final generated =
      await ref.read(recurringExpenseRepositoryProvider).generateDueCharges();
  ref.invalidate(recurringExpensesProvider);
  ref.invalidate(expensesRawProvider);
  ref.invalidate(expensesSummaryProvider);
  ref.invalidate(recentExpensesProvider);
  return generated;
}
