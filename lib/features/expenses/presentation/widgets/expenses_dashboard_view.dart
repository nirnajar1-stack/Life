import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/expense_model.dart';
import '../../domain/models/expense_category_taxonomy.dart';
import '../../domain/models/expense_dashboard.dart';
import '../../domain/models/expense_ledger.dart';
import '../../domain/models/expense_period.dart';
import '../../domain/providers/expense_providers.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);
final _currencyPrecise =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 1);

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

/// Analytics view: KPIs and cross-cuts of spending.
class ExpensesDashboardView extends ConsumerWidget {
  const ExpensesDashboardView({
    super.key,
    required this.dashboard,
    this.onOpenTransaction,
  });

  final ExpenseDashboard dashboard;
  final ValueChanged<ExpenseTransaction>? onOpenTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(expensePeriodProvider);

    if (dashboard.totalItems == 0) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _PeriodFilter(
            selected: period,
            onChanged: (p) =>
                ref.read(expensePeriodProvider.notifier).state = p,
          ),
          const SizedBox(height: 48),
          const Center(child: Text('אין נתונים לתקופה שנבחרה.')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _PeriodFilter(
          selected: period,
          onChanged: (p) =>
              ref.read(expensePeriodProvider.notifier).state = p,
        ),
        const SizedBox(height: 14),
        _KpiStrip(dashboard: dashboard),
        const SizedBox(height: 20),
        _SectionTitle(
          'השוואת חודשים · ${dashboard.currentMonthLabel} מול ${dashboard.previousMonthLabel}',
        ),
        const SizedBox(height: 8),
        _MonthCompareCard(
          comparison: dashboard.monthComparison,
          currentLabel: dashboard.currentMonthLabel,
          previousLabel: dashboard.previousMonthLabel,
          currentTotal: dashboard.thisMonthTotal,
          previousTotal: dashboard.previousMonthTotal,
        ),
        const SizedBox(height: 20),
        _SectionTitle('מגמת הוצאות חודשית'),
        const SizedBox(height: 8),
        _MonthlyTrendCard(months: dashboard.monthlyTrend),
        const SizedBox(height: 20),
        _SectionTitle('חתך לפי קטגוריית־אב'),
        const SizedBox(height: 8),
        _ShareBars(
          items: dashboard.parentCategories,
          grandTotal: dashboard.grandTotal,
          color: const Color(0xFF1976D2),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            'פירוט קטגוריות מקור (גולמי)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          children: [
            _ShareBars(
              items: dashboard.rawCategories,
              grandTotal: dashboard.grandTotal,
              color: Colors.blueGrey,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionTitle('משתנה · קבועה · תשלומים'),
        const SizedBox(height: 8),
        _NatureSplitCard(dashboard: dashboard),
        const SizedBox(height: 20),
        _SectionTitle('מקור הנתונים'),
        const SizedBox(height: 8),
        _ShareBars(
          items: dashboard.bySource,
          grandTotal: dashboard.grandTotal,
          color: const Color(0xFF6A1B9A),
        ),
        const SizedBox(height: 20),
        _SectionTitle('התנועות הגדולות'),
        const SizedBox(height: 8),
        _TopTransactionsCard(
          transactions: dashboard.topTransactions,
          onOpen: onOpenTransaction,
        ),
        const SizedBox(height: 20),
        _SectionTitle('הפריטים היקרים ביותר'),
        const SizedBox(height: 8),
        _TopItemsCard(items: dashboard.topItems),
      ],
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.selected,
    required this.onChanged,
  });

