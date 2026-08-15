import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/habit_models.dart';
import '../../domain/habit_engine.dart';
import '../../domain/models/habit_enums.dart';
import '../../domain/providers/habit_providers.dart';
import 'habit_form_screen.dart';
import '../widgets/habit_checkin_tile.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Habit? habit,
  }) async {
    await showAdaptiveForm(
      context: context,
      form: HabitFormScreen(habit: habit),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitsControllerProvider);
    final isDesktop = AppLayout.isDesktop(context);
    final today = DateTime.now();

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('הרגלים'),
              automaticallyImplyLeading: false,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('הרגל'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(habitsControllerProvider.notifier).reload(),
        child: AppLayout.constrain(
          context: context,
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              padding: AppLayout.pagePadding,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'לא ניתן לטעון הרגלים: $error',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  padding: AppLayout.pagePadding,
                  children: [
                    if (isDesktop)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'הרגלים',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    AppEmptyState(
                      icon: Icons.loop,
                      title: 'אין הרגלים עדיין',
                      message:
                          'הגדירו הרגל עם טריגר ושעת יום — הוא יופיע בלוח היום ובלוח הזמנים.',
                      actionLabel: 'הרגל חדש',
                      onAction: () => _openForm(context, ref),
                    ),
                  ],
                );
              }

              final due = items
                  .where((item) => habitIsDueOn(item.habit, today))
                  .toList();
              final rest = items
                  .where((item) => !habitIsDueOn(item.habit, today))
                  .toList();
              final doneCount = due.where((item) {
                final log = item.logOn(today);
                return log != null && log.countsForStreak;
              }).length;

              return ListView(
                padding: AppLayout.pagePadding.copyWith(
                  top: isDesktop ? 20 : 4,
                  bottom: 96,
                ),
                children: [
                  if (isDesktop)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'הרגלים',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  _RoutineSummary(due: due.length, done: doneCount),
                  const SizedBox(height: 16),
                  const Text(
                    'שגרת היום',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (due.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'אין הרגלים מתוזמנים להיום.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < due.length; i++) ...[
                            HabitCheckinTile(snapshot: due[i]),
                            if (i < due.length - 1) const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'כל ההרגלים',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final snapshot in [...due, ...rest])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HabitCard(
                        snapshot: snapshot,
                        onOpen: () =>
                            _openForm(context, ref, habit: snapshot.habit),
                        onArchive: () => ref
                            .read(habitsControllerProvider.notifier)
                            .archive(snapshot.habit.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoutineSummary extends StatelessWidget {
  const _RoutineSummary({required this.due, required this.done});

  final int due;
  final int done;

  @override
  Widget build(BuildContext context) {
    final pending = due - done;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'שגרה היום',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    due == 0 ? 'אין הרגלים להיום' : '$done מתוך $due בוצעו',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (pending > 0)
                    Text(
                      '$pending נשארו',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: AppColors.shared.withValues(alpha: 0.12),
              foregroundColor: AppColors.shared,
              child: Text(
                due == 0 ? '—' : '$done',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.snapshot,
    required this.onOpen,
    required this.onArchive,
  });

  final HabitSnapshot snapshot;
  final VoidCallback onOpen;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final habit = snapshot.habit;
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        habit.timeOfDay.labelHe,
                        habit.frequency.labelHe,
                        if (habit.habitType == HabitType.measurable &&
                            habit.targetValue != null)
                          '${habit.targetValue!.toStringAsFixed(habit.targetValue == habit.targetValue!.roundToDouble() ? 0 : 1)}${habit.unit == null ? '' : ' ${habit.unit}'}',
                        'רצף ${habit.currentStreak}',
                        if (habit.longestStreak > 0)
                          'שיא ${habit.longestStreak}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if ((habit.cueTrigger ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.cueTrigger!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'ארכיון',
                onPressed: onArchive,
                icon: const Icon(Icons.archive_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
