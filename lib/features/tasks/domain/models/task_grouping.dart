import '../../data/models/task_model.dart';

enum TaskBucket { overdue, today, week, later, undated }

extension TaskBucketX on TaskBucket {
  String get label {
    switch (this) {
      case TaskBucket.overdue:
        return 'באיחור';
      case TaskBucket.today:
        return 'היום';
      case TaskBucket.week:
        return 'השבוע';
      case TaskBucket.later:
        return 'בהמשך';
      case TaskBucket.undated:
        return 'ללא תאריך יעד';
    }
  }
}

extension TaskTimeGrouping on TaskModel {
  TaskBucket get bucket {
    if (isOverdue) return TaskBucket.overdue;
    if (isDueToday) return TaskBucket.today;
    if (isDueThisWeek) return TaskBucket.week;
    if (dueDate != null) return TaskBucket.later;
    return TaskBucket.undated;
  }
}

class TaskGroup {
  const TaskGroup({required this.bucket, required this.tasks});

  final TaskBucket bucket;
  final List<TaskModel> tasks;
}

List<TaskGroup> groupTasksByTime(List<TaskModel> tasks) {
  final grouped = <TaskBucket, List<TaskModel>>{
    for (final bucket in TaskBucket.values) bucket: [],
  };
  for (final task in tasks) {
    grouped[task.bucket]!.add(task);
  }
  return TaskBucket.values
      .map((bucket) => TaskGroup(bucket: bucket, tasks: grouped[bucket]!))
      .where((group) => group.tasks.isNotEmpty)
      .toList();
}

bool taskMatchesQuery(TaskModel task, String query) {
  final q = query.trim();
  if (q.isEmpty) return true;
  final haystack = [
    task.title,
    task.description ?? '',
    task.category,
  ].join(' ').toLowerCase();
  return haystack.contains(q.toLowerCase());
}
