import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/character/config/pd_skill_character_mapping.dart';
import '../../domain/character/models/character_enums.dart';
import '../models/character_models.dart';

class CharacterRepository {
  CharacterRepository(this._client);

  final SupabaseClient _client;

  Future<List<PdCharacterEvidence>> fetchEvidenceForTrait(String traitId) async {
    final rows = await _client
        .from('pd_character_evidence')
        .select()
        .eq('trait_id', traitId)
        .order('occurred_at', ascending: false);
    return (rows as List)
        .map(
          (row) =>
              PdCharacterEvidence.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<PdCharacterEvidence>> fetchRecentEvidence({
    String? traitId,
    int limit = 100,
  }) async {
    var query = _client.from('pd_character_evidence').select();
    if (traitId != null) {
      query = query.eq('trait_id', traitId);
    }
    final rows = await query.order('occurred_at', ascending: false).limit(limit);
    return (rows as List)
        .map(
          (row) =>
              PdCharacterEvidence.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<PdCharacterEvidence> logEvidence({
    required String traitId,
    required String indicatorId,
    required bool demonstrated,
    bool opportunityDetected = true,
    PdCharacterEvidenceSource source = PdCharacterEvidenceSource.manualReflection,
    String? eventId,
    Map<String, dynamic>? context,
    String? note,
    DateTime? occurredAt,
  }) async {
    final row = await _client
        .from('pd_character_evidence')
        .insert({
          'trait_id': traitId,
          'indicator_id': indicatorId,
          'occurred_at': (occurredAt ?? DateTime.now()).toIso8601String(),
          if (eventId != null) 'event_id': eventId,
          if (context != null) 'context': context,
          'opportunity_detected': opportunityDetected,
          'demonstrated': demonstrated,
          if (note != null) 'note': note,
          'source': source.dbValue,
        })
        .select()
        .single();
    return PdCharacterEvidence.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> syncEvidenceFromEvent({
    required String eventId,
    required String skillId,
    required List<String> microBehaviors,
    Map<String, dynamic>? context,
    DateTime? occurredAt,
  }) async {
    final mappings = mappingsForEvent(
      skillId: skillId,
      checkedBehaviorIds: microBehaviors,
    );
    if (mappings.isEmpty) return;

    await _client.from('pd_character_evidence').delete().eq('event_id', eventId);

    final when = occurredAt ?? DateTime.now();
    for (final mapping in mappings) {
      await _client.from('pd_character_evidence').insert({
        'trait_id': mapping.traitId,
        'indicator_id': mapping.indicatorId,
        'occurred_at': when.toIso8601String(),
        'event_id': eventId,
        if (context != null) 'context': context,
        'opportunity_detected': true,
        'demonstrated': true,
        'source': PdCharacterEvidenceSource.event.dbValue,
      });
    }
  }
}
