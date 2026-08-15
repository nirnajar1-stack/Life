import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_search_field.dart';
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
    await showAdaptiveForm(
      context: context,
      form: ExpenseFormScreen(
        expense: existing,
        messageGroupSize: messageGroupSize,
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'פנקס'),
                Tab(text: 'ניתוח'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, ref),
            backgroundColor: AppColors.expenses,
            icon: const Icon(Icons.add),
            label: const Text('הוצאה'),
          ),
          body: AppLayout.constrain(
            context: context,
            child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: ledgerAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ListView(
                        children: [
                          AppErrorState(
                            title: 'שגיאה בטעינת ההוצאות',
                            error: e,
                            onRetry: () => _refresh(ref),
                          ),
                        ],
                      ),
                      data: (months) {
                        final period = ref.watch(expensePeriodProvider);
                        final query = ref.watch(expenseSearchQueryProvider);
                        final visible = query.trim().isEmpty
                            ? months
                            : months
                                .map(
                                  (month) => ExpenseMonthSection(
                                    year: month.year,
                                    month: month.month,
                                    transactions: month.transactions
                                        .where((tx) => tx.matchesQuery(query))
                                        .toList(),
                                  ),
                                )
                                .where((month) => month.transactions.isNotEmpty)
                                .toList();
                        return ListView(
                          padding: AppLayout.listPadding,
                          children: [
                            AppSearchField(
                              hint: 'חיפוש בקנייה, פריט או קטגוריה…',
                              onChanged: (value) => ref
                                  .read(expenseSearchQueryProvider.notifier)
                                  .state = value,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final p in ExpensePeriod.values)
                                  ChoiceChip(
                                    showCheckmark: false,
                                    label: Text(p.label),
                                    selected: period == p,
                                    onSelected: (_) => ref
                                        .read(expensePeriodProvider.notifier)
                                        .state = p,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (visible.isEmpty && query.trim().isNotEmpty)
                              const AppEmptyState(
                                icon: Icons.search_off,
                                title: 'אין תוצאות',
                                message: 'נסה מילה אחרת או נקה את החיפוש.',
                                compact: true,
                              )
                            else
                              _MonthlyLedger(
                                months: visible,
                                onEdit: (e, {int messageGroupSize = 1}) =>
                                    _openForm(context, ref,
                                        existing: e,
                                        messageGroupSize: messageGroupSize),
                                onDelete:
                                    (e, {bool alreadyConfirmed = false}) =>
                                        _deleteExpense(context, ref, e,
                                            alreadyConfirmed: alreadyConfirmed),
                                onToggleShared: (tx) =>
                                    _toggleSharedForMessage(context, ref, tx),
                                onAdd: () => _openForm(context, ref),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: dashboardAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ListView(
                        children: [
                          AppErrorState(
                            title: 'שגיאה בטעינת ההוצאות',
                            error: e,
                            onRetry: () => _refresh(ref),
                          ),
                        ],
                      ),
                      data: (dashboard) =>
                          ExpensesDashboardView(dashboard: dashboard),
                    ),
                  ),
                ],
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
    required this.onAdd,
  });

  final List<ExpenseMonthSection> months;
  final void Function(ExpenseModel expense, {int messageGroupSize}) onEdit;
  final void Function(ExpenseModel expense, {bool alreadyConfirmed}) onDelete;
  final ValueChanged<ExpenseTransaction> onToggleShared;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'אין הוצאות להצגה',
        message: 'הוסף הוצאה או שנה את טווח התקופה.',
        actionLabel: 'הוצאה חדשה',
        onAction: onAdd,
        compact: true,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(section.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${section.transactionCount} תנועות · ${section.lineItemCount} פריטים',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.expenses.withValues(alpha: 0.12),
            child: const Icon(Icons.receipt_long,
                color: AppColors.expenses, size: 20),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  '${_dayFormat.format(transaction.date)} · ${transaction.itemCount} פריטים',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (isShared)
                  const AppStatusChip(
                    label: 'משותפת',
                    icon: Icons.group,
                    color: AppColors.shared,
                    filled: true,
                  ),
              ],
            ),
          ),
          trailing: Text(
            _currencyPrecise.format(transaction.total),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilterChip(
                  showCheckmark: false,
                  avatar: Icon(
                    isShared ? Icons.group : Icons.person_outline,
                    size: 18,
                  ),
                  label: Text(isShared ? 'קנייה משותפת' : 'סמן כמשותפת'),
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
    final allowSwipe = MediaQuery.sizeOf(context).width < 900;
    final tile = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.expenses.withValues(alpha: 0.12),
          child: const Icon(Icons.payments_outlined,
              color: AppColors.expenses, size: 20),
        ),
        title: Text(
          expense.itemName.isEmpty ? '(ללא שם)' : expense.itemName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (expense.installmentLabel != null) expense.installmentLabel!,
            expense.normalizedCategory,
            _shortDateFormat.format(expense.createdAt),
          ].join(' · '),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currencyPrecise.format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            if (!allowSwipe)
              PopupMenuButton<String>(
                tooltip: 'עוד פעולות',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('עריכה')),
                  PopupMenuItem(value: 'delete', child: Text('מחיקה')),
                ],
              ),
          ],
        ),
      ),
    );

    if (!allowSwipe) return tile;

    return Dismissible(
      key: ValueKey('single-${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(alreadyConfirmed: true),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: tile,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onEdit,
      title: Row(
        children: [
          Expanded(
            child: Text(
              expense.itemName.isEmpty ? '(ללא שם)' : expense.itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currencyPrecise.format(expense.amount),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      subtitle: Text(
        [
          if (expense.installmentLabel != null) expense.installmentLabel!,
          expense.normalizedCategory,
        ].join(' · '),
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'עוד פעולות',
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('עריכה')),
          PopupMenuItem(value: 'delete', child: Text('מחיקה')),
        ],
      ),
    );
  }
}
