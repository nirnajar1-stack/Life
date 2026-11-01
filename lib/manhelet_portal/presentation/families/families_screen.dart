import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/providers.dart';

class FamiliesScreen extends ConsumerStatefulWidget {
  const FamiliesScreen({super.key});

  @override
  ConsumerState<FamiliesScreen> createState() => _FamiliesScreenState();
}

class _FamiliesScreenState extends ConsumerState<FamiliesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(familiesProvider(_search));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'חיפוש משפחה / קוד / יישוב',
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('שגיאה: $e')),
            data: (families) {
              if (families.isEmpty) {
                return const Center(child: Text('לא נמצאו משפחות.'));
              }
              return ListView.separated(
                itemCount: families.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final f = families[i];
                  return ListTile(
                    title: Text(f.displayNameHe),
                    subtitle: Text(
                      [
                        f.familyCode,
                        f.localityHe,
                        if (f.scenarioTag != null && f.scenarioTag != 'BULK')
                          'תרחיש ${f.scenarioTag}',
                      ].whereType<String>().join(' · '),
                    ),
                    onTap: () => context.go('/families/${f.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class FamilyDetailScreen extends ConsumerWidget {
  const FamilyDetailScreen({super.key, required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<
        ({
          FamilySummary? family,
          List<PersonSummary> persons,
          List<TreatmentUnitSummary> units
        })>(
      future: () async {
        final caseload = ref.read(caseloadServiceProvider);
        final family = await caseload.getFamily(familyId);
        final persons = await caseload.listPersons(familyId: familyId);
        final units = (await caseload.listMyUnits())
            .where((u) => u.familyId == familyId)
            .toList();
        return (family: family, persons: persons, units: units);
      }(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final family = data.family;
        if (family == null) {
          return const Center(child: Text('המשפחה לא נמצאה.'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              family.displayNameHe,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('${family.familyCode} · ${family.localityHe ?? ''}'),
            const SizedBox(height: 16),
            Text('יחידות טיפול', style: Theme.of(context).textTheme.titleMedium),
            for (final u in data.units)
              ListTile(
                title: Text(u.titleHe),
                subtitle: Text('${u.openTaskCount} משימות פתוחות'),
                onTap: () => context.go('/units/${u.id}'),
              ),
            const SizedBox(height: 16),
            Text('בני המשפחה', style: Theme.of(context).textTheme.titleMedium),
            for (final p in data.persons)
              ListTile(
                title: Text(p.fullNameHe),
                subtitle: Text(p.status),
                onTap: () => context.go('/persons/${p.id}'),
              ),
          ],
        );
      },
    );
  }
}
