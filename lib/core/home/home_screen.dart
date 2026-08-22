import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../features/expenses/domain/providers/expense_providers.dart';
import '../../features/income/domain/providers/income_providers.dart';
import '../../features/expenses/presentation/screens/expense_form_screen.dart';
import '../../features/habits/data/models/habit_models.dart';
import '../../features/habits/domain/habit_engine.dart';
import '../../features/habits/domain/providers/habit_providers.dart';
import '../../features/habits/presentation/screens/habit_form_screen.dart';
import '../../features/habits/presentation/widgets/habit_checkin_tile.dart';
import '../../features/notifications/presentation/notification_card.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/domain/models/task_enums.dart';
import '../../features/tasks/domain/providers/task_providers.dart';
import '../../features/tasks/presentation/screens/add_task_screen.dart';
import '../layout/app_layout.dart';
import '../shell/app_tab.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_form.dart';
import '../widgets/app_section_header.dart';
import 'home_digest.dart';

final _dateFormat = DateFormat('EEEE, d MMMM yyyy', 'he');
final _shortDate = DateFormat('dd/MM', 'he');
final _currency =
    NumberFormat.currency(locale: 'he_IL', symbol: '₪', decimalDigits: 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'בוקר טוב';
    if (hour < 18) return 'צהריים טובים';
    return 'ערב טוב';
  }

  Future<void> _openTaskForm(
    BuildContext context,
    WidgetRef ref, {
    TaskModel? task,
  }) async {
    await showAdaptiveForm(
      context: context,
      form: AddTaskScreen(task: task),
    );
    ref.read(tasksControllerProvider.notifier).reload();
  }

  Future<void> _openExpenseForm(BuildContext context, WidgetRef ref) async {
    await showAdaptiveForm(
      context: context,
      form: const ExpenseFormScreen(),
    );
    ref.invalidate(expensesRawProvider);
    ref.invalidate(expensesSummaryProvider);
  }

  Future<void> _openHabitForm(BuildContext context, WidgetRef ref) async {
    await showAdaptiveForm(
      context: context,
      form: const HabitFormScreen(),
    );
  }

  Future<void> _toggleTask(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    try {
      await ref.read(tasksControllerProvider.notifier).complete(task);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('סומנה כהושלמה: ${task.title}'),
            action: SnackBarAction(
              label: 'בטל',
              onPressed: () {
                ref
                    .read(tasksControllerProvider.notifier)
                    .updateStatus(task, TaskStatus.ready);
              },
            ),
          ),
        );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('עדכון נכשל: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(activeTasksProvider);
    final expensesAsync = ref.watch(expensesRawProvider);
    final incomesAsync = ref.watch(incomesRawProvider);
    final habitsAsync = ref.watch(habitsControllerProvider);
    final isDesktop = AppLayout.isDesktop(context);
    final digest = HomeDigest.from(
      tasks: tasksAsync.valueOrNull ?? const [],
      expenses: expensesAsync.valueOrNull ?? const [],
      incomes: incomesAsync.valueOrNull ?? const [],
      habits: habitsAsync.valueOrNull ?? const [],
    );
    final loading = tasksAsync.isLoading ||
        expensesAsync.isLoading ||
        incomesAsync.isLoading ||
        habitsAsync.isLoading;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting()),
                  Text(
                    _dateFormat.format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              toolbarHeight: 68,
              automaticallyImplyLeading: false,
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(tasksControllerProvider.notifier).reload();
          ref.read(habitsControllerProvider.notifier).reload();
          ref.invalidate(expensesRawProvider);
          ref.invalidate(expensesSummaryProvider);
          ref.invalidate(incomesRawProvider);
        },
        child: AppLayout.constrain(
          context: context,
          child: ListView(
            padding: AppLayout.pagePadding.copyWith(
              top: isDesktop ? 20 : 4,
              bottom: 40,
            ),
            children: [
              if (isDesktop) ...[
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFormat.format(DateTime.now()),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
              ],
              if (tasksAsync.hasError ||
                  expensesAsync.hasError ||
                  incomesAsync.hasError ||
                  habitsAsync.hasError)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      [
                        if (tasksAsync.hasError)
                          'לא ניתן לטעון משימות: ${tasksAsync.error}',
                        if (expensesAsync.hasError)
                          'לא ניתן לטעון הוצאות: ${expensesAsync.error}',
                        if (incomesAsync.hasError)
                          'לא ניתן לטעון הכנסות: ${incomesAsync.error}',
                        if (habitsAsync.hasError)
                          'לא ניתן לטעון הרגלים: ${habitsAsync.error}',
                      ].join('\n'),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                )
              else ...[
                _BriefingCard(
                  digest: digest,
                  loading: loading,
                  onOpenTasks: () =>
                      ref.read(appTabProvider.notifier).state = AppTab.tasks,
                  onOpenExpenses: () =>
                      ref.read(appTabProvider.notifier).state = AppTab.expenses,
                  onOpenHabits: () =>
                      ref.read(appTabProvider.notifier).state = AppTab.habits,
                ),
                const SizedBox(height: 12),
                _QuickActions(
                  onAddTask: () => _openTaskForm(context, ref),
                  onAddExpense: () => _openExpenseForm(context, ref),
                  onAddHabit: () => _openHabitForm(context, ref),
                ),
                const SizedBox(height: 12),
                const NotificationCard(),
                const SizedBox(height: 24),
                _DigestColumns(
                  digest: digest,
                  habits: habitsAsync.valueOrNull ?? const [],
                  loading: loading,
                  onOpenTasks: () =>
                      ref.read(appTabProvider.notifier).state = AppTab.tasks,
                  onOpenExpenses: () =>
                      ref.read(appTabProvider.notifier).state = AppTab.expenses,
                  onOpenHabits: () =>
                      ref.read(appTabProvider.notifier).state = AppTab.habits,
                  onOpenTask: (task) => _openTaskForm(context, ref, task: task),
                  onToggleTask: (task) => _toggleTask(context, ref, task),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DigestColumns extends StatelessWidget {
  const _DigestColumns({
    required this.digest,
    required this.habits,
    required this.loading,
    required this.onOpenTasks,
    required this.onOpenExpenses,
    required this.onOpenHabits,
    required this.onOpenTask,
    required this.onToggleTask,
  });

  final HomeDigest digest;
  final List<HabitSnapshot> habits;
  final bool loading;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenExpenses;
  final VoidCallback onOpenHabits;
  final ValueChanged<TaskModel> onOpenTask;
  final ValueChanged<TaskModel> onToggleTask;

  @override
  Widget build(BuildContext context) {
    final tasksColumn = Column(
      children: [
        _FocusCard(
          digest: digest,
          loading: loading,
          onOpenAll: onOpenTasks,
          onOpenTask: onOpenTask,
          onToggleTask: onToggleTask,
        ),
        const SizedBox(height: 20),
        _HabitsCard(
          digest: digest,
          habits: habits,
          loading: loading,
          onOpenAll: onOpenHabits,
        ),
      ],
    );
    final moneyColumn = _MoneyCard(
      digest: digest,
      loading: loading,
      onOpenAll: onOpenExpenses,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tasksColumn),
              const SizedBox(width: 16),
              Expanded(child: moneyColumn),
            ],
          );
        }
        return Column(
          children: [
            tasksColumn,
            const SizedBox(height: 20),
            moneyColumn,
          ],
        );
      },
    );
  }
}

