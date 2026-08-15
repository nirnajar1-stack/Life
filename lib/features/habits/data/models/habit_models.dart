import '../../domain/models/habit_enums.dart';

class Habit {
  const Habit({
    required this.id,
    required this.title,
    this.description,
    required this.habitType,
    this.targetValue,
    this.unit,
    this.cueTrigger,
    required this.timeOfDay,
    required this.frequency,
    this.customDays = const [],
    this.intervalDays = 1,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    this.freezeDaysAllowedPerMonth = 2,
    this.freezeDaysUsedThisMonth = 0,
    this.freezeMonth,
    this.archived = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final HabitType habitType;
  final double? targetValue;
  final String? unit;
  final String? cueTrigger;
  final HabitTimeOfDay timeOfDay;
  final HabitFrequency frequency;
  final List<int> customDays;
  final int intervalDays;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final int freezeDaysAllowedPerMonth;
  final int freezeDaysUsedThisMonth;
  final DateTime? freezeMonth;
  final bool archived;
  final DateTime createdAt;

  factory Habit.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['custom_days'];
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      habitType: HabitTypeX.fromDb(json['habit_type'] as String?),
      targetValue: (json['target_value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      cueTrigger: json['cue_trigger'] as String?,
      timeOfDay: HabitTimeOfDayX.fromDb(json['time_of_day'] as String?),
      frequency: HabitFrequencyX.fromDb(json['frequency'] as String?),
      customDays: daysRaw is List
          ? daysRaw.map((e) => (e as num).toInt()).toList()
          : const [],
      intervalDays: (json['interval_days'] as num?)?.toInt() ?? 1,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      totalCompletions: (json['total_completions'] as num?)?.toInt() ?? 0,
      freezeDaysAllowedPerMonth:
          (json['freeze_days_allowed_per_month'] as num?)?.toInt() ?? 2,
      freezeDaysUsedThisMonth:
          (json['freeze_days_used_this_month'] as num?)?.toInt() ?? 0,
      freezeMonth: json['freeze_month'] == null
          ? null
          : DateTime.tryParse(json['freeze_month'] as String),
      archived: json['archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'habit_type': habitType.dbValue,
      'target_value': targetValue,
      'unit': unit,
      'cue_trigger': cueTrigger,
      'time_of_day': timeOfDay.dbValue,
      'frequency': frequency.dbValue,
      'custom_days': customDays,
      'interval_days': intervalDays,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_completions': totalCompletions,
      'freeze_days_allowed_per_month': freezeDaysAllowedPerMonth,
      'freeze_days_used_this_month': freezeDaysUsedThisMonth,
      'freeze_month': freezeMonth == null
          ? null
          : '${freezeMonth!.year.toString().padLeft(4, '0')}-${freezeMonth!.month.toString().padLeft(2, '0')}-01',
      'archived': archived,
    };
  }

  Habit copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    HabitType? habitType,
    double? targetValue,
    bool clearTarget = false,
    String? unit,
    bool clearUnit = false,
    String? cueTrigger,
    bool clearCue = false,
    HabitTimeOfDay? timeOfDay,
    HabitFrequency? frequency,
    List<int>? customDays,
    int? intervalDays,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    int? freezeDaysAllowedPerMonth,
    int? freezeDaysUsedThisMonth,
    DateTime? freezeMonth,
    bool? archived,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      habitType: habitType ?? this.habitType,
      targetValue: clearTarget ? null : (targetValue ?? this.targetValue),
      unit: clearUnit ? null : (unit ?? this.unit),
      cueTrigger: clearCue ? null : (cueTrigger ?? this.cueTrigger),
      timeOfDay: timeOfDay ?? this.timeOfDay,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      intervalDays: intervalDays ?? this.intervalDays,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      freezeDaysAllowedPerMonth:
          freezeDaysAllowedPerMonth ?? this.freezeDaysAllowedPerMonth,
      freezeDaysUsedThisMonth:
          freezeDaysUsedThisMonth ?? this.freezeDaysUsedThisMonth,
      freezeMonth: freezeMonth ?? this.freezeMonth,
      archived: archived ?? this.archived,
      createdAt: createdAt,
    );
  }
}

class HabitLog {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.usedFreeze = false,
    this.valueRecorded,
    this.notes,
  });

  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final bool usedFreeze;
  final double? valueRecorded;
  final String? notes;

  String get dateKey => formatHabitDate(date);

  bool get countsForStreak => completed || usedFreeze;

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      date: DateTime.parse(json['log_date'] as String),
      completed: json['completed'] as bool? ?? false,
      usedFreeze: json['used_freeze'] as bool? ?? false,
      valueRecorded: (json['value_recorded'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habit_id': habitId,
      'log_date': formatHabitDate(date),
      'completed': completed,
      'used_freeze': usedFreeze,
      'value_recorded': valueRecorded,
      'notes': notes,
    };
  }
}

String formatHabitDate(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class HabitSnapshot {
  const HabitSnapshot({required this.habit, required this.logs});

  final Habit habit;
  final List<HabitLog> logs;

  HabitLog? logOn(DateTime day) {
    final key = formatHabitDate(day);
    for (final log in logs) {
      if (log.dateKey == key) return log;
    }
    return null;
  }
}
