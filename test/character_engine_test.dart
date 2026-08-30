import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/personal_dev/domain/character/config/pd_character_registry.dart';
import 'package:life_app/features/personal_dev/domain/character/config/pd_skill_character_mapping.dart';
import 'package:life_app/features/personal_dev/domain/character/engine/character_engine.dart';
import 'package:life_app/features/personal_dev/domain/character/models/character_enums.dart';

PdCharacterEvidenceSnapshot _evidence({
  required String traitId,
  required String indicatorId,
  required bool demonstrated,
  bool opportunity = true,
  DateTime? at,
  Map<String, dynamic>? context,
}) {
  return PdCharacterEvidenceSnapshot(
    traitId: traitId,
    indicatorId: indicatorId,
    occurredAt: at ?? DateTime(2026, 8, 29),
    opportunityDetected: opportunity,
    demonstrated: demonstrated,
    context: context,
  );
}

void main() {
  test('trait registration includes five active traits', () {
    expect(allPdCharacterTraits.length, 5);
    expect(pdCharacterRegistry.containsKey('curiosity'), isTrue);
    expect(pdCharacterRegistry.containsKey('integrity'), isTrue);
  });

  test('consistency calculation uses opportunities as denominator', () {
    expect(
      computeCharacterConsistencyPercent(opportunities: 14, demonstrations: 9),
      64,
    );
    expect(
      computeCharacterConsistencyPercent(opportunities: 0, demonstrations: 0),
      0,
    );
  });

  test('missed opportunity lowers consistency', () {
    final summary = summarizeCharacterTrait(
      traitId: 'curiosity',
      evidence: [
        _evidence(
          traitId: 'curiosity',
          indicatorId: 'asked_before_advising',
          demonstrated: true,
        ),
        _evidence(
          traitId: 'curiosity',
          indicatorId: 'asked_before_advising',
          demonstrated: false,
        ),
      ],
    );
    expect(summary.opportunities, 2);
    expect(summary.demonstrations, 1);
    expect(summary.consistencyPercent, 50);
  });

  test('evidence level derives from behavior not questionnaire', () {
    expect(
      computeEvidenceLevel(
        opportunities: 14,
        demonstrations: 9,
        consistencyPercent: 64,
      ),
      PdEvidenceLevel.consistent,
    );
    expect(
      computeEvidenceLevel(
        opportunities: 1,
        demonstrations: 0,
        consistencyPercent: 0,
      ),
      PdEvidenceLevel.emerging,
    );
  });

  test('skill behavior mapping is config-driven', () {
    final mappings = mappingsForEvent(
      skillId: 'assertiveness',
      checkedBehaviorIds: const ['maintained_position_after_pushback'],
    );
    expect(mappings.length, 1);
    expect(mappings.first.traitId, 'integrity');
    expect(mappings.first.indicatorId, 'kept_or_updated_commitment');
  });

  test('weekly aggregation summarizes focus trait week', () {
    final now = DateTime(2026, 8, 29);
    final review = buildWeeklyCharacterReview(
      traitId: 'curiosity',
      now: now,
      indicatorIds: curiosityTrait.indicators.map((i) => i.indicatorId).toList(),
      evidence: [
        _evidence(
          traitId: 'curiosity',
          indicatorId: 'asked_before_advising',
          demonstrated: true,
          at: DateTime(2026, 8, 28),
        ),
        _evidence(
          traitId: 'curiosity',
          indicatorId: 'tested_assumption',
          demonstrated: false,
          at: DateTime(2026, 8, 27),
        ),
      ],
    );
    expect(review.opportunities, 2);
    expect(review.demonstrations, 1);
    expect(review.consistencyPercent, 50);
    expect(review.strongestIndicatorId, 'asked_before_advising');
  });

  test('context analytics reports consistency not personality score', () {
    final analytics = computeCharacterContextAnalytics(
      evidence: [
        _evidence(
          traitId: 'curiosity',
          indicatorId: 'asked_before_advising',
          demonstrated: true,
          context: const {'relationship_type': 'Work'},
        ),
        _evidence(
          traitId: 'curiosity',
          indicatorId: 'asked_before_advising',
          demonstrated: true,
          context: const {'relationship_type': 'Work'},
        ),
        _evidence(
          traitId: 'curiosity',
          indicatorId: 'asked_before_advising',
          demonstrated: false,
          context: const {'relationship_type': 'Senior Leaders'},
        ),
      ],
      contextKey: 'relationship_type',
    );
    expect(analytics.overallConsistencyPercent, 67);
    expect(analytics.groups.length, 2);
  });
}
