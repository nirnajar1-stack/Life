import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

/// Repository is the ONLY layer allowed to talk to Supabase directly.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(supabaseClientProvider));
});

/// Currently selected category filter (null = all active tasks).
final taskCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Async list of active (not completed) tasks, honoring the category filter.
final activeTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final category = ref.watch(taskCategoryFilterProvider);
  return repository.fetchActiveTasks(category: category);
});
