import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/character/config/pd_character_registry.dart';
import '../../domain/character/providers/character_providers.dart';

class WeeklyCharacterReviewScreen extends ConsumerWidget {
  const WeeklyCharacterReviewScreen({super.key, required this.traitId});

  final String traitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trait = pdCharacterRegistry[traitId];
    if (trait == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Review')),
        body: const Center(child: Text('Trait לא נמצא')),
      );
    }

    final reviewAsync = ref.watch(pdCharacterWeeklyReviewProvider(traitId));
    final fmt = DateFormat('d/M', 'he');

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Character Review')),
      body: AppLayout.constrain(
        context: context,
        compact: 640,
        child: ListView(
          padding: AppLayout.listPadding,
          children: [
            Text(
              trait.nameHe,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            reviewAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('שגיאה: $e'),
              data: (review) {
                final strongest = trait.indicatorById(review.strongestIndicatorId ?? '');
                final missed = trait.indicatorById(review.missedIndicatorId ?? '');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'שבוע מ-${fmt.format(review.weekStart)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Row('Opportunities', '${review.opportunities}'),
                            _Row('Demonstrated', '${review.demonstrations}'),
                            _Row('Consistency', '${review.consistencyPercent}%'),
                            if (strongest != null)
                              _Row('Strongest indicator', strongest.labelHe),
                            if (missed != null)
                              _Row(
                                'Development opportunity',
                                missed.labelHe,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
