import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_model.dart';
import '../../domain/providers/task_providers.dart';
import 'add_task_screen.dart';

const double _contentMaxWidth = 600;

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  Future<void> _openAddTask(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    // Refresh the list after returning from the add screen.
    ref.invalidate(activeTasksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TaskModel>> tasksAsync =
        ref.watch(activeTasksProvider);

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
          onPressed: () => _openAddTask(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('משימה חדשה'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: () => ref.invalidate(activeTasksProvider),
              ),
              data: (tasks) => _TasksList(
                tasks: tasks,
                onRefresh: () async => ref.invalidate(activeTasksProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TasksList extends StatelessWidget {
  const _TasksList({required this.tasks, required this.onRefresh});

  final List<TaskModel> tasks;
  final Future<void> Function() onRefresh;

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
                'אין משימות פעילות עדיין.\nלחץ על "משימה חדשה" כדי להתחיל.',
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
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: task.description == null || task.description!.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(task.description!),
              ),
        trailing: Chip(
          label: Text(task.category),
          visualDensity: VisualDensity.compact,
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
