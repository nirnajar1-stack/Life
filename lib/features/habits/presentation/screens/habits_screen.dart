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
import '../widgets/weekly_habit_tile.dart';

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

  Future<void> _confirmGraduate(
    BuildContext context,
    WidgetRef ref,
    HabitSnapshot snapshot,
  ) async {
    final eval = evaluateHabitGraduation(
      habit: snapshot.habit,
      logs: snapshot.logs,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('לסיים מעקב יומי?'),
        content: Text(
          '«${snapshot.habit.title}» הגיע ל־${eval.completionsInWindow}/${eval.windowDays} '
          '(≥${eval.requiredCompletions}).\n'
          'המעבר לתחזוקה שבועית מסיר אותו משגרת היום.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('סיום מעקב יומי'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(habitsControllerProvider.notifier).graduate(snapshot);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«${snapshot.habit.title}» עבר לתחזוקה שבועית')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('העברה נכשלה: $error')),
      );
    }
  }

  Future<void> _confirmReactivate(
    BuildContext context,
    WidgetRef ref,
    HabitSnapshot snapshot,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('לחזור למעקב יומי?'),
        content: Text(
          '«${snapshot.habit.title}» יחזור לשגרת היום ל־14+ ימים של איפוס.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('הפעלה מחדש'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(habitsControllerProvider.notifier).reactivate(snapshot);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('הפעלה נכשלה: $error')),
      );
    }
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

              final daily = items
                  .where((item) => item.habit.isDailyActive)
                  .toList();
              final graduated = items
                  .where((item) => item.habit.isWeeklyMaintenance)
                  .toList();
              final due = daily
                  .where((item) => habitIsDueOn(item.habit, today))
                  .toList();
              final restDaily = daily
                  .where((item) => !habitIsDueOn(item.habit, today))
                  .toList();
              final readyToGraduate = daily.where((item) {
                return evaluateHabitGraduation(
                  habit: item.habit,
                  logs: item.logs,
                  now: today,
                ).eligible;
              }).toList();
              final relapseAlerts = graduated
                  .where((item) => habitNeedsRelapseSuggestion(item.weeklyLogs))
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
                  if (readyToGraduate.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final snapshot in readyToGraduate)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _GraduationBanner(
                          snapshot: snapshot,
                          onGraduate: () =>
                              _confirmGraduate(context, ref, snapshot),
                        ),
                      ),
                  ],
                  if (relapseAlerts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final snapshot in relapseAlerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RelapseBanner(
                          snapshot: snapshot,
                          onReactivate: () =>
                              _confirmReactivate(context, ref, snapshot),
                        ),
                      ),
                  ],
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
                          'אין הרגלים במעקב יומי להיום.',
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
                  if (graduated.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'בוגרים · תחזוקה שבועית (${graduated.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ביקורת שבועית קצרה במקום צ׳קליסט יומי',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    for (final snapshot in graduated)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WeeklyHabitTile(
                          snapshot: snapshot,
                          onReactivate: () =>
                              _confirmReactivate(context, ref, snapshot),
                          onOpen: () => _openForm(
                            context,
                            ref,
                            habit: snapshot.habit,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'מעקב יומי',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final snapshot in [...due, ...restDaily])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HabitCard(
                        snapshot: snapshot,
                        onOpen: () =>
                            _openForm(context, ref, habit: snapshot.habit),
                        onArchive: () => ref
                            .read(habitsControllerProvider.notifier)
                            .archive(snapshot.habit.id),
                        onGraduate: evaluateHabitGraduation(
                          habit: snapshot.habit,
                          logs: snapshot.logs,
                          now: today,
                        ).eligible
                            ? () => _confirmGraduate(context, ref, snapshot)
                            : null,
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

class _GraduationBanner extends StatelessWidget {
  const _GraduationBanner({
    required this.snapshot,
    required this.onGraduate,
  });

  final HabitSnapshot snapshot;
  final VoidCallback onGraduate;

  @override
  Widget build(BuildContext context) {
    final eval = evaluateHabitGraduation(
      habit: snapshot.habit,
      logs: snapshot.logs,
    );
    return Card(
      color: AppColors.habits.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: AppColors.habits),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '«${snapshot.habit.title}» מוכן לסיום מעקב יומי '
                '(${eval.completionsInWindow}/${eval.windowDays})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onGraduate, child: const Text('סיים')),
          ],
        ),
      ),
    );
  }
}

class _RelapseBanner extends StatelessWidget {
  const _RelapseBanner({
    required this.snapshot,
    required this.onReactivate,
  });

  final HabitSnapshot snapshot;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            const Icon(Icons.replay, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '«${snapshot.habit.title}» — החלקה שבועיים ברצף. מומלץ איפוס יומי ל־14 יום.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onReactivate, child: const Text('הפעל')),
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
    this.onGraduate,
  });

  final HabitSnapshot snapshot;
  final VoidCallback onOpen;
  final VoidCallback onArchive;
  final VoidCallback? onGraduate;

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
                        habit.difficulty.labelHe,
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
              if (onGraduate != null)
                IconButton(
                  tooltip: 'סיום מעקב יומי',
                  onPressed: onGraduate,
                  icon: const Icon(Icons.emoji_events_outlined),
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
