import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/habits/data/models/habit_models.dart';
import 'package:life_app/features/habits/domain/habit_engine.dart';
import 'package:life_app/features/habits/domain/models/habit_enums.dart';

Habit _habit({
  HabitFrequency frequency = HabitFrequency.daily,
  List<int> customDays = const [],
  int intervalDays = 1,
  DateTime? createdAt,
  int freezeUsed = 0,
  DateTime? freezeMonth,
}) {
  return Habit(
    id: 'h1',
    title: 'Read',
    habitType: HabitType.boolean,
    timeOfDay: HabitTimeOfDay.morning,
    frequency: frequency,
    customDays: customDays,
    intervalDays: intervalDays,
    currentStreak: 0,
    longestStreak: 0,
    totalCompletions: 0,
    freezeDaysUsedThisMonth: freezeUsed,
    freezeMonth: freezeMonth,
    createdAt: createdAt ?? DateTime(2026, 8, 1),
  );
}

HabitLog _log(DateTime day, {bool completed = true, bool freeze = false}) {
  return HabitLog(
    id: formatHabitDate(day),
    habitId: 'h1',
    date: day,
    completed: completed,
    usedFreeze: freeze,
  );
}

void main() {
  test('daily habit is due every day after creation', () {
    final habit = _habit();
    expect(habitIsDueOn(habit, DateTime(2026, 8, 1)), isTrue);
    expect(habitIsDueOn(habit, DateTime(2026, 7, 31)), isFalse);
  });

  test('weekdays skip Saturday', () {
    final habit = _habit(frequency: HabitFrequency.weekdays);
    expect(habitIsDueOn(habit, DateTime(2026, 8, 14)), isTrue); // Friday
    expect(habitIsDueOn(habit, DateTime(2026, 8, 15)), isFalse); // Saturday
  });

  test('specific days honor ISO weekdays', () {
    final habit = _habit(
      frequency: HabitFrequency.specificDays,
      customDays: const [5],
    );
    expect(habitIsDueOn(habit, DateTime(2026, 8, 14)), isTrue);
    expect(habitIsDueOn(habit, DateTime(2026, 8, 13)), isFalse);
  });

  test('interval is counted from created date', () {
    final habit = _habit(
      frequency: HabitFrequency.interval,
      intervalDays: 3,
    );
    expect(habitIsDueOn(habit, DateTime(2026, 8, 1)), isTrue);
    expect(habitIsDueOn(habit, DateTime(2026, 8, 4)), isTrue);
    expect(habitIsDueOn(habit, DateTime(2026, 8, 5)), isFalse);
  });

  test('streak counts completed days and freeze preserves it', () {
    final habit = _habit();
    final logs = [
      _log(DateTime(2026, 8, 13)),
      _log(DateTime(2026, 8, 14), completed: false, freeze: true),
    ];
    final stats = computeHabitStreaks(
      habit: habit,
      logs: logs,
      now: DateTime(2026, 8, 15),
    );
    expect(stats.currentStreak, 2);
    expect(stats.totalCompletions, 1);
    expect(stats.longestStreak, 2);
  });

  test('missed due day breaks the current streak', () {
    final habit = _habit();
    final logs = [_log(DateTime(2026, 8, 13))];
    final stats = computeHabitStreaks(
      habit: habit,
      logs: logs,
      now: DateTime(2026, 8, 15),
    );
    expect(stats.currentStreak, 0);
    expect(stats.longestStreak, 1);
  });

  test('freeze budget resets by month', () {
    final habit = _habit(
      freezeUsed: 2,
      freezeMonth: DateTime(2026, 7),
    );
    expect(canUseHabitFreeze(habit, DateTime(2026, 8, 15)), isTrue);
    expect(
      canUseHabitFreeze(
        habit.copyWith(freezeMonth: DateTime(2026, 8)),
        DateTime(2026, 8, 15),
      ),
      isFalse,
    );
  });
}