  final ExpensePeriod selected;
  final ValueChanged<ExpensePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final period in ExpensePeriod.values)
          ChoiceChip(
            label: Text(period.label),
            selected: selected == period,
            onSelected: (_) => onChanged(period),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.dashboard});

  final ExpenseDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final mom = dashboard.monthOverMonthPercent;
    final momLabel = mom == null
        ? 'אין בסיס להשוואה'
        : '${mom >= 0 ? '↑' : '↓'} ${mom.abs().toStringAsFixed(0)}% מול חודש קודם';
    final momColor = mom == null
        ? Colors.grey
        : (mom <= 0 ? Colors.green.shade700 : Colors.red.shade700);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'תקופה: ${dashboard.period.label} · ${dashboard.totalItems} פריטים',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'החודש',
                value: _currency.format(dashboard.thisMonthTotal),
                subtitle: momLabel,
                subtitleColor: momColor,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'חודש קודם',
                value: _currency.format(dashboard.previousMonthTotal),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'ממוצע חודשי',
                value: _currency.format(dashboard.averageMonthTotal),
                color: Theme.of(context).colorScheme.tertiaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'סה״כ בתקופה',
                value: _currency.format(dashboard.grandTotal),
                subtitle: '${dashboard.totalItems} פריטים',
                color: Colors.blueGrey.shade100,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.subtitleColor,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor ?? Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthCompareCard extends StatelessWidget {
  const _MonthCompareCard({
    required this.comparison,
    required this.currentLabel,
    required this.previousLabel,
    required this.currentTotal,
    required this.previousTotal,
  });

  final List<CategoryMonthCompare> comparison;
  final String currentLabel;
  final String previousLabel;
  final double currentTotal;
  final double previousTotal;

  @override
  Widget build(BuildContext context) {
    final delta = currentTotal - previousTotal;
    final deltaColor =
        delta <= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _CompareTotal(
                    label: currentLabel,
                    total: currentTotal,
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      delta <= 0
                          ? Icons.trending_down
                          : Icons.trending_up,
                      color: deltaColor,
                    ),
                    Text(
                      _currency.format(delta.abs()),
                      style: TextStyle(
                        color: deltaColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: _CompareTotal(
                    label: previousLabel,
                    total: previousTotal,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('קטגוריה',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('נוכחי',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                ),
                Expanded(
                  child: Text('קודם',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                ),
                const SizedBox(
                  width: 56,
                  child: Text('Δ',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final row in comparison.take(8)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(row.category,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text(
                        _currency.format(row.currentTotal),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _currency.format(row.previousTotal),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        '${row.delta >= 0 ? '+' : ''}${_currency.format(row.delta)}',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: row.delta <= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompareTotal extends StatelessWidget {
  const _CompareTotal({
    required this.label,
    required this.total,
    this.alignEnd = false,
  });

  final String label;
  final double total;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text(
          _currency.format(total),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.months});

  final List<MonthSpend> months;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const Text('אין נתונים');

    final chronological = months.reversed.toList();
    final maxTotal = chronological
        .map((m) => m.total)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxTotal <= 0 ? 1.0 : maxTotal;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in chronological)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _compactMoney(m.total),
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor:
                                    (m.total / safeMax).clamp(0.05, 1),
                                widthFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final m in chronological)
                  Expanded(
                    child: Text(
                      _hebrewMonths[m.month].length <= 3
                          ? _hebrewMonths[m.month]
                          : _hebrewMonths[m.month].substring(0, 3),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}

class _ShareBars extends StatelessWidget {
  const _ShareBars({
    required this.items,
    required this.grandTotal,
    required this.color,
  });

  final List<NamedAmount> items;
  final double grandTotal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('אין נתונים');

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (final item in items) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${_currency.format(item.total)} · '
                    '${(item.shareOf(grandTotal) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: item.shareOf(grandTotal),
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${item.count} פריטים',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _NatureSplitCard extends StatelessWidget {
  const _NatureSplitCard({required this.dashboard});

  final ExpenseDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final total = dashboard.variableTotal +
        dashboard.fixedTotal +
        dashboard.installmentTotal;
    final variableShare =
        total <= 0 ? 0.0 : dashboard.variableTotal / total;
    final fixedShare = total <= 0 ? 0.0 : dashboard.fixedTotal / total;
    final installmentShare =
        total <= 0 ? 0.0 : dashboard.installmentTotal / total;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SplitStat(
                    label: 'משתנה',
                    amount: dashboard.variableTotal,
                    count: dashboard.variableCount,
                    share: variableShare,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SplitStat(
                    label: 'קבועה',
                    amount: dashboard.fixedTotal,
                    count: dashboard.fixedCount,
                    share: fixedShare,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SplitStat(
                    label: 'תשלומים',
                    amount: dashboard.installmentTotal,
                    count: dashboard.installmentCount,
                    share: installmentShare,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (variableShare > 0)
                      Expanded(
                        flex: (variableShare * 1000).round().clamp(1, 1000),
                        child: Container(color: Colors.teal),
                      ),
                    if (fixedShare > 0)
                      Expanded(
                        flex: (fixedShare * 1000).round().clamp(1, 1000),
                        child: Container(color: Colors.indigo),
                      ),
                    if (installmentShare > 0)
                      Expanded(
                        flex: (installmentShare * 1000).round().clamp(1, 1000),
                        child: Container(color: Colors.deepOrange),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'משתנה ${(variableShare * 100).toStringAsFixed(0)}% · '
              'קבועה ${(fixedShare * 100).toStringAsFixed(0)}% · '
              'תשלומים ${(installmentShare * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitStat extends StatelessWidget {
  const _SplitStat({
    required this.label,
    required this.amount,
    required this.count,
    required this.share,
    required this.color,
  });

  final String label;
  final double amount;
  final int count;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _currency.format(amount),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          '$count · ${(share * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _TopTransactionsCard extends StatelessWidget {
  const _TopTransactionsCard({
    required this.transactions,
    this.onOpen,
  });

  final List<ExpenseTransaction> transactions;
  final ValueChanged<ExpenseTransaction>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const Text('אין נתונים');

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            ListTile(
              onTap: onOpen == null ? null : () => onOpen!(transactions[i]),
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                transactions[i].title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                transactions[i].isGrouped
                    ? '${transactions[i].itemCount} פריטים · '
                        '${_hebrewMonths[transactions[i].date.month]} '
                        '${transactions[i].date.year}'
                    : '${transactions[i].primaryCategory} · '
                        '${_hebrewMonths[transactions[i].date.month]} '
                        '${transactions[i].date.year}',
              ),
              trailing: Text(
                _currencyPrecise.format(transactions[i].total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (i < transactions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TopItemsCard extends StatelessWidget {
  const _TopItemsCard({required this.items});

  final List<ExpenseModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('אין נתונים');

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade50,
                child: Icon(Icons.local_fire_department,
                    color: Colors.red.shade400, size: 18),
              ),
              title: Text(
                items[i].itemName.isEmpty ? '(ללא שם)' : items[i].itemName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${ExpenseCategoryTaxonomy.resolveParent(items[i].category)}'
                '${items[i].normalizedCategory.isEmpty ? '' : ' · ${items[i].normalizedCategory}'} · '
                '${_hebrewMonths[items[i].createdAt.month]} '
                '${items[i].createdAt.year}',
              ),
              trailing: Text(
                _currencyPrecise.format(items[i].amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (i < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