class _BriefingCard extends StatelessWidget {
  const _BriefingCard({
    required this.digest,
    required this.loading,
    required this.onOpenTasks,
    required this.onOpenExpenses,
    required this.onOpenHabits,
  });

  final HomeDigest digest;
  final bool loading;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenExpenses;
  final VoidCallback onOpenHabits;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'תקציר היום',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: LinearProgressIndicator(),
              )
            else
              Text(
                digest.headline,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  label: 'באיחור',
                  value: '${digest.overdue.length}',
                  color: digest.overdue.isEmpty
                      ? AppColors.muted
                      : AppColors.danger,
                  onTap: onOpenTasks,
                ),
                _SummaryChip(
                  label: 'היום',
                  value: '${digest.today.length}',
                  color: AppColors.tasks,
                  onTap: onOpenTasks,
                ),
                _SummaryChip(
                  label: 'השבוע',
                  value: '${digest.thisWeek.length}',
                  color: AppColors.warning,
                  onTap: onOpenTasks,
                ),
                _SummaryChip(
                  label: 'הרגלים',
                  value: digest.habitsDueToday == 0
                      ? '—'
                      : '${digest.habitsDoneToday}/${digest.habitsDueToday}',
                  color: AppColors.habits,
                  onTap: onOpenHabits,
                ),
                _SummaryChip(
                  label: 'נטו',
                  value: loading ? '—' : _currency.format(digest.monthNet),
                  color: digest.monthNet >= 0 ? AppColors.income : AppColors.danger,
                  onTap: onOpenExpenses,
                ),
                _SummaryChip(
                  label: 'הוצאות',
                  value: loading ? '—' : _currency.format(digest.monthTotal),
                  color: AppColors.expenses,
                  onTap: onOpenExpenses,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddTask,
    required this.onAddExpense,
    required this.onAddHabit,
  });

  final VoidCallback onAddTask;
  final VoidCallback onAddExpense;
  final VoidCallback onAddHabit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onAddTask,
            icon: const Icon(Icons.add_task, size: 20),
            label: const Text('משימה'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onAddHabit,
            icon: const Icon(Icons.loop, size: 20),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.habits,
            ),
            label: const Text('הרגל'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add_card, size: 20),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.expenses,
            ),
            label: const Text('הוצאה'),
          ),
        ),
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.digest,
    required this.loading,
    required this.onOpenAll,
    required this.onOpenTask,
    required this.onToggleTask,
  });

  final HomeDigest digest;
  final bool loading;
  final VoidCallback onOpenAll;
  final ValueChanged<TaskModel> onOpenTask;
  final ValueChanged<TaskModel> onToggleTask;

  @override
  Widget build(BuildContext context) {
    final urgent = digest.focusTasks;
    final idleUpcoming = !digest.hasUrgentTasks ? digest.upcomingIfIdle : const <TaskModel>[];
    final title = digest.hasUrgentTasks ? 'לטיפול עכשיו' : 'הקרוב';
    final items = digest.hasUrgentTasks ? urgent : idleUpcoming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: title,
          actionLabel: 'הכל',
          onAction: onOpenAll,
        ),
        Card(
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Text(
                        'אין משימות דחופות להיום. אפשר להמשיך ברוגע.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          _FocusTaskRow(
                            task: items[i],
                            onOpen: () => onOpenTask(items[i]),
                            onToggle: () => onToggleTask(items[i]),
                          ),
                          if (i < items.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }
}

