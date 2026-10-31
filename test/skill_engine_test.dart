import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/personal_dev/domain/config/pd_skill_config.dart';
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

  group('assertiveness (config-only skill)', () {
    test('registry includes assertiveness with five stages', () {
      expect(pdSkillRegistry.containsKey('assertiveness'), isTrue);
      expect(assertivenessSkill.stages.length, 5);
      expect(assertivenessSkill.drills.length, greaterThanOrEqualTo(2));
      expect(assertivenessSkill.realWorldMissions.length, 5);
    });

    test('uses same scoring engine with different stage ids', () {
      expect(
        computePerformanceScore(
          skill: assertivenessSkill,
          stageId: 'low_stakes_practice',
          checkedBehaviorIds: const [
            'made_clear_request',
            'avoided_unnecessary_apology',
          ],
        ),
        greaterThanOrEqualTo(4),
      );
    });

    test('stage evaluation advances to low stakes practice', () {
      final eval = evaluateStageProgress(
        skill: assertivenessSkill,
        currentStageId: 'awareness',
        events: [
          PdEventSnapshot(
            skillId: assertivenessSkill.id,
            stageAtEvent: 'awareness',
            microBehaviors: const ['expressed_actual_opinion'],
            performanceScore: 4,
            occurredAt: DateTime(2026, 8, 29),
          ),
          PdEventSnapshot(
            skillId: assertivenessSkill.id,
            stageAtEvent: 'awareness',
            microBehaviors: const ['expressed_actual_opinion'],
            performanceScore: 4,
            occurredAt: DateTime(2026, 8, 30),
          ),
          PdEventSnapshot(
            skillId: assertivenessSkill.id,
            stageAtEvent: 'awareness',
            microBehaviors: const ['expressed_actual_opinion'],
            performanceScore: 4,
            occurredAt: DateTime(2026, 8, 31),
          ),
        ],
      );

      expect(eval.nextStageId, 'low_stakes_practice');
    });

    test('relationship analytics groups scores by context', () {
      final analytics = computeRelationshipTypeAnalytics(const [
        PdContextEventSnapshot(
          relationshipType: 'עמיתים',
          performanceScore: 5,
        ),
        PdContextEventSnapshot(
          relationshipType: 'עמיתים',
          performanceScore: 4,
        ),
        PdContextEventSnapshot(
          relationshipType: 'מנהל בכיר',
          performanceScore: 2,
        ),
      ]);

      expect(analytics.overallPercent, 73);
      expect(analytics.groups.length, 2);
      expect(analytics.groups.first.label, 'עמיתים');
      expect(analytics.groups.first.avgScorePercent, 90);
    });
  });

  group('clear communication (config-only skill 3)', () {
    test('registry includes skill with drills and communication channel', () {
      expect(pdSkillRegistry.containsKey('clear_communication'), isTrue);
      expect(clearCommunicationSkill.drills.length, 2);
      expect(
        clearCommunicationSkill.contextDimensions,
        contains(PdContextDimension.communicationChannel),
      );
      expect(clearCommunicationSkill.microBehaviors.length, 5);
    });

    test('scoring works with different micro-behaviors', () {
      expect(
        computePerformanceScore(
          skill: clearCommunicationSkill,
          stageId: 'low_stakes_practice',
          checkedBehaviorIds: const ['explained_reasoning'],
        ),
        greaterThanOrEqualTo(2),
      );
    });

    test('communication channel analytics are generic', () {
      final analytics = computeContextAnalytics(const [
        PdContextEventSnapshot(
          communicationChannel: 'meeting',
          performanceScore: 5,
        ),
        PdContextEventSnapshot(
          communicationChannel: 'chat',
          performanceScore: 4,
        ),
        PdContextEventSnapshot(
          communicationChannel: 'chat',
          performanceScore: 5,
        ),
      ], PdContextDimension.communicationChannel);

      expect(analytics.overallPercent, 93);
      expect(analytics.groups.length, 2);
      expect(
        analytics.groups.map((g) => g.label),
        containsAll(['פגישה', 'צ\'אט']),
      );
    });

    test('self regulation does not require communication channel', () {
      expect(
        selfRegulationSkill.contextDimensions,
        isNot(contains(PdContextDimension.communicationChannel)),
      );
    });
  });
}
