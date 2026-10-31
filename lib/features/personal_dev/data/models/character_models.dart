import '../../domain/character/models/character_enums.dart';

class PdCharacterEvidence {
  const PdCharacterEvidence({
    required this.evidenceId,
    required this.traitId,
    required this.indicatorId,
    required this.occurredAt,
    this.eventId,
    this.context,
    required this.opportunityDetected,
    required this.demonstrated,
    this.note,
    required this.source,
    required this.createdAt,
  });

  final String evidenceId;
  final String traitId;
  final String indicatorId;
  final DateTime occurredAt;
  final String? eventId;
  final Map<String, dynamic>? context;
  final bool opportunityDetected;
  final bool demonstrated;
  final String? note;
  final PdCharacterEvidenceSource source;
  final DateTime createdAt;

  factory PdCharacterEvidence.fromJson(Map<String, dynamic> json) {
    final rawContext = json['context'];
    Map<String, dynamic>? context;
    if (rawContext is Map) {
      context = Map<String, dynamic>.from(rawContext);
    }

    return PdCharacterEvidence(
      evidenceId: json['id'] as String,
      traitId: json['trait_id'] as String,
      indicatorId: json['indicator_id'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      eventId: json['event_id'] as String?,
      context: context,
      opportunityDetected: json['opportunity_detected'] as bool? ?? true,
      demonstrated: json['demonstrated'] as bool,
      note: json['note'] as String?,
      source: PdCharacterEvidenceSource.fromDb(json['source'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trait_id': traitId,
      'indicator_id': indicatorId,
      'occurred_at': occurredAt.toIso8601String(),
      if (eventId != null) 'event_id': eventId,
      if (context != null) 'context': context,
      'opportunity_detected': opportunityDetected,
      'demonstrated': demonstrated,
      if (note != null) 'note': note,
      'source': source.dbValue,
    };
  }
}
