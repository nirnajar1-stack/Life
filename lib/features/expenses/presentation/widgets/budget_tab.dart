import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/expense_category_taxonomy.dart';
import '../../domain/models/variable_pace_forecast.dart';
import '../../domain/providers/budget_providers.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);

const List<String> _hebrewMonths = [
  '',
  'ינואר',
  'פברואר',
  'מרץ',
  'אפריל',
  'מאי',
  'יוני',
  'יולי',
  'אוגוסט',
  'ספטמבר',
  'אוקטובר',
  'נובמבר',
  'דצמבר',
];

/// Monthly category budgets with actual / forecast comparison.
class BudgetTab extends ConsumerWidget {
  const BudgetTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetMonthProvider);
    final forecastAsync = ref.watch(variablePaceForecastProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthlyBudgetsProvider);
        await onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'חודש קודם',
                onPressed: () {
                  ref.read(budgetMonthProvider.notifier).state =
                      DateTime(month.year, month.month - 1);
                },
                icon: const Icon(Icons.chevron_right),
              ),
              Expanded(
                child: Text(
                  '${_hebrewMonths[month.month]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'חודש הבא',
                onPressed: () {
                  ref.read(budgetMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1);
                },
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyPrevious(context, ref, month),
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('העתק מהחודש הקודם'),
              ),
              OutlinedButton.icon(
                onPressed: () => _addOrEditBudget(context, ref, month),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('הוסף תקציב'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          forecastAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('שגיאה: $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (forecast) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BudgetSummaryCard(forecast: forecast),
                if (forecast.isEarlyMonth) ...[
                  const SizedBox(height: 8),
                  const _EarlyForecastChip(),
                ],
                const SizedBox(height: 16),
                Text(
                  'לפי קטגוריה',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (forecast.byCategory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'אין תקציב או הוצאות משתנות לחודש זה.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  for (final row in forecast.byCategory) ...[
                    _BudgetCategoryCard(
                      row: row,
                      onEdit: () => _addOrEditBudget(
                        context,
                        ref,
                        month,
                        category: row.category,
                        initialAmount: row.budget,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPrevious(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
  ) async {
    final prev = DateTime(month.year, month.month - 1);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('העתק תקציב'),
        content: Text(
          'להעתיק את התקציב מ־${_hebrewMonths[prev.month]} ${prev.year}?\n'
          'קטגוריות שכבר קיימות בחודש היעד יידלגו (לא יידרסו).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('העתק'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result = await ref.read(monthlyBudgetRepositoryProvider).copyBudgets(
            sourceYear: prev.year,
            sourceMonth: prev.month,
            targetYear: month.year,
            targetMonth: month.month,
            overwriteExisting: false,
          );
      ref.invalidate(monthlyBudgetsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'הועתקו ${result.copied} · דולגו ${result.skipped}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ההעתקה נכשלה: $e')),
      );
    }
  }

  Future<void> _addOrEditBudget(
    BuildContext context,
    WidgetRef ref,
    DateTime month, {
    String? category,
    double? initialAmount,
  }) async {
    final categoryCtrl = TextEditingController(text: category ?? '');
    final amountCtrl = TextEditingController(
      text: initialAmount != null ? initialAmount.toStringAsFixed(0) : '',
    );
    String selected =
        category ?? ExpenseCategoryTaxonomy.allParents.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(category == null ? 'תקציב חדש' : 'עדכון תקציב'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'קטגוריה'),
                    items: [
                      for (final c in ExpenseCategoryTaxonomy.allParents)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: category != null
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() {
                              selected = v;
                              categoryCtrl.text = v;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'סכום תקציב',
                      prefixText: '₪ ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ביטול'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('שמור'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount < 0) return;

    try {
      await ref.read(monthlyBudgetRepositoryProvider).upsertBudget(
            year: month.year,
            month: month.month,
            category: selected,
            budgetAmount: amount,
          );
      ref.invalidate(monthlyBudgetsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שמירה נכשלה: $e')),
      );
    }
  }
}

class _EarlyForecastChip extends StatelessWidget {
  const _EarlyForecastChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'תחזית מוקדמת',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({required this.forecast});

  final VariablePaceForecast forecast;

  @override
  Widget build(BuildContext context) {
    final totalBudget = forecast.byCategory
        .where((c) => c.budget != null)
        .fold<double>(0, (s, c) => s + c.budget!);
    final variance = totalBudget > 0 ? forecast.forecastEom - totalBudget : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'סיכום תקציב משתנה',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _kv('תקציב משתנה', _currency.format(totalBudget)),
            _kv('הוצאה עד היום', _currency.format(forecast.variableSpendMtd)),
            _kv('תחזית', _currency.format(forecast.forecastEom)),
            if (variance != null)
              _kv(
                variance > 0 ? 'צפי חריגה' : 'צפי יתרה',
                _currency.format(variance.abs()),
                valueColor: variance > 0 ? AppColors.danger : AppColors.income,
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.row,
    required this.onEdit,
  });

  final CategoryPaceForecast row;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final budget = row.budget;
    final remaining = row.remainingBudget;
    final util = row.utilizationPercent;
    final variance = row.forecastVariance;
    final status = row.status;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.category,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),
              _kv('תקציב', budget == null ? '—' : _currency.format(budget)),
              _kv('בפועל', _currency.format(row.actualMtd)),
              _kv(
                'נשאר',
                remaining == null ? '—' : _currency.format(remaining),
                valueColor: remaining != null && remaining < 0
                    ? AppColors.danger
                    : null,
              ),
              _kv(
                'ניצול',
                util == null ? '—' : '${util.toStringAsFixed(1)}%',
              ),
              _kv('תחזית', _currency.format(row.forecastEom)),
              if (variance != null)
                _kv(
                  variance > 0 ? 'צפי חריגה' : 'צפי יתרה',
                  _currency.format(variance.abs()),
                  valueColor:
                      variance > 0 ? AppColors.danger : AppColors.income,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case BudgetStatus.onTrack:
        bg = AppColors.income.withValues(alpha: 0.12);
        fg = AppColors.income;
      case BudgetStatus.watch:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
      case BudgetStatus.overBudget:
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
      case BudgetStatus.noBudget:
        bg = AppColors.line.withValues(alpha: 0.4);
        fg = AppColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
