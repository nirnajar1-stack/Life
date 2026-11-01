import '../domain/models.dart';
import 'portal_client.dart';

class TaskFilters {
  const TaskFilters({
    this.search = '',
    this.status,
    this.treatmentUnitId,
    this.personId,
    this.domain,
    this.priority,
    this.onlyOverdue = false,
    this.onlyRequiresAttention = false,
    this.openOnly = true,
  });

  final String search;
  final TaskStatus? status;
  final String? treatmentUnitId;
  final String? personId;
  final String? domain;
  final TaskPriority? priority;
  final bool onlyOverdue;
  final bool onlyRequiresAttention;
  final bool openOnly;

  TaskFilters copyWith({
    String? search,
    TaskStatus? status,
    String? treatmentUnitId,
    String? personId,
    String? domain,
    TaskPriority? priority,
    bool? onlyOverdue,
    bool? onlyRequiresAttention,
    bool? openOnly,
    bool clearStatus = false,
    bool clearUnit = false,
    bool clearPerson = false,
    bool clearDomain = false,
    bool clearPriority = false,
  }) {
    return TaskFilters(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      treatmentUnitId: clearUnit ? null : (treatmentUnitId ?? this.treatmentUnitId),
      personId: clearPerson ? null : (personId ?? this.personId),
      domain: clearDomain ? null : (domain ?? this.domain),
      priority: clearPriority ? null : (priority ?? this.priority),
      onlyOverdue: onlyOverdue ?? this.onlyOverdue,
      onlyRequiresAttention:
          onlyRequiresAttention ?? this.onlyRequiresAttention,
      openOnly: openOnly ?? this.openOnly,
    );
  }
}

class TaskService {
  PortalTask _map(Map<String, dynamic> row) {
    final unit = row['treatment_units'];
    final family = row['families'];
    final person = row['persons'];
    final metadata = row['metadata'];
    final familyVisible = metadata is Map &&
        '${metadata['family_visible']}' == 'true';

    return PortalTask(
      id: row['id'] as String,
      titleHe: row['title_he'] as String,
      descriptionHe: row['description_he'] as String?,
      status: taskStatusFromDb(row['status'] as String),
      priority: taskPriorityFromDb(row['priority'] as String),
      treatmentUnitId: row['treatment_unit_id'] as String,
      familyId: row['family_id'] as String,
      personId: row['person_id'] as String?,
      domain: row['domain'] as String?,
      dueAt: row['due_at'] == null
          ? null
          : DateTime.tryParse(row['due_at'] as String)?.toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      familyVisible: familyVisible,
      unitCode: unit is Map ? unit['unit_code'] as String? : null,
      familyNameHe: family is Map ? family['display_name_he'] as String? : null,
      personNameHe: person is Map
          ? '${person['first_name_he']} ${person['last_name_he']}'
          : null,
    );
  }

