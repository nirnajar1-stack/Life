import '../../domain/models/task_enums.dart';

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final Eisenhower eisenhower;
  final String category;
  final DateTime? dueDate;
  final DateTime? scheduledDate;
  final String? timeStart;
  final String? timeEnd;
  final int estimatedMinutes;
  final int? actualMinutes;
  final EnergyLevel energyLevel;
  final List<String> contextTags;
  final String? projectId;
  final String? parentTaskId;
  final String? recurrenceRule;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isCompleted =>
      status == TaskStatus.done || status == TaskStatus.archived;

  bool get isOpen =>
      status != TaskStatus.done && status != TaskStatus.archived;

  int get priority => eisenhower.rank;

  DateTime? get _dueDay {
    final source = dueDate ?? scheduledDate;
    if (source == null) return null;
    return DateTime(source.year, source.month, source.day);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isOverdue {
    if (!isOpen) return false;
    final due = _dueDay;
    return due != null && due.isBefore(_today);
  }

  bool get isDueToday {
    if (!isOpen) return false;
    final due = _dueDay;
    return due != null && due == _today;
  }

  bool get isDueThisWeek {
    if (!isOpen || isOverdue || isDueToday) return false;
    final due = _dueDay;
    if (due == null) return false;
    return !due.isAfter(_today.add(const Duration(days: 7)));
  }

  bool get isScheduledToday {
    if (scheduledDate == null) return false;
    final day = DateTime(
      scheduledDate!.year,
      scheduledDate!.month,
      scheduledDate!.day,
    );
    return day == _today;
  }

  bool get hasTimeSlot =>
      (timeStart != null && timeStart!.isNotEmpty) &&
      (timeEnd != null && timeEnd!.isNotEmpty);

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.eisenhower,
    required this.category,
    this.dueDate,
    this.scheduledDate,
    this.timeStart,
    this.timeEnd,
    this.estimatedMinutes = 30,
    this.actualMinutes,
    this.energyLevel = EnergyLevel.medium,
    this.contextTags = const [],
    this.projectId,
    this.parentTaskId,
    this.recurrenceRule,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['context_tags'];
    final tags = tagsRaw is List
        ? tagsRaw.map((e) => '$e').toList()
        : const <String>[];
    final scheduledRaw = json['scheduled_date'];
    DateTime? scheduled;
    if (scheduledRaw is String && scheduledRaw.isNotEmpty) {
      scheduled = DateTime.tryParse(scheduledRaw);
    }

    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatusX.fromDb(json['status'] as String?),
      eisenhower: json['eisenhower'] != null
          ? EisenhowerX.fromDb(json['eisenhower'] as String?)
          : EisenhowerX.fromRank((json['priority'] as num?)?.toInt() ?? 2),
      category: (json['category'] as String?) ?? 'כללי',
      dueDate: json['due_date'] == null
          ? null
          : DateTime.tryParse(json['due_date'] as String),
      scheduledDate: scheduled,
      timeStart: json['time_start'] as String?,
      timeEnd: json['time_end'] as String?,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 30,
      actualMinutes: (json['actual_minutes'] as num?)?.toInt(),
      energyLevel: EnergyLevelX.fromDb(json['energy_level'] as String?),
      contextTags: tags,
      projectId: json['project_id'] as String?,
      parentTaskId: json['parent_task_id'] as String?,
      recurrenceRule: json['recurrence_rule'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonForInsert() {
    return {
      'title': title.length > 120 ? title.substring(0, 120) : title,
      'description': description,
      'status': status.dbValue,
      'eisenhower': eisenhower.dbValue,
      'category': category,
      'due_date': dueDate?.toIso8601String(),
      'scheduled_date': scheduledDate == null
          ? null
          : DateTime(scheduledDate!.year, scheduledDate!.month, scheduledDate!.day)
              .toIso8601String()
              .split('T')
              .first,
      'time_start': timeStart,
      'time_end': timeEnd,
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'energy_level': energyLevel.dbValue,
      'context_tags': contextTags,
      'project_id': projectId,
      'parent_task_id': parentTaskId,
      'recurrence_rule': recurrenceRule,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toJsonForUpdate() => toJsonForInsert();

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskStatus? status,
    Eisenhower? eisenhower,
    String? category,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    String? timeStart,
    String? timeEnd,
    bool clearTime = false,
    int? estimatedMinutes,
    int? actualMinutes,
    EnergyLevel? energyLevel,
    List<String>? contextTags,
    String? projectId,
    bool clearProject = false,
    String? parentTaskId,
    String? recurrenceRule,
    double? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      status: status ?? this.status,
      eisenhower: eisenhower ?? this.eisenhower,
      category: category ?? this.category,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      scheduledDate:
          clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      timeStart: clearTime ? null : (timeStart ?? this.timeStart),
      timeEnd: clearTime ? null : (timeEnd ?? this.timeEnd),
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      energyLevel: energyLevel ?? this.energyLevel,
      contextTags: contextTags ?? this.contextTags,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      parentTaskId: parentTaskId ?? this.parentTaskId,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

double sortOrderBetween(double? before, double? after) {
  if (before == null && after == null) {
    return DateTime.now().millisecondsSinceEpoch.toDouble();
  }
  if (before == null) return after! - 1000;
  if (after == null) return before + 1000;
  return (before + after) / 2;
}
