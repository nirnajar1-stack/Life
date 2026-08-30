import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/supabase/supabase_providers.dart';
import '../../../data/models/character_models.dart';
import '../../../data/repositories/character_repository.dart';
import '../config/pd_character_registry.dart';
import '../engine/character_engine.dart';
import '../models/character_enums.dart';
import '../../providers/personal_dev_providers.dart';

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepository(ref.watch(supabaseClientProvider));
});

final pdCharacterEvidenceProvider =
    FutureProvider.family<List<PdCharacterEvidence>, String>((ref, traitId) {
  return ref.watch(characterRepositoryProvider).fetchEvidenceForTrait(traitId);
});

List<PdCharacterEvidenceSnapshot> _toSnapshots(List<PdCharacterEvidence> rows) {
  return rows
      .map(
        (e) => PdCharacterEvidenceSnapshot(
          traitId: e.traitId,
          indicatorId: e.indicatorId,
          occurredAt: e.occurredAt,
          opportunityDetected: e.opportunityDetected,
          demonstrated: e.demonstrated,
          context: e.context,
        ),
      )
      .toList();
}

final pdCharacterTraitSummaryProvider =
    FutureProvider.family<PdCharacterTraitSummary, String>((ref, traitId) async {
  final evidence =
      await ref.watch(characterRepositoryProvider).fetchEvidenceForTrait(traitId);
  return summarizeCharacterTrait(
    traitId: traitId,
    evidence: _toSnapshots(evidence),
  );
});

final pdCharacterWeeklyReviewProvider =
    FutureProvider.family<PdCharacterWeeklyReview, String>((ref, traitId) async {
  final trait = pdCharacterRegistry[traitId];
  final evidence =
      await ref.watch(characterRepositoryProvider).fetchEvidenceForTrait(traitId);
  return buildWeeklyCharacterReview(
    traitId: traitId,
    evidence: _toSnapshots(evidence),
    indicatorIds: trait?.indicators.map((i) => i.indicatorId).toList() ?? const [],
  );
});

final pdCharacterFocusTraitIdProvider = FutureProvider<String?>((ref) async {
  final focus = await ref.watch(pdFocusCycleProvider.future);
  return focus?.traitFocus;
});

class CharacterController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  CharacterRepository get _repo => ref.read(characterRepositoryProvider);

  Future<void> logManualEvidence({
    required String traitId,
    required String indicatorId,
    required bool demonstrated,
    bool opportunityDetected = true,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.logEvidence(
        traitId: traitId,
        indicatorId: indicatorId,
        demonstrated: demonstrated,
        opportunityDetected: opportunityDetected,
        note: note,
        source: PdCharacterEvidenceSource.manualReflection,
      );
      ref.invalidate(pdCharacterEvidenceProvider(traitId));
      ref.invalidate(pdCharacterTraitSummaryProvider(traitId));
      ref.invalidate(pdCharacterWeeklyReviewProvider(traitId));
    });
  }
}

final characterControllerProvider =
    AsyncNotifierProvider<CharacterController, void>(CharacterController.new);
