import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_model.dart';

class ProjectRepository {
  ProjectRepository(this._client);

  final SupabaseClient _client;

  Future<List<ProjectModel>> fetchProjects() async {
    final rows = await _client
        .from('projects')
        .select()
        .eq('is_active', true)
        .order('name');
    return (rows as List)
        .map((row) => ProjectModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<ProjectModel> getOrCreate(String name) async {
    final trimmed = name.trim();
    final existing = await _client
        .from('projects')
        .select()
        .ilike('name', trimmed)
        .limit(1);
    final list = existing as List;
    if (list.isNotEmpty) {
      return ProjectModel.fromJson(Map<String, dynamic>.from(list.first as Map));
    }
    final inserted = await _client
        .from('projects')
        .insert({'name': trimmed})
        .select()
        .single();
    return ProjectModel.fromJson(Map<String, dynamic>.from(inserted));
  }
}
