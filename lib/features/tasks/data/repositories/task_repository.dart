import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';

class TaskRepository {
  TaskRepository(this._client);

  final SupabaseClient _client;

  static const String _tableName = 'tasks';

  Future<List<TaskModel>> fetchActiveTasks({String? category}) async {
    try {
      var query = _client.from(_tableName).select().eq('is_completed', false);

      if (category != null) {
        query = query.eq('category', category);
      }

      final List<Map<String, dynamic>> rows = await query
          .order('priority', ascending: true)
          .order('due_date', ascending: true);

      return rows.map(TaskModel.fromJson).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch active tasks',
        name: 'TaskRepository.fetchActiveTasks',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> toggleTaskStatus(String taskId, bool isCompleted) async {
    try {
      await _client
          .from(_tableName)
          .update({'is_completed': isCompleted}).eq('id', taskId);
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

  Future<void> createTask(TaskModel task) async {
    try {
      await _client.from(_tableName).insert(task.toJsonForInsert());
    } catch (error, stackTrace) {
      developer.log(
        'Failed to create task',
        name: 'TaskRepository.createTask',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _client.from(_tableName).update({
        'title': task.title,
        'description': task.description,
        'is_completed': task.isCompleted,
        'priority': task.priority,
        'category': task.category,
        'due_date': task.dueDate?.toIso8601String(),
      }).eq('id', task.id);
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
