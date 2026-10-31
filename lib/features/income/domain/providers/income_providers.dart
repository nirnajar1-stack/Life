import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/gift_voucher_model.dart';
import '../../data/models/income_model.dart';
import '../../data/models/recurring_income_model.dart';
import '../../data/repositories/gift_voucher_repository.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../models/income_ledger.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository(ref.watch(supabaseClientProvider));
});

final recurringIncomeRepositoryProvider =
    Provider<RecurringIncomeRepository>((ref) {
  return RecurringIncomeRepository(ref.watch(supabaseClientProvider));
});

final giftVoucherRepositoryProvider = Provider<GiftVoucherRepository>((ref) {
  return GiftVoucherRepository(ref.watch(supabaseClientProvider));
});

final incomesRawProvider = FutureProvider<List<IncomeModel>>((ref) async {
  return ref.watch(incomeRepositoryProvider).fetchAll();
});

final recurringIncomesProvider =
    FutureProvider<List<RecurringIncomeModel>>((ref) async {
  return ref.watch(recurringIncomeRepositoryProvider).fetchAll();
});

final giftVouchersProvider =
    FutureProvider<List<GiftVoucherModel>>((ref) async {
  return ref.watch(giftVoucherRepositoryProvider).fetchAll();
});

final activeGiftVoucherBalanceProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(giftVouchersProvider).whenData(
        (vouchers) => vouchers
            .where((v) => !v.isArchived)
            .fold<double>(0, (sum, v) => sum + v.remainingAmount),
      );
});

final incomeLedgerProvider =
    Provider<AsyncValue<List<IncomeMonthSection>>>((ref) {
  return ref.watch(incomesRawProvider).whenData(buildIncomeLedger);
});

final monthIncomeTotalProvider = Provider<AsyncValue<double>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month);
  return ref.watch(incomesRawProvider).whenData(
        (incomes) => filterIncomesByMonth(incomes, start)
            .fold<double>(0, (sum, item) => sum + item.amount),
      );
});

Future<void> refreshIncomes(WidgetRef ref) async {
  ref.invalidate(incomesRawProvider);
  ref.invalidate(recurringIncomesProvider);
  ref.invalidate(giftVouchersProvider);
}
