enum AppRole {
  superAdmin,
  systemAdmin,
  contentEditor,
  contentApprover,
  caseManager,
  governmentRepresentative,
  departmentManager,
  executive,
  headquartersStaff,
  familyMember,
}

AppRole? appRoleFromDb(String code) {
  switch (code) {
    case 'super_admin':
      return AppRole.superAdmin;
    case 'system_admin':
      return AppRole.systemAdmin;
    case 'content_editor':
      return AppRole.contentEditor;
    case 'content_approver':
      return AppRole.contentApprover;
    case 'case_manager':
      return AppRole.caseManager;
    case 'government_representative':
      return AppRole.governmentRepresentative;
    case 'department_manager':
      return AppRole.departmentManager;
    case 'executive':
      return AppRole.executive;
    case 'headquarters_staff':
      return AppRole.headquartersStaff;
    case 'family_member':
      return AppRole.familyMember;
    default:
      return null;
  }
}

String appRoleToDb(AppRole role) {
  switch (role) {
    case AppRole.superAdmin:
      return 'super_admin';
    case AppRole.systemAdmin:
      return 'system_admin';
    case AppRole.contentEditor:
      return 'content_editor';
    case AppRole.contentApprover:
      return 'content_approver';
    case AppRole.caseManager:
      return 'case_manager';
    case AppRole.governmentRepresentative:
      return 'government_representative';
    case AppRole.departmentManager:
      return 'department_manager';
    case AppRole.executive:
      return 'executive';
    case AppRole.headquartersStaff:
      return 'headquarters_staff';
    case AppRole.familyMember:
      return 'family_member';
  }
}

String appRoleLabelHe(AppRole role) {
  switch (role) {
    case AppRole.superAdmin:
      return 'מנהל על';
    case AppRole.systemAdmin:
      return 'מנהל מערכת';
    case AppRole.contentEditor:
      return 'עורך תוכן';
    case AppRole.contentApprover:
      return 'מאשר תוכן';
    case AppRole.caseManager:
      return 'מנהל תיק';
    case AppRole.governmentRepresentative:
      return 'נציג ממשלתי';
    case AppRole.departmentManager:
      return 'מנהל מחלקה';
    case AppRole.executive:
      return 'הנהלה';
    case AppRole.headquartersStaff:
      return 'מטה';
    case AppRole.familyMember:
      return 'בן/בת משפחה';
  }
}

class PortalProfile {
  const PortalProfile({
    required this.id,
    required this.email,
    required this.fullNameHe,
    required this.roles,
    this.jobTitleHe,
  });

  final String id;
  final String email;
  final String fullNameHe;
  final List<AppRole> roles;
  final String? jobTitleHe;

  bool hasRole(AppRole role) => roles.contains(role);

  bool get isCaseManager =>
      hasRole(AppRole.caseManager) ||
      hasRole(AppRole.departmentManager) ||
      hasRole(AppRole.superAdmin) ||
      hasRole(AppRole.systemAdmin) ||
      hasRole(AppRole.headquartersStaff);

  bool get isGovRep => hasRole(AppRole.governmentRepresentative);

  bool get isFamily => hasRole(AppRole.familyMember) && !isCaseManager;

  bool get isExecutive =>
      hasRole(AppRole.executive) ||
      hasRole(AppRole.departmentManager) ||
      hasRole(AppRole.superAdmin);
}

enum TaskStatus {
  open,
  inProgress,
  waitingExternal,
  waitingFamily,
  blocked,
  completed,
  cancelled,
}

TaskStatus taskStatusFromDb(String v) {
  switch (v) {
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'waiting_external':
      return TaskStatus.waitingExternal;
    case 'waiting_family':
      return TaskStatus.waitingFamily;
    case 'blocked':
      return TaskStatus.blocked;
    case 'completed':
      return TaskStatus.completed;
    case 'cancelled':
      return TaskStatus.cancelled;
    case 'open':
    default:
      return TaskStatus.open;
  }
}

String taskStatusToDb(TaskStatus s) {
  switch (s) {
    case TaskStatus.open:
      return 'open';
    case TaskStatus.inProgress:
      return 'in_progress';
    case TaskStatus.waitingExternal:
      return 'waiting_external';
    case TaskStatus.waitingFamily:
      return 'waiting_family';
    case TaskStatus.blocked:
      return 'blocked';
    case TaskStatus.completed:
      return 'completed';
    case TaskStatus.cancelled:
      return 'cancelled';
  }
}

