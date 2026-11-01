import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/task_service.dart';
import '../../domain/models.dart';
import '../../domain/providers.dart';

class UnitsListScreen extends ConsumerWidget {
  const UnitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myUnitsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (units) {
        if (units.isEmpty) {
          return const Center(child: Text('אין יחידות מורשות.'));
        }
        return ListView.separated(
          itemCount: units.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final u = units[i];
            return ListTile(
              title: Text(u.titleHe),
              subtitle: Text(
                '${u.familyNameHe} · ${u.openTaskCount} פתוחות · ${u.personCount} אנשים',
              ),
              onTap: () => context.go('/units/${u.id}'),
            );
          },
        );
      },
    );
  }
}

class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: FutureBuilder<
          ({
            TreatmentUnitSummary? unit,
            List<PersonSummary> persons,
            List<PortalTask> tasks
          })>(
        future: () async {
          final unit = await ref.read(caseloadServiceProvider).getUnit(unitId);
          final persons =
              await ref.read(caseloadServiceProvider).listPersons(unitId: unitId);
          final tasks = await ref.read(taskServiceProvider).listTasks(
                filters: TaskFilters(
                  treatmentUnitId: unitId,
                  openOnly: false,
                ),
              );
          return (unit: unit, persons: persons, tasks: tasks);
        }(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final unit = data.unit;
          if (unit == null) {
            return const Center(child: Text('יחידה לא נמצאה.'));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.titleHe,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                      '${unit.familyNameHe} · ${unit.unitCode} · ${unit.status}',
                    ),
                    TextButton(
                      onPressed: () => context.go('/families/${unit.familyId}'),
                      child: const Text('מעבר למשפחה הראשית'),
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'סקירה'),
                  Tab(text: 'בני המשפחה'),
                  Tab(text: 'משימות'),
                  Tab(text: 'צוות'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('משימות פתוחות: ${unit.openTaskCount}'),
                        Text('אנשים ביחידה: ${unit.personCount}'),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () {
                            ref.read(taskFiltersProvider.notifier).state =
                                TaskFilters(treatmentUnitId: unitId);
                            context.go('/tasks');
                          },
                          child: const Text('פתיחת מרכז המשימות ליחידה'),
                        ),
                      ],
                    ),
                    ListView(
                      children: [
                        for (final p in data.persons)
                          ListTile(
                            title: Text(p.fullNameHe),
                            subtitle: Text(
                              [
                                p.status,
                                if (p.isIndexCase) 'מקרה אינדקס',
                                if (p.ageYears != null) 'גיל ${p.ageYears}',
                              ].join(' · '),
                            ),
                            onTap: () => context.go('/persons/${p.id}'),
                          ),
                      ],
                    ),
                    ListView(
                      children: [
                        for (final t in data.tasks.take(50))
                          ListTile(
                            title: Text(t.titleHe),
                            subtitle: Text(taskStatusLabelHe(t.status)),
                            onTap: () => context.go('/tasks/${t.id}'),
                          ),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'מנהל תיק ראשי: ${unit.primaryCaseManagerId ?? 'לא הוגדר'}',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'נציגים ממשלתיים משויכים דרך gov_rep_treatment_units (מוצגים לפי RLS).',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PersonProfileScreen extends ConsumerWidget {
  const PersonProfileScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(caseloadServiceProvider).getPerson(personId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final p = snap.data;
        if (p == null) {
          return const Center(child: Text('הפרופיל לא נמצא או שאין הרשאה.'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(p.fullNameHe,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('סטטוס: ${p.status}'),
            if (p.dateOfBirth != null)
              Text(
                'תאריך לידה: ${p.dateOfBirth!.toIso8601String().substring(0, 10)}'
                '${p.ageYears != null ? ' (גיל ${p.ageYears})' : ''}',
              ),
            if (p.phone != null) Text('טלפון: ${p.phone}'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/units/${p.treatmentUnitId}'),
              child: const Text('מעבר ליחידת הטיפול'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/families/${p.familyId}'),
              child: const Text('מעבר למשפחה'),
            ),
            FilledButton.tonal(
              onPressed: () {
                ref.read(taskFiltersProvider.notifier).state =
                    TaskFilters(personId: p.id);
                context.go('/tasks');
              },
              child: const Text('משימות מקושרות'),
            ),
          ],
        );
      },
    );
  }
}
