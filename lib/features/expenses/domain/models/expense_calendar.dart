/// Calendar-date helpers for expense ledger / analytics.
///
/// Recurring and installment charges are stored as **date-only** timestamps
/// at midnight UTC (e.g. `2026-10-01T00:00:00+00`). In US timezones that
/// instant falls on the previous local evening, so naive
/// `DateTime(year, month)` local filters drop them from the target month.
///
/// Rule:
/// - UTC midnight (date-only charges) → trust the **UTC** Y/M/D
/// - Any other timestamp → trust the device **local** Y/M/D (receipt times)
DateTime expenseCalendarDate(DateTime value) {
  final utc = value.toUtc();
  final isDateOnly = utc.hour == 0 &&
      utc.minute == 0 &&
      utc.second == 0 &&
      utc.millisecond == 0 &&
      utc.microsecond == 0;
  if (isDateOnly) {
    return DateTime(utc.year, utc.month, utc.day);
  }
  return DateTime(value.year, value.month, value.day);
}

/// Local (non-UTC) midnight for [year]-[month]-[day] — used as month bounds
/// together with [expenseCalendarDate] comparisons.
DateTime expenseMonthStart(int year, int month) => DateTime(year, month);

DateTime expenseMonthEndExclusive(int year, int month) =>
    DateTime(year, month + 1);

bool expenseInMonth(DateTime value, DateTime monthStart) {
  final day = expenseCalendarDate(value);
  return day.year == monthStart.year && day.month == monthStart.month;
}

bool expenseInRange(
  DateTime value, {
  DateTime? startInclusive,
  DateTime? endExclusive,
}) {
  final day = expenseCalendarDate(value);
  if (startInclusive != null) {
    final start = DateTime(startInclusive.year, startInclusive.month, startInclusive.day);
    if (day.isBefore(start)) return false;
  }
  if (endExclusive != null) {
    final end = DateTime(endExclusive.year, endExclusive.month, endExclusive.day);
    if (!day.isBefore(end)) return false;
  }
  return true;
}

/// Canonical timestamp for a calendar charge day (noon UTC) so every
/// timezone keeps the same Y/M/D.
DateTime expenseChargeTimestamp(int year, int month, int day) =>
    DateTime.utc(year, month, day, 12);
