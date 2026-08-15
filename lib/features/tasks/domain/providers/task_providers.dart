import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/project_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../models/capture_parse.dart';
import '../models/recurrence.dart';
import '../models/task_enums.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(supabaseClientProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(supabaseClientProvider));
});

final taskCategoryFilterProvider = StateProvider<String?>((ref) => null);
final taskSearchQueryProvider = StateProvider<String>((ref) => '');
final tasksWorkspaceViewProvider =
    StateProvider<TasksWorkspaceView>((ref) => TasksWorkspaceView.today);
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);
final tasksEnergyFilterProvider = StateProvider<EnergyLevel?>((ref) => null);
final tasksContextFilterProvider = StateProvider<String?>((ref) => null);
final captureFocusTickProvider = StateProvider<int>((ref) => 0);

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) {
  return ref.watch(projectRepositoryProvider).fetchProjects();
});

final tasksControllerProvider =
    StateNotifierProvider<TasksController, AsyncValue<List<TaskModel>>>((ref) {
  return TasksController(ref);
});

/// Open (not done/archived) tasks — used by home digest and nav badge.
final activeTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  return ref.watch(tasksControllerProvider).whenData(
        (tasks) => tasks.where((task) => task.isOpen).toList(),
      );
});

class TasksController extends StateNotifier<AsyncValue<List<TaskModel>>> {
  TasksController(this._ref) : super(const AsyncLoading()) {
    _ref.listen<String?>(taskCategoryFilterProvider, (_, __) {
      reload();
    });
    reload();
  }

  final Ref _ref;

  TaskRepository get _repo => _ref.read(taskRepositoryProvider);

  Future<void> reload() async {
    try {
      final category = _ref.read(taskCategoryFilterProvider);
      final tasks = await _repo.fetchWorkspaceTasks(category: category);
      if (!mounted) return;
      state = AsyncData(tasks);
    } catch (error, stack) {
      if (!mounted) return;
      state = AsyncError(error, stack);
    }
  }

  List<TaskModel> get _items => state.valueOrNull ?? const [];

  void _setItems(List<TaskModel> items) {
    state = AsyncData(items);
  }

  Future<void> _rollback(List<TaskModel> previous, Object error) async {
    if (!mounted) return;
    state = AsyncData(previous);
  }

  Future<TaskModel?> capture(String raw) async {
    final parsed = parseTaskCapture(raw);
    if (parsed.title.isEmpty) return null;
    final previous = _items;
    String? projectId;
    if (parsed.projectName != null && parsed.projectName!.isNotEmpty) {
      final project =
          await _ref.read(projectRepositoryProvider).getOrCreate(parsed.projectName!);
      projectId = project.id;
      _ref.invalidate(projectsProvider);
    }
    final draft = TaskModel(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      title: parsed.title,
      status: TaskStatus.inbox,
      eisenhower: EisenhowerX.fromDb(parsed.eisenhowerDb),
      category: parsed.contextTags.isNotEmpty
          ? parsed.contextTags.first.replaceFirst('@', '')
          : 'כללי',
      dueDate: parsed.dueDate,
      scheduledDate: parsed.scheduledDate,
      estimatedMinutes: parsed.estimatedMinutes ?? 30,
      energyLevel: EnergyLevelX.fromDb(parsed.energyDb),
      contextTags: parsed.contextTags,
      projectId: projectId,
      recurrenceRule: parsed.recurrenceRule,
      sortOrder: sortOrderBetween(null, previous.isEmpty ? null : previous.first.sortOrder),
      createdAt: DateTime.now(),
    );
    _setItems([draft, ...previous]);
    try {
      final saved = await _repo.insertTask(draft);
      if (!mounted) return saved;
      _setItems([
        saved,
        ..._items.where((task) => task.id != draft.id),
      ]);
      return saved;
    } catch (error) {
      await _rollback(previous, error);
      rethrow;
    }
  }

  Future<void> complete(TaskModel task) async {
    await updateStatus(task, TaskStatus.done);
  }

  Future<void> toggleComplete(TaskModel task) async {
    if (task.isCompleted) {
      await updateStatus(task, TaskStatus.ready);
    } else {
      await updateStatus(task, TaskStatus.done);
    }
  }

  Future<void> updateStatus(TaskModel task, TaskStatus status) async {
    final previous = _items;
    var next = task.copyWith(status: status);
    _setItems(_replace(previous, next));
    try {
      await _repo.updateTask(next);
      if (status == TaskStatus.done && task.recurrenceRule != null) {
        final nextDate = nextRecurrenceDate(
          task.recurrenceRule,
          task.scheduledDate ?? task.dueDate ?? DateTime.now(),
        );
        if (nextDate != null) {
          final followUp = task.copyWith(
            id: '',
            status: TaskStatus.ready,
            scheduledDate: DateTime(nextDate.year, nextDate.month, nextDate.day),
            dueDate: DateTime(nextDate.year, nextDate.month, nextDate.day, 18),
            clearTime: true,
            sortOrder: sortOrderBetween(
              _items.isEmpty ? null : _items.last.sortOrder,
              null,
            ),
          );
          final saved = await _repo.insertTask(followUp);
          if (!mounted) return;
          _setItems([..._items, saved]);
        }
      }
      await _maybeCompleteParent(task.parentTaskId);
    } catch (error) {
      await _rollback(previous, error);
      rethrow;
    }
  }

  Future<void> _maybeCompleteParent(String? parentId) async {
    if (parentId == null) return;
    final children = _items.where((task) => task.parentTaskId == parentId).toList();
    if (children.isEmpty) return;
    final allDone = children.every((task) => task.isCompleted);
    if (!allDone) return;
    final parent = _items.cast<TaskModel?>().firstWhere(
          (task) => task?.id == parentId,
          orElse: () => null,
        );
    if (parent == null || parent.isCompleted) return;
    await updateStatus(parent, TaskStatus.done);
  }

  Future<void> updateTask(TaskModel task) async {
    final previous = _items;
    _setItems(_replace(previous, task));
    try {
      await _repo.updateTask(task);
    } catch (error) {
      await _rollback(previous, error);
      rethrow;
    }
  }

  Future<void> moveEisenhower(TaskModel task, Eisenhower value) async {
    await updateTask(task.copyWith(eisenhower: value));
  }

  Future<void> scheduleInSlot({
    required TaskModel task,
    required DateTime day,
    required String start,
    required String end,
  }) {
    return updateTask(
      task.copyWith(
        scheduledDate: DateTime(day.year, day.month, day.day),
        timeStart: start,
        timeEnd: end,
        status: task.status == TaskStatus.inbox ? TaskStatus.ready : task.status,
      ),
    );
  }

  Future<void> reorder(TaskModel task, double newOrder) {
    return updateTask(task.copyWith(sortOrder: newOrder));
  }

  Future<void> deleteTask(String id) async {
    final previous = _items;
    _setItems(previous.where((task) => task.id != id).toList());
    try {
      await _repo.deleteTask(id);
    } catch (error) {
      await _rollback(previous, error);
      rethrow;
    }
  }

  List<TaskModel> _replace(List<TaskModel> source, TaskModel next) {
    return [
      for (final task in source)
        if (task.id == next.id) next else task,
    ];
  }
}
