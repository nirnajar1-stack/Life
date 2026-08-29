import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/habit_models.dart';
import '../../data/repositories/habit_repository.dart';
import '../habit_engine.dart';
import '../models/habit_enums.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.watch(supabaseClientProvider));
});

final habitsControllerProvider =
    StateNotifierProvider<HabitsController, AsyncValue<List<HabitSnapshot>>>(
        (ref) {
  return HabitsController(ref);
});

final todaysHabitsProvider = Provider<List<HabitSnapshot>>((ref) {
  final today = DateTime.now();
  return ref.watch(habitsControllerProvider).valueOrNull?.where((snapshot) {
        return habitIsDueOn(snapshot.habit, today);
      }).toList() ??
      const [];
});

final dailyActiveHabitsProvider = Provider<List<HabitSnapshot>>((ref) {
  return ref.watch(habitsControllerProvider).valueOrNull?.where((snapshot) {
        return snapshot.habit.isDailyActive;
      }).toList() ??
      const [];
});

final graduatedHabitsProvider = Provider<List<HabitSnapshot>>((ref) {
  return ref.watch(habitsControllerProvider).valueOrNull?.where((snapshot) {
        return snapshot.habit.isWeeklyMaintenance;
      }).toList() ??
      const [];
});

class HabitsController extends StateNotifier<AsyncValue<List<HabitSnapshot>>> {
  HabitsController(this._ref) : super(const AsyncLoading()) {
    reload();
  }

  final Ref _ref;
  HabitRepository get _repo => _ref.read(habitRepositoryProvider);

  Future<void> reload() async {
    try {
      final items = await _repo.fetchActiveSnapshots();
      if (!mounted) return;
      state = AsyncData(items);
    } catch (error, stack) {
      if (!mounted) return;
      state = AsyncError(error, stack);
    }
  }

  List<HabitSnapshot> get _items => state.valueOrNull ?? const [];

  Future<void> create(Habit habit) async {
    final previous = _items;
    try {
      final saved = await _repo.insertHabit(habit);
      if (!mounted) return;
      state = AsyncData([
        ...previous,
        HabitSnapshot(habit: saved, logs: const []),
      ]);
    } catch (_) {
      if (!mounted) return;
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> update(Habit habit) async {
    final previous = _items;
    state = AsyncData([
      for (final item in previous)
        if (item.habit.id == habit.id)
          HabitSnapshot(
            habit: habit,
            logs: item.logs,
            weeklyLogs: item.weeklyLogs,
          )
        else
          item,
    ]);
    try {
      await _repo.updateHabit(habit);
    } catch (_) {
      if (!mounted) return;
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> archive(String id) async {
    final previous = _items;
    state = AsyncData(previous.where((item) => item.habit.id != id).toList());
    try {
      await _repo.archiveHabit(id);
    } catch (_) {
      if (!mounted) return;
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> graduate(HabitSnapshot snapshot) async {
    final previous = _items;
    try {
      final updated = await _repo.graduateHabit(snapshot.habit);
      if (!mounted) return;
      state = AsyncData([
        for (final item in previous)
          if (item.habit.id == snapshot.habit.id)
            HabitSnapshot(
              habit: updated,
              logs: item.logs,
              weeklyLogs: item.weeklyLogs,
            )
          else
            item,
      ]);
    } catch (_) {
      if (!mounted) return;
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reactivate(HabitSnapshot snapshot) async {
    final previous = _items;
    try {
      final updated = await _repo.reactivateHabit(snapshot.habit);
      if (!mounted) return;
      state = AsyncData([
        for (final item in previous)
          if (item.habit.id == snapshot.habit.id)
            HabitSnapshot(
              habit: updated,
              logs: item.logs,
              weeklyLogs: item.weeklyLogs,
            )
          else
            item,
      ]);
    } catch (_) {
      if (!mounted) return;
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> submitWeeklyCheckin({
    required HabitSnapshot snapshot,
    required WeeklyCheckinStatus status,
    DateTime? weekStart,
    String? notes,
  }) async {
    final previous = _items;
    final start = habitWeekStart(weekStart ?? DateTime.now());
    try {
      final saved = await _repo.upsertWeeklyLog(
        habitId: snapshot.habit.id,
        weekStart: start,
        status: status,
        notes: notes,
      );
      if (!mounted) return;
      final nextWeekly = [
        saved,
        ...snapshot.weeklyLogs.where(
          (log) => formatHabitDate(log.weekStartDate) != formatHabitDate(start),
        ),
      ];
      state = AsyncData([
        for (final item in previous)
          if (item.habit.id == snapshot.habit.id)
            HabitSnapshot(
              habit: item.habit,
              logs: item.logs,
              weeklyLogs: nextWeekly,
            )
          else
            item,
      ]);
    } catch (_) {
      if (!mounted) return;
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> logToday({
    required HabitSnapshot snapshot,
    required bool completed,
    bool usedFreeze = false,
    double? valueRecorded,
    DateTime? day,
  }) async {
    final previous = _items;
    final targetDay = day ?? DateTime.now();
    final freeze = usedFreeze &&
        !completed &&
        canUseHabitFreeze(snapshot.habit, targetDay);
    try {
      final next = await _repo.upsertLog(
        snapshot: snapshot,
        day: targetDay,
        completed: completed,
        usedFreeze: freeze,
        valueRecorded: valueRecorded,
      );
      if (!mounted) return;
      state = AsyncData([
        for (final item in previous)
          if (item.habit.id == snapshot.habit.id) next else item,
      ]);
    } catch (_) {
      if (!mounted) return;
      state = AsyncData(previous);
      rethrow;
    }
  }
}