String taskStatusLabelHe(TaskStatus s) {
  switch (s) {
    case TaskStatus.open:
      return 'פתוחה';
    case TaskStatus.inProgress:
      return 'בטיפול';
    case TaskStatus.waitingExternal:
      return 'ממתינה לגורם חיצוני';
    case TaskStatus.waitingFamily:
      return 'ממתינה למשפחה';
    case TaskStatus.blocked:
      return 'חסומה';
    case TaskStatus.completed:
      return 'הושלמה';
    case TaskStatus.cancelled:
      return 'בוטלה';
  }
}

enum TaskPriority { low, medium, high, critical }

TaskPriority taskPriorityFromDb(String v) {
  switch (v) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    case 'critical':
      return TaskPriority.critical;
    case 'medium':
    default:
      return TaskPriority.medium;
  }
}

String taskPriorityLabelHe(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return 'נמוכה';
    case TaskPriority.medium:
      return 'בינונית';
    case TaskPriority.high:
      return 'גבוהה';
    case TaskPriority.critical:
      return 'קריטית';
  }
}

class PortalTask {
  const PortalTask({
    required this.id,
    required this.titleHe,
    required this.status,
    required this.priority,
    required this.treatmentUnitId,
    required this.familyId,
    required this.updatedAt,
    this.personId,
    this.dueAt,
    this.domain,
    this.descriptionHe,
    this.familyVisible = false,
    this.unitCode,
    this.familyNameHe,
    this.personNameHe,
  });

  final String id;
  final String titleHe;
  final TaskStatus status;
  final TaskPriority priority;
  final String treatmentUnitId;
  final String familyId;
  final String? personId;
  final DateTime? dueAt;
  final DateTime updatedAt;
  final String? domain;
  final String? descriptionHe;
  final bool familyVisible;
  final String? unitCode;
  final String? familyNameHe;
  final String? personNameHe;

  bool get isOpen =>
      status != TaskStatus.completed && status != TaskStatus.cancelled;

  bool get isOverdue =>
      isOpen && dueAt != null && dueAt!.isBefore(DateTime.now().toUtc());

  bool get requiresAttention =>
      isOverdue ||
      priority == TaskPriority.critical ||
      status == TaskStatus.blocked;
}

class TreatmentUnitSummary {
  const TreatmentUnitSummary({
    required this.id,
    required this.unitCode,
    required this.titleHe,
    required this.familyId,
    required this.familyNameHe,
    required this.status,
    this.primaryCaseManagerId,
    this.personCount = 0,
    this.openTaskCount = 0,
  });

  final String id;
  final String unitCode;
  final String titleHe;
  final String familyId;
  final String familyNameHe;
  final String status;
  final String? primaryCaseManagerId;
  final int personCount;
  final int openTaskCount;
}

class FamilySummary {
  const FamilySummary({
    required this.id,
    required this.familyCode,
    required this.displayNameHe,
    this.localityHe,
    this.scenarioTag,
  });

  final String id;
  final String familyCode;
  final String displayNameHe;
  final String? localityHe;
  final String? scenarioTag;
}

class PersonSummary {
  const PersonSummary({
    required this.id,
    required this.firstNameHe,
    required this.lastNameHe,
    required this.treatmentUnitId,
    required this.familyId,
    required this.status,
    this.dateOfBirth,
    this.phone,
    this.isIndexCase = false,
  });

  final String id;
  final String firstNameHe;
  final String lastNameHe;
  final String treatmentUnitId;
  final String familyId;
  final String status;
  final DateTime? dateOfBirth;
  final String? phone;
  final bool isIndexCase;

  String get fullNameHe => '$firstNameHe $lastNameHe';

  int? get ageYears {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}

class PortalNotification {
  const PortalNotification({
    required this.id,
    required this.titleHe,
    required this.createdAt,
    this.bodyHe,
    this.linkPath,
    this.readAt,
  });

  final String id;
  final String titleHe;
  final String? bodyHe;
  final String? linkPath;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.titleHe,
    required this.status,
    this.summaryHe,
    this.publishedAt,
  });

  final String id;
  final String titleHe;
  final String status;
  final String? summaryHe;
  final DateTime? publishedAt;
}

class TaskMessage {
  const TaskMessage({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.bodyHe,
    required this.createdAt,
    this.authorNameHe,
  });

  final String id;
  final String threadId;
  final String authorId;
  final String bodyHe;
  final DateTime createdAt;
  final String? authorNameHe;
}
