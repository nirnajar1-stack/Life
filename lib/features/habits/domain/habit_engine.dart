import '../data/models/habit_models.dart';
import 'models/habit_enums.dart';

DateTime habitDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// ISO week start (Monday) for [day].
DateTime habitWeekStart(DateTime day) {
  final d = habitDay(day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

bool habitIsDueOn(Habit habit, DateTime day) {
  if (habit.archived) return false;
  // Graduated / archived habits leave the daily checklist.
  if (habit.trackingMode != HabitTrackingMode.dailyActive) return false;
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

class HabitGraduationEval {
  const HabitGraduationEval({
    required this.eligible,
    required this.windowDays,
    required this.completionsInWindow,
    required this.requiredCompletions,
    required this.successRate,
    required this.daysTracked,
  });

  final bool eligible;
  final int windowDays;
  final int completionsInWindow;
  final int requiredCompletions;
  final double successRate;
  final int daysTracked;
}

/// Evaluates whether a daily-active habit can graduate to weekly maintenance.
HabitGraduationEval evaluateHabitGraduation({
  required Habit habit,
  required List<HabitLog> logs,
  DateTime? now,
}) {
  final today = habitDay(now ?? DateTime.now());
  final window = habit.difficulty.evaluationWindowDays;
  final required = habit.difficulty.minCompletionsForGraduation;
  final created = habitDay(habit.createdAt);
  final windowStart = today.subtract(Duration(days: window - 1));
  final evalStart = windowStart.isBefore(created) ? created : windowStart;
  final daysTracked = today.difference(created).inDays + 1;

  if (habit.trackingMode != HabitTrackingMode.dailyActive || habit.archived) {
    return HabitGraduationEval(
      eligible: false,
      windowDays: window,
      completionsInWindow: 0,
      requiredCompletions: required,
      successRate: 0,
      daysTracked: daysTracked,
    );
  }

  if (daysTracked < window) {
    return HabitGraduationEval(
      eligible: false,
      windowDays: window,
      completionsInWindow: 0,
      requiredCompletions: required,
      successRate: 0,
      daysTracked: daysTracked,
    );
  }

  final byDate = {for (final log in logs) log.dateKey: log};
  var completions = 0;
  var cursor = evalStart;
  while (!cursor.isAfter(today)) {
    // Count calendar-day completions in the window (matches 26/30 / 51/60).
    final log = byDate[formatHabitDate(cursor)];
    if (log != null && log.completed) completions += 1;
    cursor = cursor.add(const Duration(days: 1));
  }

  final rate = completions / window;
  final eligible =
      completions >= required && rate >= habit.difficulty.successRateThreshold;

  return HabitGraduationEval(
    eligible: eligible,
    windowDays: window,
    completionsInWindow: completions,
    requiredCompletions: required,
    successRate: rate,
    daysTracked: daysTracked,
  );
}

/// True when the last two weekly audits were both SLIPPED (newest first).
bool habitNeedsRelapseSuggestion(List<HabitWeeklyLog> weeklyLogs) {
  if (weeklyLogs.length < 2) return false;
  final sorted = [...weeklyLogs]
    ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
  return sorted[0].status == WeeklyCheckinStatus.slipped &&
      sorted[1].status == WeeklyCheckinStatus.slipped;
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

  // Streak math uses schedule due-days; temporarily treat as daily-active
  // so graduated habits still show historical streak on the card.
  final streakHabit = habit.trackingMode == HabitTrackingMode.dailyActive
      ? habit
      : habit.copyWith(trackingMode: HabitTrackingMode.dailyActive);

  int current = 0;
  var cursor = today;
  if (habitIsDueOn(streakHabit, cursor)) {
    final todayLog = byDate[formatHabitDate(cursor)];
    if (todayLog == null || !todayLog.countsForStreak) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  final created = habitDay(habit.createdAt);
  while (!cursor.isBefore(created)) {
    if (!habitIsDueOn(streakHabit, cursor)) {
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
    if (habitIsDueOn(streakHabit, cursor)) {
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
