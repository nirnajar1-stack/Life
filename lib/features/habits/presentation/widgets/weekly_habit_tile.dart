import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/habit_models.dart';
import '../../domain/habit_engine.dart';
import '../../domain/models/habit_enums.dart';
import '../../domain/providers/habit_providers.dart';

class WeeklyHabitTile extends ConsumerWidget {
  const WeeklyHabitTile({
    super.key,
    required this.snapshot,
    required this.onReactivate,
    required this.onOpen,
  });

  final HabitSnapshot snapshot;
  final VoidCallback onReactivate;
  final VoidCallback onOpen;

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    WeeklyCheckinStatus status,
  ) async {
    try {
      await ref.read(habitsControllerProvider.notifier).submitWeeklyCheckin(
            snapshot: snapshot,
            status: status,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נשמר: ${status.labelHe}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שמירה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = snapshot.habit;
    final weekStart = habitWeekStart(DateTime.now());
    final thisWeek = snapshot.weeklyLogFor(weekStart);
    final needsRelapse = habitNeedsRelapseSuggestion(snapshot.weeklyLogs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpen,
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
                            'בוגר',
                            habit.difficulty.labelHe,
                            if (habit.graduatedAt != null)
                              'מ־${habit.graduatedAt!.day}/${habit.graduatedAt!.month}',
                          ].join(' · '),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'חזרה למעקב יומי',
                  onPressed: onReactivate,
                  icon: Icon(
                    Icons.replay,
                    color: needsRelapse ? AppColors.warning : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (thisWeek != null)
              Text(
                'השבוע: ${thisWeek.status.labelHe}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            else
              const Text(
                'עדיין לא דיווחתם על השבוע',
                style: TextStyle(color: AppColors.muted),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in WeeklyCheckinStatus.values)
                  ChoiceChip(
                    label: Text(status.labelHe),
                    selected: thisWeek?.status == status,
                    onSelected: (_) => _submit(context, ref, status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
