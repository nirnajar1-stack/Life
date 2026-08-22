enum RecurrenceMode { weekly, interval }

class RecurrenceConfig {
  const RecurrenceConfig({
    required this.mode,
    this.weekday = DateTime.friday,
    this.interval = 1,
    this.leadDays = 0,
  });

  final RecurrenceMode mode;
  /// Dart weekday: Monday=1 … Sunday=7 (weekly mode).
  final int weekday;
  /// Weeks between occurrences (weekly) or days between occurrences (interval).
  final int interval;
  /// Show the task this many days before the anchor day.
  final int leadDays;

  static const _byDayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  String toRule() {
    switch (mode) {
      case RecurrenceMode.weekly:
        return 'FREQ=WEEKLY;BYDAY=${_weekdayCode(weekday)};'
            'INTERVAL=$interval;LEAD=$leadDays';
      case RecurrenceMode.interval:
        return 'FREQ=DAILY;INTERVAL=$interval;LEAD=$leadDays';
    }
  }

  String get labelHe {
    switch (mode) {
      case RecurrenceMode.weekly:
        final every = interval == 1 ? 'כל' : 'כל $interval שבועות ·';
        return '$every ${_weekdayLabel(weekday)}'
            '${leadDays > 0 ? ' · $leadDays ימים לפני' : ''}';
      case RecurrenceMode.interval:
        return 'כל $interval ימים'
            '${leadDays > 0 ? ' · $leadDays ימים לפני' : ''}';
    }
  }

  static RecurrenceConfig? fromRule(String? rule) {
    if (rule == null || rule.trim().isEmpty) return null;
    final parts = <String, String>{};
    for (final chunk in rule.split(';')) {
      final pair = chunk.split('=');
      if (pair.length == 2) {
        parts[pair[0].trim().toUpperCase()] = pair[1].trim().toUpperCase();
      }
    }

    final freq = parts['FREQ'];
    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final lead = int.tryParse(parts['LEAD'] ?? '0') ?? 0;

    if (freq == 'WEEKLY') {
      final weekday = _weekdayFromCode(parts['BYDAY'] ?? 'MO');
      return RecurrenceConfig(
        mode: RecurrenceMode.weekly,
        weekday: weekday,
        interval: interval < 1 ? 1 : interval,
        leadDays: lead < 0 ? 0 : lead,
      );
    }

    if (freq == 'DAILY') {
      return RecurrenceConfig(
        mode: RecurrenceMode.interval,
        interval: interval < 1 ? 1 : interval,
        leadDays: lead < 0 ? 0 : lead,
      );
    }

    return null;
  }

  /// First due date when creating a recurring task from [start] (usually today).
  DateTime firstDueFrom(DateTime start) {
    final today = _dayOnly(start);
    switch (mode) {
      case RecurrenceMode.weekly:
        return _weeklyDueOnOrAfter(today, weekday, interval, leadDays);
      case RecurrenceMode.interval:
        final anchor = today.add(Duration(days: interval));
        return anchor.subtract(Duration(days: leadDays));
    }
  }

  /// Next due date after completing a task that was due on [currentDue].
  DateTime nextDueAfter(DateTime currentDue) {
    final due = _dayOnly(currentDue);
    switch (mode) {
      case RecurrenceMode.weekly:
        final anchor = due.add(Duration(days: leadDays));
        final nextAnchor = anchor.add(Duration(days: 7 * interval));
        return nextAnchor.subtract(Duration(days: leadDays));
      case RecurrenceMode.interval:
        final anchor = due.add(Duration(days: leadDays));
        final nextAnchor = anchor.add(Duration(days: interval));
        return nextAnchor.subtract(Duration(days: leadDays));
    }
  }

  static DateTime _weeklyDueOnOrAfter(
    DateTime start,
    int weekday,
    int weekInterval,
    int leadDays,
  ) {
    var anchor = _nextWeekdayOnOrAfter(start, weekday);
    var due = anchor.subtract(Duration(days: leadDays));
    if (due.isBefore(start)) {
      anchor = anchor.add(Duration(days: 7 * weekInterval));
      while (anchor.weekday != weekday) {
        anchor = anchor.add(const Duration(days: 1));
      }
      due = anchor.subtract(Duration(days: leadDays));
    }
    return due;
  }

  static DateTime _nextWeekdayOnOrAfter(DateTime from, int weekday) {
    var cursor = _dayOnly(from);
    while (cursor.weekday != weekday) {
      cursor = cursor.add(const Duration(days: 1));
    }
    return cursor;
  }

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _weekdayCode(int weekday) =>
      _byDayCodes[(weekday.clamp(1, 7)) - 1];

  static int _weekdayFromCode(String code) {
    final index = _byDayCodes.indexOf(code.toUpperCase());
    return index >= 0 ? index + 1 : DateTime.monday;
  }

  static String _weekdayLabel(int weekday) {
    const labels = [
      'שני',
      'שלישי',
      'רביעי',
      'חמישי',
      'שישי',
      'שבת',
      'ראשון',
    ];
    return labels[(weekday.clamp(1, 7)) - 1];
  }
}

DateTime? nextRecurrenceDate(String? rule, DateTime from) {
  final config = RecurrenceConfig.fromRule(rule);
  if (config == null) return null;
  return config.nextDueAfter(from);
}

String? recurrenceLabel(String? rule) =>
    RecurrenceConfig.fromRule(rule)?.labelHe;
