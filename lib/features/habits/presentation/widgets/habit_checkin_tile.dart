import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/habit_models.dart';
import '../../domain/habit_engine.dart';
import '../../domain/models/habit_enums.dart';
import '../../domain/providers/habit_providers.dart';

class HabitCheckinTile extends ConsumerWidget {
  const HabitCheckinTile({
    super.key,
    required this.snapshot,
    this.compact = false,
  });

  final HabitSnapshot snapshot;
  final bool compact;

  Habit get habit => snapshot.habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final log = snapshot.logOn(today);
    final done = log?.completed ?? false;
    final frozen = log?.usedFreeze ?? false;
    final canFreeze = !done && !frozen && canUseHabitFreeze(habit, today);
    final cue = habit.cueTrigger?.trim();
    final progress = _progressLabel(log);

    return ListTile(
      dense: compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 0 : 2,
      ),
      leading: IconButton(
        tooltip: done ? 'בטל סימון' : 'סמן כבוצע',
        onPressed: () => _toggleComplete(context, ref, log),
        icon: Icon(
          done
              ? Icons.check_circle
              : frozen
                  ? Icons.ac_unit
                  : Icons.circle_outlined,
              color: done
              ? AppColors.habits
              : frozen
                  ? AppColors.tasks
                  : AppColors.muted,
        ),
      ),
      title: Text(
        habit.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          habit.timeOfDay.labelHe,
          if (habit.currentStreak > 0) 'רצף ${habit.currentStreak}',
          if (progress != null) progress,
          if (cue != null && cue.isNotEmpty && !compact) cue,
        ].join(' · '),
        maxLines: compact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canFreeze)
            IconButton(
              tooltip: 'יום הקפאה',
              onPressed: () => _freeze(context, ref),
              icon: const Icon(Icons.ac_unit, size: 20),
            ),
          if (habit.habitType == HabitType.measurable)
            IconButton(
              tooltip: 'רשום ערך',
              onPressed: () => _recordValue(context, ref, log),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
        ],
      ),
      onTap: habit.habitType == HabitType.measurable
          ? () => _recordValue(context, ref, log)
          : () => _toggleComplete(context, ref, log),
    );
  }

  String? _progressLabel(HabitLog? log) {
    if (habit.habitType != HabitType.measurable) return null;
    final recorded = log?.valueRecorded;
    final unit = habit.unit?.trim();
    final target = habit.targetValue;
    if (recorded == null && target == null) return null;
    final left = recorded == null ? '0' : _trim(recorded);
    final right = target == null ? '' : '/${_trim(target)}';
    final suffix = unit == null || unit.isEmpty ? '' : ' $unit';
    return '$left$right$suffix';
  }

  String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  Future<void> _toggleComplete(
    BuildContext context,
    WidgetRef ref,
    HabitLog? log,
  ) async {
    final done = log?.completed ?? false;
    try {
      await ref.read(habitsControllerProvider.notifier).logToday(
            snapshot: snapshot,
            completed: !done,
            valueRecorded: !done && habit.habitType == HabitType.measurable
                ? habit.targetValue
                : (done ? null : log?.valueRecorded),
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('עדכון נכשל: $error')),
      );
    }
  }

  Future<void> _freeze(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(habitsControllerProvider.notifier).logToday(
            snapshot: snapshot,
            completed: false,
            usedFreeze: true,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('הקפאה נכשלה: $error')),
      );
    }
  }

  Future<void> _recordValue(
    BuildContext context,
    WidgetRef ref,
    HabitLog? log,
  ) async {
    final controller = TextEditingController(
      text: log?.valueRecorded == null ? '' : _trim(log!.valueRecorded!),
    );
    final unit = habit.unit?.trim();
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(habit.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: unit == null || unit.isEmpty ? 'ערך היום' : unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null) return;
              Navigator.pop(ctx, parsed);
            },
            child: const Text('שמירה'),
          ),
        ],
      ),
    );
    if (value == null) return;
    final target = habit.targetValue;
    final complete = target == null ? true : value >= target;
    try {
      await ref.read(habitsControllerProvider.notifier).logToday(
            snapshot: snapshot,
            completed: complete,
            valueRecorded: value,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('עדכון נכשל: $error')),
      );
    }
  }
}
