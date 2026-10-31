enum PdCharacterEvidenceSource {
  event('event'),
  manualReflection('manual_reflection'),
  weeklyReview('weekly_review'),
  mission('mission');

  const PdCharacterEvidenceSource(this.dbValue);
  final String dbValue;

  static PdCharacterEvidenceSource fromDb(String? value) {
    return PdCharacterEvidenceSource.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => PdCharacterEvidenceSource.manualReflection,
    );
  }

  String get labelHe => switch (this) {
        PdCharacterEvidenceSource.event => 'אירוע Skill',
        PdCharacterEvidenceSource.manualReflection => 'רפלקציה ידנית',
        PdCharacterEvidenceSource.weeklyReview => 'סקירה שבועית',
        PdCharacterEvidenceSource.mission => 'Character Mission',
      };
}

enum PdEvidenceLevel {
  emerging('Emerging', 'מתגבש'),
  developing('Developing', 'בהתפתחות'),
  consistent('Consistent', 'עקבי'),
  strongEvidence('Strong Evidence', 'ראיות חזקות');

  const PdEvidenceLevel(this.labelEn, this.labelHe);
  final String labelEn;
  final String labelHe;
}

enum PdCharacterTrend {
  improving('Improving', '↑ משתפר'),
  stable('Stable', '→ יציב'),
  declining('Declining', '↓ יורד');

  const PdCharacterTrend(this.labelEn, this.labelHe);
  final String labelEn;
  final String labelHe;
}
