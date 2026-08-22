import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/income_model.dart';
import '../../domain/models/income_ledger.dart';
import '../../domain/models/income_type.dart';
import '../../domain/providers/income_providers.dart';
import '../widgets/recurring_incomes_tab.dart';
import 'income_form_screen.dart';
import 'recurring_income_form_screen.dart';

final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);
final _shortDate = DateFormat('dd/MM', 'he');

const _hebrewMonths = [
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

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await refreshIncomes(ref);
  }

  Future<void> _openForm(BuildContext context, {IncomeModel? existing}) async {
    await showAdaptiveForm(
      context: context,
      form: IncomeFormScreen(income: existing),
    );
    await _refresh();
  }

  Future<void> _deleteIncome(BuildContext context, IncomeModel income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת הכנסה'),
          content: Text('למחוק את "${income.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(incomeRepositoryProvider).delete(income.id);
      await _refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נמחק: ${income.title}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(incomeLedgerProvider);
    final monthTotal = ref.watch(monthIncomeTotalProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('הכנסות'),
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'פנקס'),
                Tab(text: 'קבועות'),
              ],
            ),
          ),
          floatingActionButton: _IncomeFab(
            onAddVariable: () => _openForm(context),
            onAddRecurring: () {
              showAdaptiveForm(
                context: context,
                form: const RecurringIncomeFormScreen(),
              ).then((_) => _refresh());
            },
          ),
          body: AppLayout.constrain(
            context: context,
            child: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: ledgerAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => ListView(
                      children: [
                        AppErrorState(
                          title: 'שגיאה בטעינת ההכנסות',
                          error: e,
                          onRetry: _refresh,
                        ),
                      ],
                    ),
                    data: (months) {
                      return ListView(
                        padding: AppLayout.listPadding,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _MonthSummaryCard(
                            total: monthTotal.valueOrNull ?? 0,
                            loading: monthTotal.isLoading,
                          ),
                          const SizedBox(height: 16),
                          if (months.isEmpty)
                            AppEmptyState(
                              icon: Icons.trending_up,
                              title: 'אין הכנסות עדיין',
                              message:
                                  'הוסף משכורת חודשית בלשונית "קבועות", או הכנסה חד-פעמית (מד״ו, פרילנס…).',
                              actionLabel: 'הכנסה חד-פעמית',
                              onAction: () => _openForm(context),
                            )
                          else
                            for (final month in months) ...[
                              _MonthSection(
                                section: month,
                                onEdit: (income) => _openForm(context, existing: income),
                                onDelete: (income) =>
                                    _deleteIncome(context, income),
                              ),
                              const SizedBox(height: 12),
                            ],
                        ],
                      );
                    },
                  ),
                ),
                RecurringIncomesTab(onRefresh: _refresh),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.total, required this.loading});

  final double total;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.income.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'סה״כ הכנסות החודש',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            loading
                ? const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _currency.format(total),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.income,
                        ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  final IncomeMonthSection section;
  final void Function(IncomeModel) onEdit;
  final void Function(IncomeModel) onDelete;

  @override
  Widget build(BuildContext context) {
    final label =
        '${_hebrewMonths[section.month]} ${section.year} · ${_currency.format(section.total)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
            ),
          ),
        ),
        for (final income in section.items)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              onTap: () => onEdit(income),
              leading: CircleAvatar(
                backgroundColor: AppColors.income.withValues(alpha: 0.12),
                child: Icon(
                  income.isSalary ? Icons.work_outline : Icons.payments_outlined,
                  color: AppColors.income,
                  size: 20,
                ),
              ),
              title: Text(
                income.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  income.category,
                  income.incomeType.label,
                  _shortDate.format(income.createdAt),
                ].join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currency.format(income.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.income,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit(income);
                      if (value == 'delete') onDelete(income);
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('ערוך')),
                      PopupMenuItem(value: 'delete', child: Text('מחק')),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _IncomeFab extends StatefulWidget {
  const _IncomeFab({
    required this.onAddVariable,
    required this.onAddRecurring,
  });

  final VoidCallback onAddVariable;
  final VoidCallback onAddRecurring;

  @override
  State<_IncomeFab> createState() => _IncomeFabState();
}

class _IncomeFabState extends State<_IncomeFab> {
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.maybeOf(context);
    if (_tabController != controller) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = controller;
      _tabController?.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging ?? true) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabController?.index ?? 0;
    final onPressed = tab == 1 ? widget.onAddRecurring : widget.onAddVariable;
    final label = tab == 1 ? 'קבועה' : 'הכנסה';

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.income,
      icon: const Icon(Icons.add),
      label: Text(label),
    );
  }
}
