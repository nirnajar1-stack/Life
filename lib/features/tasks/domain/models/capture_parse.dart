class ParsedCapture {
  const ParsedCapture({
    required this.title,
    this.dueDate,
    this.scheduledDate,
    this.eisenhowerDb,
    this.estimatedMinutes,
    this.energyDb,
    this.contextTags = const [],
    this.projectName,
    this.recurrenceRule,
  });

  final String title;
  final DateTime? dueDate;
  final DateTime? scheduledDate;
  final String? eisenhowerDb;
  final int? estimatedMinutes;
  final String? energyDb;
  final List<String> contextTags;
  final String? projectName;
  final String? recurrenceRule;
}

/// Extracts GTD tokens from a single capture line.
/// Example: `Prepare report tomorrow @desk p1 ~45m #ProjectA`
ParsedCapture parseTaskCapture(String raw, {DateTime? now}) {
  var rest = raw.trim();
  final stamp = now ?? DateTime.now();
  final today = DateTime(stamp.year, stamp.month, stamp.day);

  DateTime? due;
  DateTime? scheduled;
  String? eisenhower;
  String? energy;
  int? minutes;
  String? project;
  String? rrule;
  final tags = <String>[];

  DateTime weekdayOnOrAfter(int weekday) {
    final delta = (weekday - today.weekday) % 7;
    return today.add(Duration(days: delta == 0 ? 7 : delta));
  }

  void takeDate(DateTime day) {
    due = DateTime(day.year, day.month, day.day, 18);
    scheduled = DateTime(day.year, day.month, day.day);
  }

  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)(tomorrow|מחר)(?=\s|$)', caseSensitive: false),
    (m) {
      takeDate(today.add(const Duration(days: 1)));
      return ' ';
    },
  );
  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)(today|היום)(?=\s|$)', caseSensitive: false),
    (m) {
      takeDate(today);
      return ' ';
    },
  );
  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)יום\s+ראשון(?=\s|$)', caseSensitive: false),
    (_) {
      takeDate(weekdayOnOrAfter(DateTime.sunday));
      return ' ';
    },
  );
  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)(next\s+week|בשבוע\s+הבא)(?=\s|$)', caseSensitive: false),
    (_) {
      takeDate(today.add(const Duration(days: 7)));
      return ' ';
    },
  );

  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)(p1|דחוף)(?=\s|$)', caseSensitive: false),
    (_) {
      eisenhower = 'P1_DO';
      return ' ';
    },
  );
  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)p2(?=\s|$)', caseSensitive: false),
    (_) {
      eisenhower = 'P2_SCHEDULE';
      return ' ';
    },
  );
  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)p3(?=\s|$)', caseSensitive: false),
    (_) {
      eisenhower = 'P3_DELEGATE';
      return ' ';
    },
  );
  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)p4(?=\s|$)', caseSensitive: false),
    (_) {
      eisenhower = 'P4_ELIMINATE';
      return ' ';
    },
  );

  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)~(\d+)\s*(m|min|ד|דק)?(?=\s|$)', caseSensitive: false),
    (m) {
      minutes = int.tryParse(m.group(1)!);
      return ' ';
    },
  );

  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)@(high|focus|ריכוז)(?=\s|$)', caseSensitive: false),
    (_) {
      energy = 'high_focus';
      return ' ';
    },
  );

  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)(daily|יומי)(?=\s|$)', caseSensitive: false),
    (_) {
      rrule = 'FREQ=DAILY;INTERVAL=1';
      return ' ';
    },
  );
  rest = rest.replaceAllMapped(
    RegExp(r'(?:^|\s)(weekly|שבועי)(?=\s|$)', caseSensitive: false),
    (_) {
      rrule = 'FREQ=WEEKLY;INTERVAL=1';
      return ' ';
    },
  );

  rest = rest.replaceAllMapped(RegExp(r'(?:^|\s)#([^\s]+)'), (m) {
    project = m.group(1);
    return ' ';
  });

  rest = rest.replaceAllMapped(RegExp(r'(?:^|\s)@([^\s]+)'), (m) {
    tags.add('@${m.group(1)}');
    return ' ';
  });

  var title = rest.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (title.length > 120) title = title.substring(0, 120);

  return ParsedCapture(
    title: title,
    dueDate: due,
    scheduledDate: scheduled,
    eisenhowerDb: eisenhower,
    estimatedMinutes: minutes,
    energyDb: energy,
    contextTags: tags,
    projectName: project,
    recurrenceRule: rrule,
  );
}
