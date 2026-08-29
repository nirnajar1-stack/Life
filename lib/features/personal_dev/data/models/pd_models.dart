import '../../domain/models/pd_enums.dart';

class PdFocusCycle {
  const PdFocusCycle({
    required this.id,
    required this.primarySkillId,
    this.secondarySkillId,
    this.traitFocus,
    required this.cycleStart,
    this.cycleEnd,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String primarySkillId;
  final String? secondarySkillId;
  final String? traitFocus;
  final DateTime cycleStart;
  final DateTime? cycleEnd;
  final String? notes;
  final DateTime createdAt;

  factory PdFocusCycle.fromJson(Map<String, dynamic> json) {
    return PdFocusCycle(
      id: json['id'] as String,
      primarySkillId: json['primary_skill_id'] as String,
      secondarySkillId: json['secondary_skill_id'] as String?,
      traitFocus: json['trait_focus'] as String?,
      cycleStart: DateTime.parse(json['cycle_start'] as String),
      cycleEnd: json['cycle_end'] != null
          ? DateTime.parse(json['cycle_end'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_skill_id': primarySkillId,
      if (secondarySkillId != null) 'secondary_skill_id': secondarySkillId,
      if (traitFocus != null) 'trait_focus': traitFocus,
      'cycle_start': cycleStart.toIso8601String().split('T').first,
      if (cycleEnd != null)
        'cycle_end': cycleEnd!.toIso8601String().split('T').first,
      if (notes != null) 'notes': notes,
    };
  }
}

class PdSkillProgress {
  const PdSkillProgress({
    required this.skillId,
    required this.currentStageId,
    required this.eventsInStage,
    required this.updatedAt,
  });

  final String skillId;
  final String currentStageId;
  final int eventsInStage;
  final DateTime updatedAt;

  factory PdSkillProgress.fromJson(Map<String, dynamic> json) {
    return PdSkillProgress(
      skillId: json['skill_id'] as String,
      currentStageId: json['current_stage_id'] as String,
      eventsInStage: json['events_in_stage'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill_id': skillId,
      'current_stage_id': currentStageId,
      'events_in_stage': eventsInStage,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PdSkillProgress copyWith({
    String? currentStageId,
    int? eventsInStage,
    DateTime? updatedAt,
  }) {
    return PdSkillProgress(
      skillId: skillId,
      currentStageId: currentStageId ?? this.currentStageId,
      eventsInStage: eventsInStage ?? this.eventsInStage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PdEvent {
  const PdEvent({
    required this.id,
    required this.skillId,
    required this.eventType,
    required this.occurredAt,
    this.relationshipType,
    this.powerGap,
    this.relationshipSafety,
    this.outcomeImportance,
    this.difficulty,
    this.emotionalActivation,
    this.situationId,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String skillId;
  final PdEventType eventType;
  final DateTime occurredAt;
  final String? relationshipType;
  final PdContextLevel? powerGap;
  final PdSafetyLevel? relationshipSafety;
  final PdContextLevel? outcomeImportance;
  final PdContextLevel? difficulty;
  final PdContextLevel? emotionalActivation;
  final String? situationId;
  final String? notes;
  final DateTime createdAt;

  factory PdEvent.fromJson(Map<String, dynamic> json) {
    return PdEvent(
      id: json['id'] as String,
      skillId: json['skill_id'] as String,
      eventType: PdEventType.fromDb(json['event_type'] as String?),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      relationshipType: json['relationship_type'] as String?,
      powerGap: PdContextLevel.fromDb(json['power_gap'] as String?),
      relationshipSafety:
          PdSafetyLevel.fromDb(json['relationship_safety'] as String?),
      outcomeImportance:
          PdContextLevel.fromDb(json['outcome_importance'] as String?),
      difficulty: PdContextLevel.fromDb(json['difficulty'] as String?),
      emotionalActivation:
          PdContextLevel.fromDb(json['emotional_activation'] as String?),
      situationId: json['situation_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill_id': skillId,
      'event_type': eventType.dbValue,
      'occurred_at': occurredAt.toIso8601String(),
      if (relationshipType != null) 'relationship_type': relationshipType,
      if (powerGap != null) 'power_gap': powerGap!.dbValue,
      if (relationshipSafety != null)
        'relationship_safety': relationshipSafety!.dbValue,
      if (outcomeImportance != null)
        'outcome_importance': outcomeImportance!.dbValue,
      if (difficulty != null) 'difficulty': difficulty!.dbValue,
      if (emotionalActivation != null)
        'emotional_activation': emotionalActivation!.dbValue,
      if (situationId != null) 'situation_id': situationId,
      if (notes != null) 'notes': notes,
    };
  }
}

class PdEventSkill {
  const PdEventSkill({
    required this.id,
    required this.eventId,
    required this.skillId,
    required this.microBehaviors,
    this.performanceScore,
    this.stageAtEvent,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String skillId;
  final List<String> microBehaviors;
  final int? performanceScore;
  final String? stageAtEvent;
  final DateTime createdAt;

  factory PdEventSkill.fromJson(Map<String, dynamic> json) {
    final rawBehaviors = json['micro_behaviors'];
    final behaviors = rawBehaviors is List
        ? rawBehaviors.map((e) => e.toString()).toList()
        : <String>[];

    return PdEventSkill(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      skillId: json['skill_id'] as String,
      microBehaviors: behaviors,
      performanceScore: json['performance_score'] as int?,
      stageAtEvent: json['stage_at_event'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'skill_id': skillId,
      'micro_behaviors': microBehaviors,
      if (performanceScore != null) 'performance_score': performanceScore,
      if (stageAtEvent != null) 'stage_at_event': stageAtEvent,
    };
  }
}

class PdEventRecord {
  const PdEventRecord({
    required this.event,
    required this.eventSkill,
  });

  final PdEvent event;
  final PdEventSkill eventSkill;
}
