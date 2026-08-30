import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/config/pd_skill_registry.dart';
import '../../domain/engine/skill_engine.dart';
import '../../domain/models/pd_enums.dart';
import '../models/pd_models.dart';

class PersonalDevRepository {
  PersonalDevRepository(this._client);

  final SupabaseClient _client;

  Future<PdFocusCycle?> fetchCurrentFocusCycle() async {
    final rows = await _client
        .from('pd_focus_cycles')
        .select()
        .isFilter('cycle_end', null)
        .order('cycle_start', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return PdFocusCycle.fromJson(Map<String, dynamic>.from(list.first as Map));
  }

  Future<PdSkillProgress?> fetchSkillProgress(String skillId) async {
    final row = await _client
        .from('pd_skill_progress')
        .select()
        .eq('skill_id', skillId)
        .maybeSingle();
    if (row == null) return null;
    return PdSkillProgress.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<PdSkillProgress>> fetchAllSkillProgress() async {
    final rows = await _client.from('pd_skill_progress').select();
    return (rows as List)
        .map((row) =>
            PdSkillProgress.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<PdSkillProgress> upsertSkillProgress(PdSkillProgress progress) async {
    final row = await _client
        .from('pd_skill_progress')
        .upsert(progress.toJson(), onConflict: 'skill_id')
        .select()
        .single();
    return PdSkillProgress.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<PdEventRecord>> fetchEventsForSkill(String skillId) async {
    final eventRows = await _client
        .from('pd_events')
        .select()
        .eq('skill_id', skillId)
        .order('occurred_at', ascending: false);
    final events = (eventRows as List)
        .map((row) => PdEvent.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    if (events.isEmpty) return const [];

    final ids = events.map((e) => e.id).toList();
    final skillRows = await _client
        .from('pd_event_skills')
        .select()
        .inFilter('event_id', ids);
    final skills = (skillRows as List)
        .map((row) =>
            PdEventSkill.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();

    return [
      for (final event in events)
        if (skills.any((s) => s.eventId == event.id))
          PdEventRecord(
            event: event,
            eventSkill: skills.firstWhere((s) => s.eventId == event.id),
          ),
    ];
  }

  Future<PdEventRecord> logEvent({
    required String skillId,
    required PdEventType eventType,
    required List<String> microBehaviors,
    required String stageAtEvent,
    int? performanceScore,
    DateTime? occurredAt,
    String? relationshipType,
    PdContextLevel? powerGap,
    PdSafetyLevel? relationshipSafety,
    PdContextLevel? outcomeImportance,
    PdContextLevel? difficulty,
    PdContextLevel? emotionalActivation,
    PdCommunicationChannel? communicationChannel,
    String? notes,
    String? situationId,
  }) async {
    final when = occurredAt ?? DateTime.now();
    final skill = pdSkillRegistry[skillId];
    final score = performanceScore ??
        (skill == null
            ? 3
            : computePerformanceScore(
                skill: skill,
                stageId: stageAtEvent,
                checkedBehaviorIds: microBehaviors,
              ));

    final eventRow = await _client
        .from('pd_events')
        .insert({
          'skill_id': skillId,
          'event_type': eventType.dbValue,
          'occurred_at': when.toIso8601String(),
          if (relationshipType != null) 'relationship_type': relationshipType,
          if (powerGap != null) 'power_gap': powerGap.dbValue,
          if (relationshipSafety != null)
            'relationship_safety': relationshipSafety.dbValue,
          if (outcomeImportance != null)
            'outcome_importance': outcomeImportance.dbValue,
          if (difficulty != null) 'difficulty': difficulty.dbValue,
          if (emotionalActivation != null)
            'emotional_activation': emotionalActivation.dbValue,
          if (communicationChannel != null)
            'communication_channel': communicationChannel.dbValue,
          if (situationId != null) 'situation_id': situationId,
          if (notes != null) 'notes': notes,
        })
        .select()
        .single();

    final event = PdEvent.fromJson(Map<String, dynamic>.from(eventRow));

    final skillRow = await _client
        .from('pd_event_skills')
        .insert({
          'event_id': event.id,
          'skill_id': skillId,
          'micro_behaviors': microBehaviors,
          'performance_score': score,
          'stage_at_event': stageAtEvent,
        })
        .select()
        .single();

    return PdEventRecord(
      event: event,
      eventSkill: PdEventSkill.fromJson(Map<String, dynamic>.from(skillRow)),
    );
  }

  Future<void> advanceSkillStage({
    required String skillId,
    required String nextStageId,
  }) async {
    await _client.from('pd_skill_progress').upsert({
      'skill_id': skillId,
      'current_stage_id': nextStageId,
      'events_in_stage': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'skill_id');
  }

  Future<void> incrementEventsInStage(String skillId) async {
    final current = await fetchSkillProgress(skillId);
    if (current == null) return;
    await upsertSkillProgress(
      current.copyWith(
        eventsInStage: current.eventsInStage + 1,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
