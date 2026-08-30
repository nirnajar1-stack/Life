import '../models/character_enums.dart';

/// Lightweight evidence record for engine calculations.
class PdCharacterEvidenceSnapshot {
  const PdCharacterEvidenceSnapshot({
    required this.traitId,
    required this.indicatorId,
    required this.occurredAt,
    required this.opportunityDetected,
    required this.demonstrated,
    this.context,
  });

  final String traitId;
  final String indicatorId;
  final DateTime occurredAt;
  final bool opportunityDetected;
  final bool demonstrated;
  final Map<String, dynamic>? context;
}

class PdCharacterTraitSummary {
  const PdCharacterTraitSummary({
    required this.traitId,
    required this.evidenceLevel,
    required this.demonstrations,
    required this.opportunities,
    required this.consistencyPercent,
    required this.trend,
    required this.recentDemonstrations,
  });

  final String traitId;
  final PdEvidenceLevel evidenceLevel;
  final int demonstrations;
  final int opportunities;
  final int consistencyPercent;
  final PdCharacterTrend trend;
  final int recentDemonstrations;
}

class PdIndicatorStats {
  const PdIndicatorStats({
    required this.indicatorId,
    required this.demonstrations,
    required this.opportunities,
    required this.consistencyPercent,
  });

  final String indicatorId;
  final int demonstrations;
  final int opportunities;
  final int consistencyPercent;
}

class PdCharacterWeeklyReview {
  const PdCharacterWeeklyReview({
    required this.traitId,
    required this.weekStart,
    required this.opportunities,
    required this.demonstrations,
    required this.consistencyPercent,
    required this.strongestIndicatorId,
    required this.missedIndicatorId,
  });

  final String traitId;
  final DateTime weekStart;
  final int opportunities;
  final int demonstrations;
  final int consistencyPercent;
  final String? strongestIndicatorId;
  final String? missedIndicatorId;
}

/// Consistency = demonstrated / opportunities (when opportunity_detected).
int computeCharacterConsistencyPercent({
  required int opportunities,
  required int demonstrations,
}) {
  if (opportunities <= 0) return 0;
  return ((demonstrations / opportunities) * 100).round().clamp(0, 100);
}

PdEvidenceLevel computeEvidenceLevel({
  required int opportunities,
  required int demonstrations,
  required int consistencyPercent,
}) {
  if (opportunities < 3 && demonstrations < 2) {
    return PdEvidenceLevel.emerging;
  }
  if (consistencyPercent >= 75 && demonstrations >= 12 && opportunities >= 10) {
    return PdEvidenceLevel.strongEvidence;
  }
  if (consistencyPercent >= 55 && demonstrations >= 6 && opportunities >= 6) {
    return PdEvidenceLevel.consistent;
  }
  if (demonstrations >= 2 || consistencyPercent >= 35) {
    return PdEvidenceLevel.developing;
  }
  return PdEvidenceLevel.emerging;
}

PdCharacterTrend computeCharacterTrend({
  required List<PdCharacterEvidenceSnapshot> evidence,
  DateTime? now,
}) {
  final anchor = now ?? DateTime.now();
  final recentStart = anchor.subtract(const Duration(days: 14));
  final priorStart = anchor.subtract(const Duration(days: 28));

  final recent = _consistencyForWindow(evidence, recentStart, anchor);
  final prior = _consistencyForWindow(evidence, priorStart, recentStart);

  if (recent.opportunities < 2 && prior.opportunities < 2) {
    return PdCharacterTrend.stable;
  }
  if (recent.percent > prior.percent + 8) return PdCharacterTrend.improving;
  if (recent.percent + 8 < prior.percent) return PdCharacterTrend.declining;
  return PdCharacterTrend.stable;
}

class _WindowConsistency {
  const _WindowConsistency(this.opportunities, this.demonstrations, this.percent);
  final int opportunities;
  final int demonstrations;
  final int percent;
}

_WindowConsistency _consistencyForWindow(
  List<PdCharacterEvidenceSnapshot> evidence,
  DateTime start,
  DateTime end,
) {
  final window = evidence.where(
    (e) =>
        e.opportunityDetected &&
        !e.occurredAt.isBefore(start) &&
        e.occurredAt.isBefore(end),
  );
  final opportunities = window.length;
  final demonstrations = window.where((e) => e.demonstrated).length;
  return _WindowConsistency(
    opportunities,
    demonstrations,
    computeCharacterConsistencyPercent(
      opportunities: opportunities,
      demonstrations: demonstrations,
    ),
  );
}

