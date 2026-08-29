import '../config/pd_skill_config.dart';

/// Snapshot of one logged event for stage evaluation.
class PdEventSnapshot {
  const PdEventSnapshot({
    required this.skillId,
    required this.stageAtEvent,
    required this.microBehaviors,
    this.performanceScore,
    required this.occurredAt,
  });

  final String skillId;
  final String? stageAtEvent;
  final List<String> microBehaviors;
  final int? performanceScore;
  final DateTime occurredAt;
}

class PdStageEvaluation {
  const PdStageEvaluation({
    required this.stageId,
    required this.eventsInStage,
    required this.avgScore,
    required this.behaviorRate,
    required this.readyToAdvance,
    this.nextStageId,
  });

  final String stageId;
  final int eventsInStage;
  final double avgScore;
  final double behaviorRate;
  final bool readyToAdvance;
  final String? nextStageId;
}

/// Evaluates whether the learner is ready to advance within a skill.
PdStageEvaluation evaluateStageProgress({
  required PdSkillConfig skill,
  required String currentStageId,
  required List<PdEventSnapshot> events,
}) {
  final stage = skill.stageById(currentStageId) ?? skill.firstStage;
  final stageBehaviors =
      skill.microBehaviors.where((b) => b.stageId == stage.id).toList();
  final stageBehaviorIds = stageBehaviors.map((b) => b.id).toSet();

  final stageEvents = events
      .where((e) => e.skillId == skill.id && e.stageAtEvent == stage.id)
      .toList();

  final scored = stageEvents.where((e) => e.performanceScore != null).toList();
  final avgScore = scored.isEmpty
      ? 0.0
      : scored.map((e) => e.performanceScore!).reduce((a, b) => a + b) /
          scored.length;

  var behaviorHits = 0;
  var behaviorSlots = 0;
  for (final event in stageEvents) {
    behaviorSlots += stageBehaviorIds.length;
    behaviorHits +=
        event.microBehaviors.where(stageBehaviorIds.contains).length;
  }
  final behaviorRate =
      behaviorSlots == 0 ? 0.0 : behaviorHits / behaviorSlots;

  final ready = stageEvents.length >= stage.minEvents &&
      avgScore >= stage.minAvgScore &&
      behaviorRate >= stage.minBehaviorRate;

  final next = skill.nextStageAfter(stage.id);

  return PdStageEvaluation(
    stageId: stage.id,
    eventsInStage: stageEvents.length,
    avgScore: avgScore,
    behaviorRate: behaviorRate,
    readyToAdvance: ready && next != null,
    nextStageId: next?.id,
  );
}

/// Computes performance score from checked micro-behaviors (1–5 scale).
int computePerformanceScore({
  required PdSkillConfig skill,
  required String stageId,
  required List<String> checkedBehaviorIds,
}) {
  final stageBehaviors = skill.microBehaviors
      .where((b) => b.stageId == stageId)
      .map((b) => b.id)
      .toList();
  if (stageBehaviors.isEmpty) {
    return checkedBehaviorIds.isEmpty ? 1 : 3;
  }
  final hits =
      checkedBehaviorIds.where(stageBehaviors.contains).length;
  final rate = hits / stageBehaviors.length;
  if (rate >= 0.85) return 5;
  if (rate >= 0.65) return 4;
  if (rate >= 0.45) return 3;
  if (rate >= 0.25) return 2;
  return 1;
}

/// Rich event snapshot for generic context analytics (not stage evaluation).
class PdContextEventSnapshot {
  const PdContextEventSnapshot({
    this.relationshipType,
    this.powerGap,
    this.performanceScore,
  });

  final String? relationshipType;
  final String? powerGap;
  final int? performanceScore;
}

class PdContextScoreGroup {
  const PdContextScoreGroup({
    required this.label,
    required this.eventCount,
    required this.avgScorePercent,
  });

  final String label;
  final int eventCount;
  final int avgScorePercent;
}

/// Groups scored events by relationship type for breakdown views (e.g. Peers vs Senior Leaders).
PdContextAnalytics computeRelationshipTypeAnalytics(
  List<PdContextEventSnapshot> events,
) {
  final scored =
      events.where((e) => e.performanceScore != null).toList();
  if (scored.isEmpty) {
    return const PdContextAnalytics(overallPercent: 0, groups: []);
  }

  final overall = _avgScorePercent(scored.map((e) => e.performanceScore!).toList());
  final buckets = <String, List<int>>{};
  for (final event in scored) {
    final key = (event.relationshipType?.trim().isEmpty ?? true)
        ? 'לא צוין'
        : event.relationshipType!.trim();
    buckets.putIfAbsent(key, () => []).add(event.performanceScore!);
  }

  final groups = buckets.entries
      .map(
        (entry) => PdContextScoreGroup(
          label: entry.key,
          eventCount: entry.value.length,
          avgScorePercent: _avgScorePercent(entry.value),
        ),
      )
      .toList()
    ..sort((a, b) => b.avgScorePercent.compareTo(a.avgScorePercent));

  return PdContextAnalytics(overallPercent: overall, groups: groups);
}

class PdContextAnalytics {
  const PdContextAnalytics({
    required this.overallPercent,
    required this.groups,
  });

  final int overallPercent;
  final List<PdContextScoreGroup> groups;
}

int _avgScorePercent(List<int> scores) {
  if (scores.isEmpty) return 0;
  final avg = scores.reduce((a, b) => a + b) / scores.length;
  return ((avg / 5) * 100).round();
}
