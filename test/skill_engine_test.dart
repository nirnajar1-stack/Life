import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/personal_dev/domain/config/pd_skill_registry.dart';
import 'package:life_app/features/personal_dev/domain/engine/skill_engine.dart';

PdEventSnapshot _event({
  required String stageId,
  List<String> behaviors = const [],
  int? score,
  DateTime? at,
}) {
  return PdEventSnapshot(
    skillId: selfRegulationSkill.id,
    stageAtEvent: stageId,
    microBehaviors: behaviors,
    performanceScore: score,
    occurredAt: at ?? DateTime(2026, 8, 29),
  );
}

void main() {
  test('self regulation registry has five stages', () {
    expect(selfRegulationSkill.stages.length, 5);
    expect(pdSkillRegistry.containsKey('self_regulation'), isTrue);
  });

  test('computePerformanceScore scales with behavior coverage', () {
    final stageBehaviors = selfRegulationSkill.microBehaviors
        .where((b) => b.stageId == 'awareness')
        .map((b) => b.id)
        .toList();

    expect(
      computePerformanceScore(
        skill: selfRegulationSkill,
        stageId: 'awareness',
        checkedBehaviorIds: stageBehaviors,
      ),
      greaterThanOrEqualTo(4),
    );

    expect(
      computePerformanceScore(
        skill: selfRegulationSkill,
        stageId: 'awareness',
        checkedBehaviorIds: const [],
      ),
      1,
    );
  });

  test('evaluateStageProgress requires min events and scores', () {
    final eval = evaluateStageProgress(
      skill: selfRegulationSkill,
      currentStageId: 'awareness',
      events: [
        _event(stageId: 'awareness', behaviors: ['noticed_activation'], score: 3),
        _event(stageId: 'awareness', behaviors: ['noticed_body_signal'], score: 3),
      ],
    );

    expect(eval.eventsInStage, 2);
    expect(eval.readyToAdvance, isFalse);

    final ready = evaluateStageProgress(
      skill: selfRegulationSkill,
      currentStageId: 'awareness',
      events: [
        _event(stageId: 'awareness', behaviors: ['noticed_activation'], score: 3),
        _event(stageId: 'awareness', behaviors: ['noticed_body_signal'], score: 3),
        _event(
          stageId: 'awareness',
          behaviors: ['noticed_activation', 'noticed_body_signal'],
          score: 4,
        ),
      ],
    );

    expect(ready.eventsInStage, 3);
    expect(ready.nextStageId, 'pause');
  });

  test('next stage is null at integrated mastery', () {
    expect(
      selfRegulationSkill.nextStageAfter('integrated_mastery'),
      isNull,
    );
  });
}
