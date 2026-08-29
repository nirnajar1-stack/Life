import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/habit_engine.dart';
import '../../domain/models/habit_enums.dart';
import '../models/habit_models.dart';

class HabitRepository {
  HabitRepository(this._client);

  final SupabaseClient _client;

  Future<List<HabitSnapshot>> fetchActiveSnapshots() async {
    final habitRows = await _client
        .from('habits')
        .select()
        .eq('archived', false)
        .order('created_at');
    final habits = (habitRows as List)
        .map((row) => Habit.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    if (habits.isEmpty) return const [];

    final ids = habits.map((h) => h.id).toList();
    final logRows = await _client
        .from('habit_logs')
        .select()
        .inFilter('habit_id', ids)
        .order('log_date');
    final logs = (logRows as List)
        .map((row) => HabitLog.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();

    final weeklyRows = await _client
        .from('habit_weekly_logs')
        .select()
        .inFilter('habit_id', ids)
        .order('week_start_date', ascending: false);
    final weeklyLogs = (weeklyRows as List)
        .map(
          (row) =>
              HabitWeeklyLog.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();

    return [
      for (final habit in habits)
        HabitSnapshot(
          habit: habit,
          logs: logs.where((log) => log.habitId == habit.id).toList(),
          weeklyLogs:
              weeklyLogs.where((log) => log.habitId == habit.id).toList(),
        ),
    ];
  }

  Future<Habit> insertHabit(Habit habit) async {
    final row =
        await _client.from('habits').insert(habit.toJson()).select().single();
    return Habit.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> updateHabit(Habit habit) async {
    await _client.from('habits').update(habit.toJson()).eq('id', habit.id);
  }

  Future<void> archiveHabit(String id) async {
    await _client.from('habits').update({
      'archived': true,
      'tracking_mode': HabitTrackingMode.archived.dbValue,
    }).eq('id', id);
  }

  Future<Habit> graduateHabit(Habit habit, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    final updated = habit.copyWith(
      trackingMode: HabitTrackingMode.weeklyMaintenance,
      graduatedAt: when,
      archived: false,
    );
    await updateHabit(updated);
    return updated;
  }

  Future<Habit> reactivateHabit(Habit habit, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    final updated = habit.copyWith(
      trackingMode: HabitTrackingMode.dailyActive,
      lastRelapsedAt: when,
      archived: false,
    );
    await updateHabit(updated);
    return updated;
  }

  Future<HabitWeeklyLog> upsertWeeklyLog({
    required String habitId,
    required DateTime weekStart,
    required WeeklyCheckinStatus status,
    String? notes,
  }) async {
    final row = await _client
        .from('habit_weekly_logs')
        .upsert(
          {
            'habit_id': habitId,
            'week_start_date': formatHabitDate(habitWeekStart(weekStart)),
            'status': status.dbValue,
            'notes': notes,
          },
          onConflict: 'habit_id,week_start_date',
        )
        .select()
        .single();
    return HabitWeeklyLog.fromJson(Map<String, dynamic>.from(row));
  }

  Future<HabitSnapshot> upsertLog({
    required HabitSnapshot snapshot,
    required DateTime day,
    required bool completed,
    bool usedFreeze = false,
    double? valueRecorded,
    String? notes,
  }) async {
    final key = formatHabitDate(day);
    await _client.from('habit_logs').upsert(
      {
        'habit_id': snapshot.habit.id,
        'log_date': key,
        'completed': completed,
        'used_freeze': usedFreeze && !completed,
        'value_recorded': valueRecorded,
        'notes': notes,
      },
      onConflict: 'habit_id,log_date',
    );

    final logRows = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', snapshot.habit.id)
        .order('log_date');
    final logs = (logRows as List)
        .map((row) => HabitLog.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    final stats = computeHabitStreaks(
      habit: snapshot.habit,
      logs: logs,
      now: DateTime.now(),
    );
    final monthStart = DateTime(day.year, day.month);
    final sameMonth = snapshot.habit.freezeMonth != null &&
        snapshot.habit.freezeMonth!.year == monthStart.year &&
        snapshot.habit.freezeMonth!.month == monthStart.month;
    var freezeUsed = sameMonth ? snapshot.habit.freezeDaysUsedThisMonth : 0;
    final previous = snapshot.logOn(day);
    final applyingFreeze = usedFreeze && !completed;
    if (applyingFreeze && (previous == null || !previous.usedFreeze)) {
      freezeUsed += 1;
    }

    final updated = snapshot.habit.copyWith(
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      totalCompletions: stats.totalCompletions,
      freezeDaysUsedThisMonth: freezeUsed,
      freezeMonth: monthStart,
    );
    await updateHabit(updated);
    return HabitSnapshot(
      habit: updated,
      logs: logs,
      weeklyLogs: snapshot.weeklyLogs,
    );
  }
}
