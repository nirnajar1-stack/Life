enum PdEventType {
  realWorld('real_world'),
  practice('practice'),
  drill('drill');

  const PdEventType(this.dbValue);
  final String dbValue;

  static PdEventType fromDb(String? value) {
    return PdEventType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => PdEventType.realWorld,
    );
  }

  String get labelHe => switch (this) {
        PdEventType.realWorld => 'אירוע אמיתי',
        PdEventType.practice => 'תרגול',
        PdEventType.drill => 'Drill',
      };
}

enum PdContextLevel {
  low('low'),
  medium('medium'),
  high('high');

  const PdContextLevel(this.dbValue);
  final String dbValue;

  static PdContextLevel? fromDb(String? value) {
    if (value == null) return null;
    for (final level in PdContextLevel.values) {
      if (level.dbValue == value) return level;
    }
    return null;
  }

  String get labelHe => switch (this) {
        PdContextLevel.low => 'נמוך',
        PdContextLevel.medium => 'בינוני',
        PdContextLevel.high => 'גבוה',
      };
}

enum PdSafetyLevel {
  safe('safe'),
  uncertain('uncertain'),
  unsafe('unsafe');

  const PdSafetyLevel(this.dbValue);
  final String dbValue;

  static PdSafetyLevel? fromDb(String? value) {
    if (value == null) return null;
    for (final level in PdSafetyLevel.values) {
      if (level.dbValue == value) return level;
    }
    return null;
  }

  String get labelHe => switch (this) {
        PdSafetyLevel.safe => 'בטוח',
        PdSafetyLevel.uncertain => 'לא ודאי',
        PdSafetyLevel.unsafe => 'לא בטוח',
      };
}
