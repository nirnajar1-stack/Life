import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/task_model.dart';
import '../../domain/providers/task_providers.dart';
import 'add_task_screen.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

const double _contentMaxWidth = 600;

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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
    );
    ref.invalidate(activeTasksProvider);
  }

  Future<void> _toggleComplete(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    try {
      await ref
          .read(taskRepositoryProvider)
          .toggleTaskStatus(task.id, !task.isCompleted);
      ref.invalidate(activeTasksProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task.isCompleted
                ? 'המשימה הוחזרה לפעילה'
                : 'סומנה כהושלמה: ${task.title}',
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('המשימות שלי'),
          actions: [
            IconButton(
              tooltip: 'רענון',
              onPressed: () => ref.invalidate(activeTasksProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('משימה חדשה'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final cat in _filterCategories) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(cat ?? 'הכל'),
                              selected: selectedCategory == cat,
                              onSelected: (_) {
                                ref
                                    .read(taskCategoryFilterProvider.notifier)
                                    .state = cat;
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
                    error: (error, _) => _ErrorState(
                      error: error,
                      onRetry: () => ref.invalidate(activeTasksProvider),
                    ),
                    data: (tasks) => _TasksList(
                      tasks: tasks,
                      onRefresh: () async =>
                          ref.invalidate(activeTasksProvider),
                      onToggle: (t) => _toggleComplete(context, ref, t),
                      onEdit: (t) => _openForm(context, ref, task: t),
                      onDelete: (t) => _deleteTask(context, ref, t),
                    ),
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

class _TasksList extends StatelessWidget {
  const _TasksList({
    required this.tasks,
    required this.onRefresh,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TaskModel> tasks;
  final Future<void> Function() onRefresh;
  final ValueChanged<TaskModel> onToggle;
  final ValueChanged<TaskModel> onEdit;
  final ValueChanged<TaskModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.checklist_rtl, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                'אין משימות פעילות.\nלחץ על "משימה חדשה" כדי להתחיל.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _TaskCard(
          task: tasks[index],
          onToggle: () => onToggle(tasks[index]),
          onEdit: () => onEdit(tasks[index]),
          onDelete: () => onDelete(tasks[index]),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _priorityColor() {
    switch (task.priority) {
      case 1:
        return Colors.red.shade400;
      case 3:
        return Colors.grey.shade500;
      default:
        return Colors.orange.shade400;
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

  @override
  Widget build(BuildContext context) {
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
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          onTap: onEdit,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          leading: IconButton(
            tooltip: 'סמן כהושלמה',
            onPressed: onToggle,
            icon: Icon(
              Icons.check_circle_outline,
              color: Colors.green.shade600,
            ),
          ),
          title: Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(task.description!),
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(task.category),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  Chip(
                    label: Text(_priorityLabel()),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    backgroundColor: _priorityColor().withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: _priorityColor()),
                  ),
                  if (task.dueDate != null)
                    Chip(
                      avatar: const Icon(Icons.event, size: 16),
                      label: Text(_dateFormat.format(task.dueDate!)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'עריכה',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text(
            'שגיאה בטעינת המשימות מ-Supabase',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
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
