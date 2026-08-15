enum HabitFrequency { daily, weekdays, specificDays, interval }

enum HabitTimeOfDay { morning, afternoon, evening, anytime }

enum HabitType { boolean, measurable }

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
