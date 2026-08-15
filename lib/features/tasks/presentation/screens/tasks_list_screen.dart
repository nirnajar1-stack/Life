import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../data/models/task_model.dart';
import '../../domain/models/task_grouping.dart';
import '../../domain/providers/task_providers.dart';
import 'add_task_screen.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

const _filterCategories = [
  null,
  'כללי',
  'פיננסי',
  'בריאותי',
  'אישי',
];

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    TaskModel? task,
  }) async {
    await showAdaptiveForm(
      context: context,
      form: AddTaskScreen(task: task),
    );
    ref.invalidate(activeTasksProvider);
  }

  Future<void> _toggleComplete(
    BuildContext context,
    WidgetRef ref,
    TaskModel task, {
    bool showUndo = true,
  }) async {
    try {
      await ref
          .read(taskRepositoryProvider)
          .toggleTaskStatus(task.id, !task.isCompleted);
      ref.invalidate(activeTasksProvider);
      if (!context.mounted) return;
      if (!showUndo) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              task.isCompleted
                  ? 'המשימה הוחזרה לפעילה'
                  : 'סומנה כהושלמה: ${task.title}',
            ),
            action: SnackBarAction(
              label: 'בטל',
              onPressed: () {
                ref
                    .read(taskRepositoryProvider)
                    .toggleTaskStatus(task.id, task.isCompleted)
                    .then((_) => ref.invalidate(activeTasksProvider));
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

  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת משימה'),
          content: Text('למחוק את "${task.title}"?'),
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

    try {
      await ref.read(taskRepositoryProvider).deleteTask(task.id);
      ref.invalidate(activeTasksProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נמחקה: ${task.title}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(activeTasksProvider);
    final selectedCategory = ref.watch(taskCategoryFilterProvider);
    final query = ref.watch(taskSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('משימות'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('משימה'),
      ),
      body: AppLayout.constrain(
        context: context,
        compact: 640,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppSearchField(
                hint: 'חיפוש משימה…',
                onChanged: (value) =>
                    ref.read(taskSearchQueryProvider.notifier).state = value,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final cat in _filterCategories) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(cat ?? 'הכל'),
                          selected: selectedCategory == cat,
                          onSelected: (_) {
                            ref.read(taskCategoryFilterProvider.notifier).state =
                                cat;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorState(
                  title: 'שגיאה בטעינת המשימות',
                  error: error,
                  onRetry: () => ref.invalidate(activeTasksProvider),
                ),
                data: (tasks) {
                  final visible =
                      tasks.where((t) => taskMatchesQuery(t, query)).toList();
                  return _TasksList(
                    tasks: visible,
                    totalCount: tasks.length,
                    onRefresh: () async =>
                        ref.invalidate(activeTasksProvider),
                    onToggle: (t) => _toggleComplete(context, ref, t),
                    onEdit: (t) => _openForm(context, ref, task: t),
                    onDelete: (t) => _deleteTask(context, ref, t),
                    onAdd: () => _openForm(context, ref),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksList extends StatelessWidget {
  const _TasksList({
    required this.tasks,
    required this.totalCount,
    required this.onRefresh,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final List<TaskModel> tasks;
  final int totalCount;
  final Future<void> Function() onRefresh;
  final ValueChanged<TaskModel> onToggle;
  final ValueChanged<TaskModel> onEdit;
  final ValueChanged<TaskModel> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            AppEmptyState(
              icon: Icons.checklist_rtl,
              title: 'אין משימות פתוחות',
              message: 'הוסף משימה ראשונה ונתחיל לסדר את היום.',
              actionLabel: 'משימה חדשה',
              onAction: onAdd,
            ),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            AppEmptyState(
              icon: Icons.search_off,
              title: 'אין תוצאות',
              message: 'נסה מילה אחרת או נקה את החיפוש.',
              compact: true,
            ),
          ],
        ),
      );
    }

    final groups = groupTasksByTime(tasks);
    final overdue = tasks.where((t) => t.isOverdue).length;
    final allowSwipe = MediaQuery.sizeOf(context).width < 900;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: AppLayout.listPadding,
        children: [
          Text(
            overdue == 0
                ? '$totalCount משימות פתוחות'
                : '$totalCount משימות פתוחות · $overdue באיחור',
            style: TextStyle(
              color: overdue > 0 ? AppColors.danger : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
              child: Text(
                '${group.bucket.label} · ${group.tasks.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: group.bucket == TaskBucket.overdue
                      ? AppColors.danger
                      : AppColors.ink,
                ),
              ),
            ),
            for (final task in group.tasks) ...[
              _TaskCard(
                task: task,
                allowSwipe: allowSwipe,
                onToggle: () => onToggle(task),
                onEdit: () => onEdit(task),
                onDelete: () => onDelete(task),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.allowSwipe,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final bool allowSwipe;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _priorityColor() {
    switch (task.priority) {
      case 1:
        return AppColors.danger;
      case 3:
        return AppColors.muted;
      default:
        return AppColors.warning;
    }
  }

  String _priorityLabel() {
    switch (task.priority) {
      case 1:
        return 'גבוהה';
      case 3:
        return 'נמוכה';
      default:
        return 'בינונית';
    }
  }

  Widget _card() {
    final accent = task.isOverdue ? AppColors.danger : _priorityColor();
    final dueLabel = task.dueDate == null
        ? null
        : task.isOverdue
            ? 'באיחור · ${_dateFormat.format(task.dueDate!)}'
            : task.isDueToday
                ? 'היום'
                : _dateFormat.format(task.dueDate!);

    return Card(
      child: InkWell(
        onTap: onEdit,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'סמן כהושלמה',
                        onPressed: onToggle,
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.expenses,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            if (task.description != null &&
                                task.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  task.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                AppStatusChip(label: task.category),
                                AppStatusChip(
                                  label: _priorityLabel(),
                                  color: _priorityColor(),
                                  filled: task.priority == 1,
                                ),
                                if (dueLabel != null)
                                  AppStatusChip(
                                    label: dueLabel,
                                    icon: task.isOverdue
                                        ? Icons.warning_amber_rounded
                                        : Icons.event,
                                    color: task.isOverdue
                                        ? AppColors.danger
                                        : AppColors.muted,
                                    filled: task.isOverdue || task.isDueToday,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!allowSwipe) return _card();
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: _card(),
    );
  }
}
