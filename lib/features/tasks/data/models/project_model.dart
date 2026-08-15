class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
