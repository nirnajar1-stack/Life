/// Result of parsing a free-text Hebrew/English calendar request.
class ParsedCalendarEvent {
  const ParsedCalendarEvent({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.durationMinutes,
    required this.timeInferred,
    required this.durationInferred,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final int durationMinutes;
  final bool timeInferred;
  final bool durationInferred;
}

/// Parses natural-language calendar messages for Telegram / in-app capture.
///
/// Examples:
/// - `יום שלישי הקרוב בשעה 6 תור לרופא`
/// - `15/9 בשעה 10:30 פגישה עם רואה חשבון`
/// - `מחר ב־18 פגישת צוות שעתיים`
ParsedCalendarEvent? parseCalendarEvent(String raw, {DateTime? now}) {
  final stamp = now ?? DateTime.now();
  var text = raw.trim();
  if (text.isEmpty) return null;

  final today = DateTime(stamp.year, stamp.month, stamp.day);
  DateTime? day;
  int? hour;
  int minute = 0;
  var durationMinutes = 60;
  var timeInferred = true;
  var durationInferred = true;
  var forceEvening = false;
  var forceMorning = false;

  if (RegExp(r'(בערב|בלילה|אחה[\"״]?צ|אחר\s*הצהריים)').hasMatch(text)) {
    forceEvening = true;
  }
  if (RegExp(r'בבוקר').hasMatch(text)) {
    forceMorning = true;
  }

  // Duration first so leftovers become the title cleanly.
  text = text.replaceAllMapped(
    RegExp(r'(?:^|\s)(?:למשך\s+)?(\d+)\s*(שעות|שעה|דקות|דק|ד)(?=\s|$)'),
    (m) {
      durationInferred = false;
      final n = int.parse(m.group(1)!);
      final unit = m.group(2)!;
      durationMinutes = unit.startsWith('שע') ? n * 60 : n;
      return ' ';
    },
  );
  text = text.replaceAllMapped(
    RegExp(r'(?:^|\s)(שעתיים)(?=\s|$)'),
    (_) {
      durationInferred = false;
      durationMinutes = 120;
      return ' ';
    },
  );
  text = text.replaceAllMapped(
    RegExp(r'(?:^|\s)(שעה\s+אחת|שעה)(?=\s|$)'),
    (_) {
      durationInferred = false;
      durationMinutes = 60;
      return ' ';
    },
  );
  text = text.replaceAllMapped(
    RegExp(
      r'(?:^|\s)(?:for\s+)?(\d+)\s*(h|hr|hrs|hours?|m|min|mins|minutes?)(?=\s|$)',
      caseSensitive: false,
    ),
    (m) {
      durationInferred = false;
      final n = int.parse(m.group(1)!);
      final unit = m.group(2)!.toLowerCase();
      durationMinutes = unit.startsWith('h') ? n * 60 : n;
      return ' ';
    },
  );

  // Exact dates: 15/9/2026, 15/9, 15.9.2026, 15.9
  text = text.replaceAllMapped(
    RegExp(r'(?:^|\s)(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?(?=\s|$)'),
    (m) {
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      var y = m.group(3) == null ? stamp.year : int.parse(m.group(3)!);
      if (y < 100) y += 2000;
      var candidate = DateTime(y, mo, d);
      if (m.group(3) == null && candidate.isBefore(today)) {
        candidate = DateTime(y + 1, mo, d);
      }
      day = candidate;
      return ' ';
    },
  );

  // Hebrew month: 15 בספטמבר / ב־20 לאוקטובר
  const months = <String, int>{
    'ינואר': 1,
    'פברואר': 2,
    'מרץ': 3,
    'אפריל': 4,
    'מאי': 5,
    'יוני': 6,
    'יולי': 7,
    'אוגוסט': 8,
    'ספטמבר': 9,
    'אוקטובר': 10,
    'נובמבר': 11,
    'דצמבר': 12,
  };
  for (final entry in months.entries) {
    // 20 בספטמבר | ב־20 לספטמבר | 20 לאוקטובר 2026
    final re = RegExp(
      '(?:^|\\s)(?:ב[־\\-]?\\s*)?(\\d{1,2})\\s*(?:ב|ל)?\\s*${entry.key}(?:\\s+(\\d{4}))?(?=\\s|\$)',
    );
    text = text.replaceAllMapped(re, (m) {
      final d = int.parse(m.group(1)!);
      final y = m.group(2) == null ? stamp.year : int.parse(m.group(2)!);
      var candidate = DateTime(y, entry.value, d);
      if (m.group(2) == null && candidate.isBefore(today)) {
        candidate = DateTime(y + 1, entry.value, d);
      }
      day = candidate;
      return ' ';
    });
  }

  // Relative days
  text = text.replaceAllMapped(
    RegExp(r'(?:^|\s)(מחר|tomorrow)(?=\s|$)', caseSensitive: false),
    (_) {
      day = today.add(const Duration(days: 1));
      return ' ';
    },
  );
  text = text.replaceAllMapped(
    RegExp(r'(?:^|\s)(היום|today)(?=\s|$)', caseSensitive: false),
    (_) {
      day = today;
      return ' ';
    },
  );
  text = text.replaceAllMapped(
    RegExp(r'(?:^|\s)(?:עוד|בעוד)\s+(\d+)\s*ימים?(?=\s|$)'),
    (m) {
      day = today.add(Duration(days: int.parse(m.group(1)!)));
      return ' ';
    },
  );

  // Weekdays (Hebrew)
  const weekdayMap = <String, int>{
    'ראשון': DateTime.sunday,
    'שני': DateTime.monday,
    'שלישי': DateTime.tuesday,
    'רביעי': DateTime.wednesday,
    'חמישי': DateTime.thursday,
    'שישי': DateTime.friday,
    'שבת': DateTime.saturday,
  };
  for (final entry in weekdayMap.entries) {
    final re = RegExp(
      '(?:^|\\s)(?:ביום|יום)?\\s*${entry.key}(?:\\s+הקרוב)?(?=\\s|\$)',
    );
    text = text.replaceAllMapped(re, (_) {
      day = _nextWeekday(today, entry.value, stamp);
      return ' ';
    });
  }

  // English weekdays
  const enWeekdays = <String, int>{
    'sunday': DateTime.sunday,
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
  };
  for (final entry in enWeekdays.entries) {
    final re = RegExp(
      '(?:^|\\s)(?:next\\s+)?${entry.key}(?=\\s|\$)',
      caseSensitive: false,
    );
    text = text.replaceAllMapped(re, (_) {
      day = _nextWeekday(today, entry.value, stamp);
      return ' ';
    });
  }

  // Time: בשעה 6 / בשעה 18:30 / ב־18 / at 6pm
  text = text.replaceAllMapped(
    RegExp(
      r'(?:^|\s)(?:בשעה|ב[־\-]?|at)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm|בערב|בבוקר)?(?=\s|$)',
      caseSensitive: false,
    ),
    (m) {
      timeInferred = false;
      hour = int.parse(m.group(1)!);
      minute = m.group(2) == null ? 0 : int.parse(m.group(2)!);
      final suffix = (m.group(3) ?? '').toLowerCase();
      if (suffix == 'pm' || suffix == 'בערב') {
        if (hour! < 12) hour = hour! + 12;
      } else if (suffix == 'am' || suffix == 'בבוקר') {
        if (hour == 12) hour = 0;
      }
      return ' ';
    },
  );

  // Strip leftover time-of-day words
  text = text.replaceAll(
    RegExp(r'(?:^|\s)(בערב|בבוקר|בלילה|אחה[\"״]?צ|אחר\s*הצהריים)(?=\s|$)'),
    ' ',
  );

  if (day == null) return null;

  if (hour == null) {
    hour = 9;
    minute = 0;
    timeInferred = true;
  } else if (!forceMorning &&
      (forceEvening || hour! <= 7) &&
      hour! < 12 &&
      hour! > 0) {
    // Israeli habit: "בשעה 6" for appointments usually means 18:00.
    hour = hour! + 12;
  }

  if (hour! > 23 || minute > 59 || durationMinutes <= 0) return null;

  final startsAt = DateTime(day!.year, day!.month, day!.day, hour!, minute);
  final endsAt = startsAt.add(Duration(minutes: durationMinutes));

  var title = text
      .replaceAll(RegExp(r'[־\-–]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (title.isEmpty) title = 'אירוע';
  if (title.length > 120) title = title.substring(0, 120);

  return ParsedCalendarEvent(
    title: title,
    startsAt: startsAt,
    endsAt: endsAt,
    durationMinutes: durationMinutes,
    timeInferred: timeInferred,
    durationInferred: durationInferred,
  );
}

DateTime _nextWeekday(DateTime today, int weekday, DateTime now) {
  var delta = (weekday - today.weekday) % 7;
  if (delta == 0) {
    // Same weekday: keep today if evening slot might still be ahead; else +7.
    // Caller applies the concrete hour later — prefer today when message is
    // sent before 21:00, otherwise roll to next week.
    if (now.hour >= 21) delta = 7;
  }
  return today.add(Duration(days: delta));
}