class _FocusTaskRow extends StatelessWidget {
  const _FocusTaskRow({
    required this.task,
    required this.onOpen,
    required this.onToggle,
  });

  final TaskModel task;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final stamp = task.isOverdue
        ? 'באיחור'
        : task.isDueToday
            ? 'היום'
            : task.dueDate != null
                ? _shortDate.format(task.dueDate!)
                : task.category;

    return ListTile(
      onTap: onOpen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      leading: IconButton(
        tooltip: 'סמן כהושלמה',
        onPressed: onToggle,
        icon: Icon(
          task.isOverdue
              ? Icons.warning_amber_rounded
              : Icons.check_circle_outline,
          color: task.isOverdue ? AppColors.danger : AppColors.expenses,
        ),
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [task.category, stamp].join(' · '),
        style: TextStyle(
          color: task.isOverdue ? AppColors.danger : AppColors.muted,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({
    required this.digest,
    required this.habits,
    required this.loading,
    required this.onOpenAll,
  });

  final HomeDigest digest;
  final List<HabitSnapshot> habits;
  final bool loading;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final items = habits.where((item) {
      return habitIsDueOn(item.habit, today);
    }).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: digest.habitsDueToday == 0
              ? 'שגרת היום'
              : 'שגרת היום · ${digest.habitsDoneToday}/${digest.habitsDueToday}',
          actionLabel: 'הכל',
          onAction: onOpenAll,
        ),
        Card(
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Text(
                        'אין הרגלים מתוזמנים להיום.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          HabitCheckinTile(snapshot: items[i], compact: true),
                          if (i < items.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.digest,
    required this.loading,
    required this.onOpenAll,
  });

  final HomeDigest digest;
  final bool loading;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final delta = digest.monthDeltaPercent;
    final deltaLabel = delta == null
        ? 'אין חודש קודם להשוואה'
        : '${delta >= 0 ? '↑' : '↓'} ${delta.abs().toStringAsFixed(0)}% מול חודש קודם';
    final deltaColor = delta == null
        ? AppColors.muted
        : (delta > 0 ? AppColors.danger : AppColors.expenses);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'תזרים כספי',
          actionLabel: 'הכל',
          onAction: onOpenAll,
        ),
        Card(
          child: InkWell(
            onTap: onOpenAll,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'נטו החודש',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currency.format(digest.monthNet),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: digest.monthNet >= 0
                                    ? AppColors.income
                                    : AppColors.danger,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'הכנסות ${_currency.format(digest.monthIncome)}',
                                style: const TextStyle(
                                  color: AppColors.income,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'הוצאות ${_currency.format(digest.monthTotal)}',
                                style: const TextStyle(
                                  color: AppColors.expenses,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deltaLabel,
                          style: TextStyle(
                            color: deltaColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (digest.todaySpend > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'היום ${_currency.format(digest.todaySpend)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (digest.topCategory != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.expenses.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'הקטגוריה הבולטת: ${digest.topCategory}'
                              ' · ${_currency.format(digest.topCategoryAmount ?? 0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.expenses,
                              ),
                            ),
                          ),
                        ],
                        if (digest.recent.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'אחרונות',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final expense in digest.recent)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      expense.itemName.isEmpty
                                          ? '(ללא שם)'
                                          : expense.itemName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currency.format(expense.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ] else
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'אין הוצאות עדיין.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