PdCharacterTraitSummary summarizeCharacterTrait({
  required String traitId,
  required List<PdCharacterEvidenceSnapshot> evidence,
  DateTime? now,
}) {
  final traitEvidence = evidence.where((e) => e.traitId == traitId).toList();
  final opportunities =
      traitEvidence.where((e) => e.opportunityDetected).length;
  final demonstrations =
      traitEvidence.where((e) => e.opportunityDetected && e.demonstrated).length;
  final consistency = computeCharacterConsistencyPercent(
    opportunities: opportunities,
    demonstrations: demonstrations,
  );
  final anchor = now ?? DateTime.now();
  final recentDemonstrations = traitEvidence
      .where(
        (e) =>
            e.demonstrated &&
            !e.occurredAt.isBefore(anchor.subtract(const Duration(days: 14))),
      )
      .length;

  return PdCharacterTraitSummary(
    traitId: traitId,
    evidenceLevel: computeEvidenceLevel(
      opportunities: opportunities,
      demonstrations: demonstrations,
      consistencyPercent: consistency,
    ),
    demonstrations: demonstrations,
    opportunities: opportunities,
    consistencyPercent: consistency,
    trend: computeCharacterTrend(evidence: traitEvidence, now: anchor),
    recentDemonstrations: recentDemonstrations,
  );
}

PdCharacterWeeklyReview buildWeeklyCharacterReview({
  required String traitId,
  required List<PdCharacterEvidenceSnapshot> evidence,
  required List<String> indicatorIds,
  DateTime? now,
}) {
  final anchor = now ?? DateTime.now();
  final weekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  final weekEvidence = evidence.where(
    (e) =>
        e.traitId == traitId &&
        e.opportunityDetected &&
        !e.occurredAt.isBefore(weekStart) &&
        e.occurredAt.isBefore(weekEnd),
  );

  final opportunities = weekEvidence.length;
  final demonstrations = weekEvidence.where((e) => e.demonstrated).length;
  final consistency = computeCharacterConsistencyPercent(
    opportunities: opportunities,
    demonstrations: demonstrations,
  );

  final stats = <PdIndicatorStats>[
    for (final id in indicatorIds)
      _indicatorStats(id, weekEvidence.toList()),
  ];

  PdIndicatorStats? strongest;
  PdIndicatorStats? missed;
  for (final stat in stats) {
    if (stat.opportunities == 0) continue;
    if (strongest == null ||
        stat.demonstrations > strongest.demonstrations) {
      strongest = stat;
    }
    if (missed == null ||
        stat.consistencyPercent < missed.consistencyPercent) {
      missed = stat;
    }
  }

  return PdCharacterWeeklyReview(
    traitId: traitId,
    weekStart: weekStart,
    opportunities: opportunities,
    demonstrations: demonstrations,
    consistencyPercent: consistency,
    strongestIndicatorId: strongest?.indicatorId,
    missedIndicatorId: missed?.indicatorId,
  );
}

PdIndicatorStats _indicatorStats(
  String indicatorId,
  List<PdCharacterEvidenceSnapshot> evidence,
) {
  final rows = evidence.where((e) => e.indicatorId == indicatorId).toList();
  final opportunities = rows.length;
  final demonstrations = rows.where((e) => e.demonstrated).length;
  return PdIndicatorStats(
    indicatorId: indicatorId,
    demonstrations: demonstrations,
    opportunities: opportunities,
    consistencyPercent: computeCharacterConsistencyPercent(
      opportunities: opportunities,
      demonstrations: demonstrations,
    ),
  );
}

/// Context analytics for character (consistency by context bucket — not personality score).
class PdCharacterContextAnalytics {
  const PdCharacterContextAnalytics({
    required this.contextKey,
    required this.overallConsistencyPercent,
    required this.groups,
  });

  final String contextKey;
  final int overallConsistencyPercent;
  final List<PdCharacterContextGroup> groups;
}

class PdCharacterContextGroup {
  const PdCharacterContextGroup({
    required this.label,
    required this.consistencyPercent,
    required this.opportunities,
  });

  final String label;
  final int consistencyPercent;
  final int opportunities;
}

PdCharacterContextAnalytics computeCharacterContextAnalytics({
  required List<PdCharacterEvidenceSnapshot> evidence,
  required String contextKey,
}) {
  final rows = evidence.where((e) => e.opportunityDetected).toList();
  if (rows.isEmpty) {
    return PdCharacterContextAnalytics(
      contextKey: contextKey,
      overallConsistencyPercent: 0,
      groups: const [],
    );
  }

  final overall = computeCharacterConsistencyPercent(
    opportunities: rows.length,
    demonstrations: rows.where((e) => e.demonstrated).length,
  );

  final buckets = <String, List<PdCharacterEvidenceSnapshot>>{};
  for (final row in rows) {
    final raw = row.context?[contextKey]?.toString();
    final label = (raw == null || raw.trim().isEmpty) ? 'לא צוין' : raw.trim();
    buckets.putIfAbsent(label, () => []).add(row);
  }

  final groups = buckets.entries
      .map(
        (entry) => PdCharacterContextGroup(
          label: entry.key,
          opportunities: entry.value.length,
          consistencyPercent: computeCharacterConsistencyPercent(
            opportunities: entry.value.length,
            demonstrations: entry.value.where((e) => e.demonstrated).length,
          ),
        ),
      )
      .toList()
    ..sort((a, b) => b.consistencyPercent.compareTo(a.consistencyPercent));

  return PdCharacterContextAnalytics(
    contextKey: contextKey,
    overallConsistencyPercent: overall,
    groups: groups,
  );
}
