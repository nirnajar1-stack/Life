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
          appBar: AppBar(
            title: const Text('כסף'),
            automaticallyImplyLeading: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: loading
            ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'הכנסות',
                      value: _currency.format(income),
                      color: AppColors.income,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.line),
                  Expanded(
                    child: _StatCell(
                      label: 'הוצאות',
                      value: _currency.format(expense),
                      color: AppColors.expenses,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.line),
                  Expanded(
                    child: _StatCell(
                      label: 'נטו',
                      value: _currency.format(net),
                      color: net >= 0 ? AppColors.income : AppColors.danger,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
