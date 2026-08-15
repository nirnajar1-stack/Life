import '../data/models/habit_models.dart';
import 'models/habit_enums.dart';

DateTime habitDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool habitIsDueOn(Habit habit, DateTime day) {
  if (habit.archived) return false;
  final target = habitDay(day);
  final created = habitDay(habit.createdAt);
  if (target.isBefore(created)) return false;

  switch (habit.frequency) {
    case HabitFrequency.daily:
      return true;
    case HabitFrequency.weekdays:
      return target.weekday <= DateTime.friday;
    case HabitFrequency.specificDays:
      return habit.customDays.contains(target.weekday);
    case HabitFrequency.interval:
      final gap = target.difference(created).inDays;
      final interval = habit.intervalDays < 1 ? 1 : habit.intervalDays;
      return gap % interval == 0;
  }
}

class HabitStreakResult {
  const HabitStreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
}

HabitStreakResult computeHabitStreaks({
  required Habit habit,
  required List<HabitLog> logs,
  DateTime? now,
}) {
  final today = habitDay(now ?? DateTime.now());
  final byDate = {for (final log in logs) log.dateKey: log};
  final completions = logs.where((log) => log.completed).length;

  int current = 0;
  var cursor = today;
  if (habitIsDueOn(habit, cursor)) {
    final todayLog = byDate[formatHabitDate(cursor)];
    if (todayLog == null || !todayLog.countsForStreak) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  final created = habitDay(habit.createdAt);
  while (!cursor.isBefore(created)) {
    if (!habitIsDueOn(habit, cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      continue;
    }
    final log = byDate[formatHabitDate(cursor)];
    if (log != null && log.countsForStreak) {
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  var longest = 0;
  var run = 0;
  cursor = created;
  while (!cursor.isAfter(today)) {
    if (habitIsDueOn(habit, cursor)) {
      final log = byDate[formatHabitDate(cursor)];
      if (log != null && log.countsForStreak) {
        run += 1;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  return HabitStreakResult(
    currentStreak: current,
    longestStreak: longest < current ? current : longest,
    totalCompletions: completions,
  );
}

bool canUseHabitFreeze(Habit habit, DateTime now) {
  final monthStart = DateTime(now.year, now.month);
  final usedMonth = habit.freezeMonth == null
      ? null
      : DateTime(habit.freezeMonth!.year, habit.freezeMonth!.month);
  final used = usedMonth == monthStart ? habit.freezeDaysUsedThisMonth : 0;
  return used < habit.freezeDaysAllowedPerMonth;
}
