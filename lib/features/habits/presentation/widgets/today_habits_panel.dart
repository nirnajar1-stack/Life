import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/habit_models.dart';
import '../../domain/providers/habit_providers.dart';
import 'habit_checkin_tile.dart';

class TodayHabitsPanel extends ConsumerWidget {
  const TodayHabitsPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitsControllerProvider);
    final due = ref.watch(todaysHabitsProvider);
    if (async.isLoading && due.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    if (due.isEmpty) return const SizedBox.shrink();

    final done = due.where((item) {
      final log = item.logOn(DateTime.now());
      return log != null && log.countsForStreak;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'הרגלים להיום · $done/${due.length}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Card(
          margin: compact
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < due.length; i++) ...[
                HabitCheckinTile(snapshot: due[i], compact: compact),
                if (i < due.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CalendarHabitChip extends ConsumerWidget {
  const CalendarHabitChip({
    super.key,
    required this.snapshot,
    required this.day,
  });

  final HabitSnapshot snapshot;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = snapshot.logOn(day);
    final done = log?.completed ?? false;
    return Align(
      alignment: Alignment.centerRight,
      child: InputChip(
        avatar: Icon(
          done ? Icons.check_circle : Icons.loop,
          size: 16,
          color: AppColors.habits,
        ),
        label: Text(snapshot.habit.title),
        selected: done,
        onPressed: () {
          ref.read(habitsControllerProvider.notifier).logToday(
                snapshot: snapshot,
                day: day,
                completed: !done,
                valueRecorded: !done && snapshot.habit.targetValue != null
                    ? snapshot.habit.targetValue
                    : log?.valueRecorded,
              );
        },
      ),
    );
  }
}
