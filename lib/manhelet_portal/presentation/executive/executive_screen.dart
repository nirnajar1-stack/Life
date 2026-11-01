import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers.dart';
import '../theme/portal_theme.dart';

class ExecutiveScreen extends ConsumerWidget {
  const ExecutiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(caseloadServiceProvider).executiveSituation(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final m = snap.data!;
        final cards = [
          ('משפחות פתוחות', m['open_families'] ?? 0),
          ('יחידות פעילות', m['active_units'] ?? 0),
          ('חטופים', m['persons_captive'] ?? 0),
          ('נעדרים', m['persons_missing'] ?? 0),
          ('שבים', m['persons_returned'] ?? 0),
          ('משימות פתוחות', m['open_tasks'] ?? 0),
          ('משימות קריטיות', m['critical_open_tasks'] ?? 0),
          ('תוכניות שיקום פעילות', m['active_rehab_plans'] ?? 0),
        ];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'תמונת מצב ארגונית',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'נתונים חיים מתוך v_executive_situation (ללא KPI מומצאים).',
              style: TextStyle(color: PortalColors.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in cards)
                  SizedBox(
                    width: 180,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${c.$2}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: PortalColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(c.$1),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
