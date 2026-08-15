import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';

class TaskRepository {
  TaskRepository(this._client);

  final SupabaseClient _client;

  static const String _tableName = 'tasks';

  Future<List<TaskModel>> fetchWorkspaceTasks({String? category}) async {
    try {
      var query = _client.from(_tableName).select().neq('status', 'archived');
      if (category != null) {
        query = query.eq('category', category);
      }
      final rows = await query
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return (rows as List)
          .map((row) => TaskModel.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch workspace tasks',
        name: 'TaskRepository.fetchWorkspaceTasks',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<TaskModel>> fetchActiveTasks({String? category}) async {
    final all = await fetchWorkspaceTasks(category: category);
    return all.where((task) => task.isOpen).toList();
  }

  Future<TaskModel> insertTask(TaskModel task) async {
    try {
      final row = await _client
          .from(_tableName)
          .insert(task.toJsonForInsert())
          .select()
          .single();
      return TaskModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error, stackTrace) {
      developer.log(
        'Failed to create task',
        name: 'TaskRepository.insertTask',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> createTask(TaskModel task) async {
    await insertTask(task);
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _client
          .from(_tableName)
          .update(task.toJsonForUpdate())
          .eq('id', task.id);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to update task',
        name: 'TaskRepository.updateTask',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> patchTask(String id, Map<String, dynamic> values) async {
    await _client.from(_tableName).update(values).eq('id', id);
  }

  Future<void> toggleTaskStatus(String taskId, bool isCompleted) async {
    try {
      await _client.from(_tableName).update({
        'status': isCompleted ? 'done' : 'ready',
      }).eq('id', taskId);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to toggle task status',
        name: 'TaskRepository.toggleTaskStatus',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _client.from(_tableName).delete().eq('id', taskId);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to delete task',
        name: 'TaskRepository.deleteTask',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
