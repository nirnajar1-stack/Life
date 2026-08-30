import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/pd_models.dart';
import '../../data/repositories/personal_dev_repository.dart';
import '../../domain/character/config/pd_skill_character_mapping.dart';
import '../../domain/character/providers/character_providers.dart';
import '../../domain/config/pd_skill_config.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/engine/skill_engine.dart';
import '../../domain/models/pd_enums.dart';

final personalDevRepositoryProvider = Provider<PersonalDevRepository>((ref) {
  return PersonalDevRepository(ref.watch(supabaseClientProvider));
});

final pdFocusCycleProvider = FutureProvider<PdFocusCycle?>((ref) async {
  return ref.watch(personalDevRepositoryProvider).fetchCurrentFocusCycle();
});

final pdSkillProgressProvider =
    FutureProvider.family<PdSkillProgress?, String>((ref, skillId) async {
  return ref.watch(personalDevRepositoryProvider).fetchSkillProgress(skillId);
});

final pdEventsForSkillProvider =
    FutureProvider.family<List<PdEventRecord>, String>((ref, skillId) async {
  return ref.watch(personalDevRepositoryProvider).fetchEventsForSkill(skillId);
});

final pdStageEvaluationProvider =
    FutureProvider.family<PdStageEvaluation?, String>((ref, skillId) async {
  final skill = pdSkillRegistry[skillId];
  if (skill == null) return null;

  final progress =
      await ref.watch(personalDevRepositoryProvider).fetchSkillProgress(skillId);
  final events =
      await ref.watch(personalDevRepositoryProvider).fetchEventsForSkill(skillId);

  final snapshots = events
      .map(
        (r) => PdEventSnapshot(
          skillId: skillId,
          stageAtEvent: r.eventSkill.stageAtEvent,
          microBehaviors: r.eventSkill.microBehaviors,
          performanceScore: r.eventSkill.performanceScore,
          occurredAt: r.event.occurredAt,
        ),
      )
      .toList();

  return evaluateStageProgress(
    skill: skill,
    currentStageId: progress?.currentStageId ?? skill.firstStage.id,
    events: snapshots,
  );
});

final pdContextAnalyticsProvider =
    FutureProvider.family<PdContextAnalytics, String>((ref, key) async {
  final separator = key.indexOf('|');
  final skillId = key.substring(0, separator);
  final dimensionKey = key.substring(separator + 1);
  final dimension = PdContextDimension.values.firstWhere(
    (d) => d.key == dimensionKey,
  );

  final events =
      await ref.watch(personalDevRepositoryProvider).fetchEventsForSkill(skillId);
  final snapshots = events
      .map(
        (r) => PdContextEventSnapshot(
          relationshipType: r.event.relationshipType,
          powerGap: r.event.powerGap?.dbValue,
          outcomeImportance: r.event.outcomeImportance?.dbValue,
          difficulty: r.event.difficulty?.dbValue,
          emotionalActivation: r.event.emotionalActivation?.dbValue,
          communicationChannel: r.event.communicationChannel?.dbValue,
          performanceScore: r.eventSkill.performanceScore,
        ),
      )
      .toList();
  return computeContextAnalytics(snapshots, dimension);
});

String pdContextAnalyticsKey(String skillId, PdContextDimension dimension) =>
    '$skillId|${dimension.key}';

class PersonalDevController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  PersonalDevRepository get _repo => ref.read(personalDevRepositoryProvider);

  Future<void> logEvent({
    required String skillId,
    required PdEventType eventType,
    required List<String> microBehaviors,
    required String stageAtEvent,
    int? performanceScore,
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final record = await _repo.logEvent(
        skillId: skillId,
        eventType: eventType,
        microBehaviors: microBehaviors,
        stageAtEvent: stageAtEvent,
        performanceScore: performanceScore,
        relationshipType: relationshipType,
        powerGap: powerGap,
        relationshipSafety: relationshipSafety,
        outcomeImportance: outcomeImportance,
        difficulty: difficulty,
        emotionalActivation: emotionalActivation,
        communicationChannel: communicationChannel,
        notes: notes,
        situationId: situationId,
      );
      await _repo.incrementEventsInStage(skillId);

      final eventContext = <String, dynamic>{
        if (relationshipType != null) 'relationship_type': relationshipType,
        if (powerGap != null) 'power_gap': powerGap.dbValue,
        if (difficulty != null) 'difficulty': difficulty.dbValue,
        if (emotionalActivation != null)
          'emotional_activation': emotionalActivation.dbValue,
        if (communicationChannel != null)
          'communication_channel': communicationChannel.dbValue,
      };

      await ref.read(characterRepositoryProvider).syncEvidenceFromEvent(
            eventId: record.event.id,
            skillId: skillId,
            microBehaviors: microBehaviors,
            context: eventContext.isEmpty ? null : eventContext,
            occurredAt: record.event.occurredAt,
          );

      final mappedTraits = mappingsForEvent(
        skillId: skillId,
        checkedBehaviorIds: microBehaviors,
      )
          .map((m) => m.traitId)
          .toSet();

      ref.invalidate(pdEventsForSkillProvider(skillId));
      ref.invalidate(pdSkillProgressProvider(skillId));
      ref.invalidate(pdStageEvaluationProvider(skillId));
      final skill = pdSkillRegistry[skillId];
      if (skill != null) {
        for (final dimension in skill.contextDimensions) {
          ref.invalidate(
            pdContextAnalyticsProvider(pdContextAnalyticsKey(skillId, dimension)),
          );
        }
      }
      for (final traitId in mappedTraits) {
        ref.invalidate(pdCharacterEvidenceProvider(traitId));
        ref.invalidate(pdCharacterTraitSummaryProvider(traitId));
        ref.invalidate(pdCharacterWeeklyReviewProvider(traitId));
      }
    });
  }

  Future<void> tryAdvanceStage(String skillId) async {
    final skill = pdSkillRegistry[skillId];
    if (skill == null) return;

    final evaluation = await ref.read(pdStageEvaluationProvider(skillId).future);
    if (evaluation == null || !evaluation.readyToAdvance) return;
    if (evaluation.nextStageId == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.advanceSkillStage(
        skillId: skillId,
        nextStageId: evaluation.nextStageId!,
      );
      ref.invalidate(pdSkillProgressProvider(skillId));
      ref.invalidate(pdStageEvaluationProvider(skillId));
    });
  }
}

final personalDevControllerProvider =
    AsyncNotifierProvider<PersonalDevController, void>(
  PersonalDevController.new,
);
