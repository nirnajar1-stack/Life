import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/character/config/pd_character_registry.dart';
import '../../domain/character/providers/character_providers.dart';
import 'manual_evidence_screen.dart';
import 'trait_detail_screen.dart';
import 'weekly_character_review_screen.dart';

class CharacterTraitCard extends ConsumerWidget {
  const CharacterTraitCard({
    super.key,
    required this.traitId,
    this.onTap,
  });

  final String traitId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trait = pdCharacterRegistry[traitId];
    if (trait == null) return const SizedBox.shrink();

    final summaryAsync = ref.watch(pdCharacterTraitSummaryProvider(traitId));

    return summaryAsync.when(
      loading: () => const Card(
        child: ListTile(
          title: Text('טוען...'),
          trailing: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Card(child: ListTile(title: Text('שגיאה: $e'))),
      data: (summary) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trait.nameHe,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Text(
                      summary.evidenceLevel.labelHe,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.development,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.demonstrations} / ${summary.opportunities} opportunities',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  summary.trend.labelHe,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusTraitId = ref.watch(pdCharacterFocusTraitIdProvider).valueOrNull;
    final focusTrait = focusTraitId != null
        ? pdCharacterRegistry[focusTraitId]
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Character')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          Text(
            'דפוסי פעולה לאורך זמן — לא Skills ולא ציונים.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          if (focusTrait != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.development.withValues(alpha: 0.06),
              child: ListTile(
                title: const Text(
                  'Character Focus',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(focusTrait.nameHe),
                trailing: Icon(Icons.center_focus_strong,
                    color: AppColors.development),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      WeeklyCharacterReviewScreen(traitId: focusTrait.traitId),
                ),
              ),
              icon: const Icon(Icons.calendar_view_week_outlined),
              label: const Text('Weekly Character Review'),
            ),
          ],
          const SizedBox(height: 20),
          ...allPdCharacterTraits.map(
            (trait) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CharacterTraitCard(
                traitId: trait.traitId,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TraitDetailScreen(traitId: trait.traitId),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: focusTraitId == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ManualEvidenceScreen(traitId: focusTraitId),
                      ),
                    ),
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('הוסף Evidence ידני'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.development,
            ),
          ),
        ],
      ),
    );
  }
}
