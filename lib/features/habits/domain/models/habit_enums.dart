enum HabitFrequency { daily, weekdays, specificDays, interval }

enum HabitTimeOfDay { morning, afternoon, evening, anytime }

enum HabitType { boolean, measurable }

enum HabitDifficulty { easy, hard }

enum HabitTrackingMode { dailyActive, weeklyMaintenance, archived }

enum WeeklyCheckinStatus { perfect, good, slipped }

extension HabitDifficultyX on HabitDifficulty {
  String get dbValue => this == HabitDifficulty.hard ? 'HARD' : 'EASY';

  String get labelHe => this == HabitDifficulty.hard ? 'קשה' : 'קל';

  /// Minimum calendar-day window before graduation can be evaluated.
  int get evaluationWindowDays => this == HabitDifficulty.hard ? 60 : 30;

  /// Required success rate inside the evaluation window (0–1).
  double get successRateThreshold => 0.85;

  int get minCompletionsForGraduation {
    final window = evaluationWindowDays;
    return (window * successRateThreshold).ceil();
  }

  static HabitDifficulty fromDb(String? raw) =>
      raw == 'HARD' ? HabitDifficulty.hard : HabitDifficulty.easy;
}

extension HabitTrackingModeX on HabitTrackingMode {
  String get dbValue {
    switch (this) {
      case HabitTrackingMode.dailyActive:
        return 'DAILY_ACTIVE';
      case HabitTrackingMode.weeklyMaintenance:
        return 'WEEKLY_MAINTENANCE';
      case HabitTrackingMode.archived:
        return 'ARCHIVED';
    }
  }

  String get labelHe {
    switch (this) {
      case HabitTrackingMode.dailyActive:
        return 'מעקב יומי';
      case HabitTrackingMode.weeklyMaintenance:
        return 'תחזוקה שבועית';
      case HabitTrackingMode.archived:
        return 'בארכיון';
    }
  }

  static HabitTrackingMode fromDb(String? raw) {
    switch (raw) {
      case 'WEEKLY_MAINTENANCE':
        return HabitTrackingMode.weeklyMaintenance;
      case 'ARCHIVED':
        return HabitTrackingMode.archived;
      default:
        return HabitTrackingMode.dailyActive;
    }
  }
}

extension WeeklyCheckinStatusX on WeeklyCheckinStatus {
  String get dbValue {
    switch (this) {
      case WeeklyCheckinStatus.perfect:
        return 'PERFECT';
      case WeeklyCheckinStatus.good:
        return 'GOOD';
      case WeeklyCheckinStatus.slipped:
        return 'SLIPPED';
    }
  }

  String get labelHe {
    switch (this) {
      case WeeklyCheckinStatus.perfect:
        return 'מושלם (7/7)';
      case WeeklyCheckinStatus.good:
        return 'טוב (5–6/7)';
      case WeeklyCheckinStatus.slipped:
        return 'החלקה (<4/7)';
    }
  }

  static WeeklyCheckinStatus fromDb(String? raw) {
    switch (raw) {
      case 'GOOD':
        return WeeklyCheckinStatus.good;
      case 'SLIPPED':
        return WeeklyCheckinStatus.slipped;
      default:
        return WeeklyCheckinStatus.perfect;
    }
  }
}

extension HabitFrequencyX on HabitFrequency {
  String get dbValue {
    switch (this) {
      case HabitFrequency.daily:
        return 'daily';
      case HabitFrequency.weekdays:
        return 'weekdays';
      case HabitFrequency.specificDays:
        return 'specific_days';
      case HabitFrequency.interval:
        return 'interval';
    }
  }

  String get labelHe {
    switch (this) {
      case HabitFrequency.daily:
        return 'כל יום';
      case HabitFrequency.weekdays:
        return 'ימים א׳–ה׳';
      case HabitFrequency.specificDays:
        return 'ימים נבחרים';
      case HabitFrequency.interval:
        return 'כל N ימים';
    }
  }

  static HabitFrequency fromDb(String? raw) {
    switch (raw) {
      case 'weekdays':
        return HabitFrequency.weekdays;
      case 'specific_days':
        return HabitFrequency.specificDays;
      case 'interval':
        return HabitFrequency.interval;
      default:
        return HabitFrequency.daily;
    }
  }
}

extension HabitTimeOfDayX on HabitTimeOfDay {
  String get dbValue {
    switch (this) {
      case HabitTimeOfDay.morning:
        return 'morning';
      case HabitTimeOfDay.afternoon:
        return 'afternoon';
      case HabitTimeOfDay.evening:
        return 'evening';
      case HabitTimeOfDay.anytime:
        return 'anytime';
    }
  }

  String get labelHe {
    switch (this) {
      case HabitTimeOfDay.morning:
        return 'בוקר';
      case HabitTimeOfDay.afternoon:
        return 'צהריים';
      case HabitTimeOfDay.evening:
        return 'ערב';
      case HabitTimeOfDay.anytime:
        return 'גמיש';
    }
  }

  /// Hour used when overlaying the habit on the timeblocking calendar.
  int? get calendarHour {
    switch (this) {
      case HabitTimeOfDay.morning:
        return 8;
      case HabitTimeOfDay.afternoon:
        return 13;
      case HabitTimeOfDay.evening:
        return 19;
      case HabitTimeOfDay.anytime:
        return null;
    }
  }

  static HabitTimeOfDay fromDb(String? raw) {
    switch (raw) {
      case 'morning':
        return HabitTimeOfDay.morning;
      case 'afternoon':
        return HabitTimeOfDay.afternoon;
      case 'evening':
        return HabitTimeOfDay.evening;
      default:
        return HabitTimeOfDay.anytime;
    }
  }
}

extension HabitTypeX on HabitType {
  String get dbValue => this == HabitType.measurable ? 'measurable' : 'boolean';

  static HabitType fromDb(String? raw) =>
      raw == 'measurable' ? HabitType.measurable : HabitType.boolean;
}