  Future<List<PortalTask>> listTasks({TaskFilters filters = const TaskFilters()}) async {
    var query = portalClient.from('tasks').select(
          '*, treatment_units(unit_code, title_he), families(display_name_he), persons(first_name_he, last_name_he)',
        );

    // soft-delete filter
    query = query.isFilter('deleted_at', null);

    if (filters.openOnly) {
      query = query.not('status', 'in', '("completed","cancelled")');
    }
    if (filters.status != null) {
      query = query.eq('status', taskStatusToDb(filters.status!));
    }
    if (filters.treatmentUnitId != null) {
      query = query.eq('treatment_unit_id', filters.treatmentUnitId!);
    }
    if (filters.personId != null) {
      query = query.eq('person_id', filters.personId!);
    }
    if (filters.domain != null && filters.domain!.isNotEmpty) {
      query = query.eq('domain', filters.domain!);
    }
    if (filters.priority != null) {
      query = query.eq(
        'priority',
        filters.priority!.name == 'critical'
            ? 'critical'
            : filters.priority!.name == 'high'
                ? 'high'
                : filters.priority!.name == 'low'
                    ? 'low'
                    : 'medium',
      );
    }

    final rows = await query.order('updated_at', ascending: false).limit(500);
    var tasks = (rows as List)
        .map((e) => _map(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (filters.search.trim().isNotEmpty) {
      final q = filters.search.trim().toLowerCase();
      tasks = tasks
          .where(
            (t) =>
                t.titleHe.toLowerCase().contains(q) ||
                (t.familyNameHe?.toLowerCase().contains(q) ?? false) ||
                (t.personNameHe?.toLowerCase().contains(q) ?? false) ||
                (t.unitCode?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    if (filters.onlyOverdue) {
      tasks = tasks.where((t) => t.isOverdue).toList();
    }
    if (filters.onlyRequiresAttention) {
      tasks = tasks.where((t) => t.requiresAttention).toList();
    }
    return tasks;
  }

  Future<PortalTask?> getTask(String id) async {
    final row = await portalClient
        .from('tasks')
        .select(
          '*, treatment_units(unit_code, title_he), families(display_name_he), persons(first_name_he, last_name_he)',
        )
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    return _map(Map<String, dynamic>.from(row));
  }

  Future<PortalTask> createTask({
    required String titleHe,
    required String treatmentUnitId,
    String? personId,
    String? descriptionHe,
    TaskPriority priority = TaskPriority.medium,
    String? domain,
    DateTime? dueAt,
    bool familyVisible = false,
  }) async {
    final uid = portalClient.auth.currentUser?.id;
    final inserted = await portalClient
        .from('tasks')
        .insert({
          'title_he': titleHe,
          'treatment_unit_id': treatmentUnitId,
          if (personId != null) 'person_id': personId,
          if (descriptionHe != null) 'description_he': descriptionHe,
          'priority': priority.name == 'critical'
              ? 'critical'
              : priority.name == 'high'
                  ? 'high'
                  : priority.name == 'low'
                      ? 'low'
                      : 'medium',
          if (domain != null) 'domain': domain,
          if (dueAt != null) 'due_at': dueAt.toUtc().toIso8601String(),
          'created_by': uid,
          'metadata': {'family_visible': familyVisible ? 'true' : 'false'},
        })
        .select(
          '*, treatment_units(unit_code, title_he), families(display_name_he), persons(first_name_he, last_name_he)',
        )
        .single();
    return _map(Map<String, dynamic>.from(inserted));
  }

  Future<PortalTask> updateStatus(String id, TaskStatus status) async {
    final patch = <String, dynamic>{
      'status': taskStatusToDb(status),
      if (status == TaskStatus.completed)
        'completed_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = await portalClient
        .from('tasks')
        .update(patch)
        .eq('id', id)
        .select(
          '*, treatment_units(unit_code, title_he), families(display_name_he), persons(first_name_he, last_name_he)',
        )
        .single();
    return _map(Map<String, dynamic>.from(row));
  }

  Future<List<TaskMessage>> listTaskMessages({
    required String treatmentUnitId,
    required String channel, // internal | interagency | family_portal
  }) async {
    final threads = await portalClient
        .from('communication_threads')
        .select('id')
        .eq('channel_type', channel)
        .eq('treatment_unit_id', treatmentUnitId)
        .isFilter('deleted_at', null)
        .limit(5);

    if ((threads as List).isEmpty) return [];
    final threadId = threads.first['id'] as String;
    final rows = await portalClient
        .from('communications')
        .select('id, thread_id, author_id, body_he, created_at, profiles:author_id(full_name_he)')
        .eq('thread_id', threadId)
        .isFilter('deleted_at', null)
        .order('created_at');

    return (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final profile = m['profiles'];
      return TaskMessage(
        id: m['id'] as String,
        threadId: m['thread_id'] as String,
        authorId: m['author_id'] as String,
        bodyHe: m['body_he'] as String,
        createdAt: DateTime.parse(m['created_at'] as String).toUtc(),
        authorNameHe:
            profile is Map ? profile['full_name_he'] as String? : null,
      );
    }).toList();
  }

  Future<void> postUnitMessage({
    required String treatmentUnitId,
    required String channel,
    required String bodyHe,
    String? subjectHe,
  }) async {
    final uid = portalClient.auth.currentUser?.id;
    if (uid == null) throw StateError('לא מחובר');

    var threads = await portalClient
        .from('communication_threads')
        .select('id')
        .eq('channel_type', channel)
        .eq('treatment_unit_id', treatmentUnitId)
        .isFilter('deleted_at', null)
        .limit(1);

    String threadId;
    if ((threads as List).isEmpty) {
      final created = await portalClient
          .from('communication_threads')
          .insert({
            'channel_type': channel,
            'treatment_unit_id': treatmentUnitId,
            'subject_he': subjectHe ?? 'שיחת יחידת טיפול',
            'created_by': uid,
          })
          .select('id')
          .single();
      threadId = created['id'] as String;
    } else {
      threadId = threads.first['id'] as String;
    }

    await portalClient.from('communications').insert({
      'thread_id': threadId,
      'author_id': uid,
      'body_he': bodyHe,
    });
  }
}
