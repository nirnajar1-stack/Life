import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../features/expenses/domain/providers/expense_providers.dart';
import '../../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../../features/income/domain/providers/income_providers.dart';
import '../../../features/income/presentation/screens/income_screen.dart';
import '../layout/app_layout.dart';
import '../theme/app_theme.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);

/// Unified money hub: expenses + income with monthly cashflow summary.
class MoneyHubScreen extends ConsumerWidget {
  const MoneyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(monthIncomeTotalProvider);
    final expenseAsync = ref.watch(monthExpenseTotalProvider);

    final income = incomeAsync.valueOrNull ?? 0;
    final expense = expenseAsync.valueOrNull ?? 0;
    final net = income - expense;
    final loading = incomeAsync.isLoading || expenseAsync.isLoading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: const Text('כסף'),
            automaticallyImplyLeading: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(168),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm + AppSpacing.xs,
                    ),
                    child: _CashflowBanner(
                      income: income,
                      expense: expense,
                      net: net,
                      loading: loading,
                    ),
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'הוצאות'),
                      Tab(text: 'הכנסות'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: AppLayout.constrain(
            context: context,
            child: const TabBarView(
              children: [
                ExpensesScreen(),
                IncomeScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashflowBanner extends StatelessWidget {
  const _CashflowBanner({
    required this.income,
    required this.expense,
    required this.net,
    required this.loading,
  });

  final double income;
  final double expense;
  final double net;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return HeroPanel(
      eyebrow: 'תזרים החודש',
      title: loading ? 'טוען…' : _currency.format(net),
      subtitle: loading
          ? null
          : 'הכנסות ${_currency.format(income)} · הוצאות ${_currency.format(expense)}',
      trailing: StatusPill(
        label: net >= 0 ? 'חיובי' : 'גירעון',
        tone: net >= 0 ? StatusPillTone.success : StatusPillTone.danger,
      ),
      child: loading
          ? const LinearProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.white24,
            )
          : Row(
              children: [
                Expanded(
                  child: _CashStat(
                    label: 'הכנסות',
                    value: _currency.format(income),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CashStat(
                    label: 'הוצאות',
                    value: _currency.format(expense),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CashStat(
                    label: 'נטו',
                    value: _currency.format(net),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CashStat extends StatelessWidget {
  const _CashStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
