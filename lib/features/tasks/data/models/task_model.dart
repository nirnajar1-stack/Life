class TaskModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final int priority;
  final String category;
  final DateTime? dueDate;
  final DateTime createdAt;

  DateTime? get _dueDay {
    if (dueDate == null) return null;
    return DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isOverdue {
    if (isCompleted) return false;
    final due = _dueDay;
    return due != null && due.isBefore(_today);
  }

  bool get isDueToday {
    if (isCompleted) return false;
    final due = _dueDay;
    return due != null && due == _today;
  }

  bool get isDueThisWeek {
    if (isCompleted || isOverdue || isDueToday) return false;
    final due = _dueDay;
    if (due == null) return false;
    return !due.isAfter(_today.add(const Duration(days: 7)));
  }

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    required this.category,
    this.dueDate,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawDueDate = json['due_date'];

    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool,
      priority: (json['priority'] as num).toInt(),
      category: json['category'] as String,
      dueDate: rawDueDate == null ? null : DateTime.parse(rawDueDate as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'category': category,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Payload for inserting a new row. Omits DB-generated columns
  /// (`id`, `created_at`) so Postgres defaults take effect.
  Map<String, dynamic> toJsonForInsert() {
    return {
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
      'category': category,
      'due_date': dueDate?.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    bool? isCompleted,
    int? priority,
    String? category,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
