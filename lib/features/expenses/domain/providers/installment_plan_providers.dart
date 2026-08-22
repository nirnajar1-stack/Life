import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/installment_plan_model.dart';
import '../../data/repositories/installment_plan_repository.dart';
import 'expense_providers.dart';

final installmentPlanRepositoryProvider =
    Provider<InstallmentPlanRepository>((ref) {
  return InstallmentPlanRepository(ref.watch(supabaseClientProvider));
});

final installmentPlansProvider =
    FutureProvider<List<InstallmentPlanModel>>((ref) async {
  return ref.watch(installmentPlanRepositoryProvider).fetchAll();
});

Future<void> refreshInstallmentPlansAndExpenses(WidgetRef ref) async {
  ref.invalidate(installmentPlansProvider);
  ref.invalidate(expensesRawProvider);
  ref.invalidate(expensesSummaryProvider);
  ref.invalidate(recentExpensesProvider);
}
