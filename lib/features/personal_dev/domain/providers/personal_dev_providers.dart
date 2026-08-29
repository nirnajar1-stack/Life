import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/pd_models.dart';
import '../../data/repositories/personal_dev_repository.dart';
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

final pdRelationshipAnalyticsProvider =
    FutureProvider.family<PdContextAnalytics, String>((ref, skillId) async {
  final events =
      await ref.watch(personalDevRepositoryProvider).fetchEventsForSkill(skillId);
  final snapshots = events
      .map(
        (r) => PdContextEventSnapshot(
          relationshipType: r.event.relationshipType,
          powerGap: r.event.powerGap?.dbValue,
          performanceScore: r.eventSkill.performanceScore,
        ),
      )
      .toList();
  return computeRelationshipTypeAnalytics(snapshots);
});

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
    String? notes,
    String? situationId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.logEvent(
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
        notes: notes,
        situationId: situationId,
      );
      await _repo.incrementEventsInStage(skillId);
      ref.invalidate(pdEventsForSkillProvider(skillId));
      ref.invalidate(pdSkillProgressProvider(skillId));
      ref.invalidate(pdStageEvaluationProvider(skillId));
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
