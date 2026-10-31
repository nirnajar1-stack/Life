import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/character/config/pd_character_trait_config.dart';
import '../../domain/character/config/pd_character_registry.dart';
import '../../domain/character/providers/character_providers.dart';
import 'manual_evidence_screen.dart';

class TraitDetailScreen extends ConsumerWidget {
  const TraitDetailScreen({super.key, required this.traitId});

  final String traitId;

  String _missionForTrait(PdCharacterTraitConfig trait) {
    if (trait.characterMissions.isEmpty) return '';
    final index = DateTime.now().day % trait.characterMissions.length;
    return trait.characterMissions[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trait = pdCharacterRegistry[traitId];
    if (trait == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trait')),
        body: const Center(child: Text('Trait לא נמצא')),
      );
    }

    final summaryAsync = ref.watch(pdCharacterTraitSummaryProvider(traitId));
    final evidenceAsync = ref.watch(pdCharacterEvidenceProvider(traitId));
    final fmt = DateFormat('d/M HH:mm', 'he');

    return Scaffold(
      appBar: AppBar(title: Text(trait.nameHe)),
      body: AppLayout.constrain(
        context: context,
        compact: 720,
        child: ListView(
          padding: AppLayout.listPadding,
          children: [
            summaryAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('שגיאה: $e'),
              data: (summary) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        summary.evidenceLevel.labelHe,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Evidence',
                        value: '${summary.demonstrations} demonstrations',
                      ),
                      _DetailRow(
                        label: 'Opportunities',
                        value: '${summary.opportunities}',
                      ),
                      _DetailRow(
                        label: 'Consistency',
                        value: '${summary.consistencyPercent}%',
                      ),
                      _DetailRow(
                        label: 'Trend',
                        value: summary.trend.labelHe,
                      ),
                      _DetailRow(
                        label: 'Recent Evidence',
                        value: '${summary.recentDemonstrations} (14d)',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Behavioral Definition',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(trait.behavioralDefinitionHe),
            const SizedBox(height: 16),
            Text(
              'Indicators',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            ...trait.indicators.map(
              (indicator) => Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  title: Text(indicator.labelHe),
                  subtitle: Text(indicator.descriptionHe),
                ),
              ),
            ),
            if (trait.characterMissions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Current Character Mission',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.flag_outlined, color: AppColors.development),
                  title: Text(_missionForTrait(trait)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Recent Evidence',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            evidenceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('שגיאה: $e'),
              data: (rows) {
                if (rows.isEmpty) {
                  return Text(
                    'עדיין אין ראיות — הוסף ידנית או קשר מאירוע Skill.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  );
                }
                return Column(
                  children: [
                    for (final row in rows.take(10))
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            trait.indicatorById(row.indicatorId)?.labelHe ??
                                row.indicatorId,
                          ),
                          subtitle: Text(
                            '${fmt.format(row.occurredAt)} · '
                            '${row.demonstrated ? "הודגם" : "הזדמנות שהוחמצה"} · '
                            '${row.source.labelHe}',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManualEvidenceScreen(traitId: traitId),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('הוסף Evidence'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.development,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
