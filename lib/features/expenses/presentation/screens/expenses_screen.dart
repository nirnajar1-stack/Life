import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/expense_model.dart';
import '../../domain/models/expense_ledger.dart';
import '../../domain/models/expense_nature.dart';
import '../../domain/models/expense_period.dart';
import '../../domain/providers/expense_providers.dart';
import '../widgets/expenses_dashboard_view.dart';
import 'expense_form_screen.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);
final _currencyPrecise =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 2);
final _dayFormat = DateFormat('EEEE, d', 'he');
final _shortDateFormat = DateFormat('dd/MM', 'he');

const double _contentMaxWidth = 720;

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

/// Expenses module — analytics dashboard + monthly ledger with drill-down.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(expensesRawProvider);
    ref.invalidate(expensesSummaryProvider);
    ref.invalidate(expenseLedgerProvider);
    ref.invalidate(expenseDashboardProvider);
    ref.invalidate(recentExpensesProvider);
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {ExpenseModel? existing, int messageGroupSize = 1}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          expense: existing,
          messageGroupSize: messageGroupSize,
        ),
      ),
    );
    await _refresh(ref);
  }

  Future<void> _toggleSharedForMessage(
    BuildContext context,
    WidgetRef ref,
    ExpenseTransaction tx,
  ) async {
    final mid = tx.messageId?.trim();
    if (mid == null || mid.isEmpty) return;

    final currentlyShared =
        tx.items.any((e) => SharedExpenseFlag.isShared(e.sharedExp));
    final next = !currentlyShared;

    try {
      await ref.read(expenseRepositoryProvider).updateSharedFlagForMessage(
            messageId: mid,
            sharedExp: SharedExpenseFlag.toDb(next),
          );
      await _refresh(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? 'הקנייה סומנה כמשותפת (${tx.itemCount} פריטים)'
                : 'הקנייה סומנה כלא משותפת (${tx.itemCount} פריטים)',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('עדכון משותפת נכשל: $error')),
      );
    }
  }

  Future<void> _deleteExpense(
      BuildContext context, WidgetRef ref, ExpenseModel expense,
      {bool alreadyConfirmed = false}) async {
    if (!alreadyConfirmed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('מחיקת הוצאה'),
            content: Text('למחוק את "${expense.itemName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('ביטול'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('מחק'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await ref.read(expenseRepositoryProvider).deleteExpense(expense.id);
      await _refresh(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נמחק: ${expense.itemName}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('המחיקה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(expenseDashboardProvider);
    final ledgerAsync = ref.watch(expenseLedgerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('הוצאות'),
            actions: [
              IconButton(
                tooltip: 'רענון',
                onPressed: () => _refresh(ref),
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.insights_outlined), text: 'דשבורד'),
                Tab(icon: Icon(Icons.receipt_long_outlined), text: 'פנקס'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('הוצאה חדשה'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: dashboardAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ListView(
                        children: [
                          _ErrorBox(error: e, onRetry: () => _refresh(ref)),
                        ],
                      ),
                      data: (dashboard) =>
                          ExpensesDashboardView(dashboard: dashboard),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: ledgerAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ListView(
                        children: [
                          _ErrorBox(error: e, onRetry: () => _refresh(ref)),
                        ],
                      ),
                      data: (months) {
                        final period = ref.watch(expensePeriodProvider);
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final p in ExpensePeriod.values)
                                  ChoiceChip(
                                    label: Text(p.label),
                                    selected: period == p,
                                    onSelected: (_) => ref
                                        .read(expensePeriodProvider.notifier)
                                        .state = p,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _MonthlyLedger(
                              months: months,
                              onEdit: (e, {int messageGroupSize = 1}) =>
                                  _openForm(context, ref,
                                      existing: e,
                                      messageGroupSize: messageGroupSize),
                              onDelete: (e, {bool alreadyConfirmed = false}) =>
                                  _deleteExpense(context, ref, e,
                                      alreadyConfirmed: alreadyConfirmed),
                              onToggleShared: (tx) =>
                                  _toggleSharedForMessage(context, ref, tx),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyLedger extends StatelessWidget {
  const _MonthlyLedger({
    required this.months,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleShared,
  });

  final List<ExpenseMonthSection> months;
  final void Function(ExpenseModel expense, {int messageGroupSize}) onEdit;
  final void Function(ExpenseModel expense, {bool alreadyConfirmed}) onDelete;
  final ValueChanged<ExpenseTransaction> onToggleShared;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('אין הוצאות להצגה.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final month in months) ...[
          _MonthHeader(section: month),
          const SizedBox(height: 8),
          for (final tx in month.transactions)
            _TransactionTile(
              transaction: tx,
              onEdit: onEdit,
              onDelete: onDelete,
              onToggleShared: () => onToggleShared(tx),
            ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.section});

  final ExpenseMonthSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = '${_hebrewMonths[section.month]} ${section.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(section.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${section.transactionCount} תנועות · ${section.lineItemCount} פריטים',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleShared,
  });

  final ExpenseTransaction transaction;
  final void Function(ExpenseModel expense, {int messageGroupSize}) onEdit;
  final void Function(ExpenseModel expense, {bool alreadyConfirmed}) onDelete;
  final VoidCallback onToggleShared;

  @override
  Widget build(BuildContext context) {
    if (!transaction.isGrouped) {
      return _SingleExpenseRow(
        expense: transaction.items.first,
        onEdit: () => onEdit(transaction.items.first),
        onDelete: ({bool alreadyConfirmed = false}) => onDelete(
          transaction.items.first,
          alreadyConfirmed: alreadyConfirmed,
        ),
      );
    }

    final isShared = transaction.items
        .any((e) => SharedExpenseFlag.isShared(e.sharedExp));

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade50,
            child: Icon(Icons.receipt_long,
                color: Colors.green.shade700, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (isShared)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    label: const Text('משותפת', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.purple.shade50,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            '${_dayFormat.format(transaction.date)} · ${transaction.itemCount} פריטים\n'
            '${transaction.itemsPreview}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            _currencyPrecise.format(transaction.total),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilterChip(
                  avatar: Icon(
                    isShared ? Icons.group : Icons.person_outline,
                    size: 18,
                  ),
                  label: Text(
                    isShared
                        ? 'קנייה משותפת — לחץ לביטול'
                        : 'סמן קנייה כמשותפת',
                  ),
                  selected: isShared,
                  onSelected: (_) => onToggleShared(),
                ),
              ),
            ),
            const Divider(),
            for (final item in transaction.items)
              _LineItemRow(
                expense: item,
                onEdit: () => onEdit(item,
                    messageGroupSize: transaction.itemCount),
                onDelete: () => onDelete(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _SingleExpenseRow extends StatelessWidget {
  const _SingleExpenseRow({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseModel expense;
  final VoidCallback onEdit;
  final void Function({bool alreadyConfirmed}) onDelete;

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת הוצאה'),
          content: Text('למחוק את "${expense.itemName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('single-${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(alreadyConfirmed: true),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onEdit,
          leading: CircleAvatar(
            backgroundColor: Colors.blueGrey.shade50,
            child: Icon(Icons.payments_outlined,
                color: Colors.blueGrey.shade600, size: 20),
          ),
          title: Text(
            expense.itemName.isEmpty ? '(ללא שם)' : expense.itemName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              if (expense.installmentLabel != null) expense.installmentLabel!,
              expense.normalizedCategory,
              _shortDateFormat.format(expense.createdAt),
            ].join(' · '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currencyPrecise.format(expense.amount),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                tooltip: 'עריכה',
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseModel expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onEdit,
      title: Text(
        expense.itemName.isEmpty ? '(ללא שם)' : expense.itemName,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        [
          if (expense.installmentLabel != null) expense.installmentLabel!,
          expense.normalizedCategory,
        ].join(' · '),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currencyPrecise.format(expense.amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            tooltip: 'עריכה',
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'מחיקה',
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text('שגיאה בטעינת ההוצאות',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('נסה שוב'),
          ),
        ],
      ),
    );
  }
}
