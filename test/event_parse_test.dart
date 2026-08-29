import 'package:flutter_test/flutter_test.dart';

import 'package:life_app/features/calendar/domain/models/event_parse.dart';

void main() {
  final now = DateTime(2026, 8, 29, 12); // Saturday

  test('parses next Tuesday at 6 as 18:00 doctor visit', () {
    final parsed = parseCalendarEvent(
      'יום שלישי הקרוב בשעה 6 תור לרופא',
      now: now,
    );
    expect(parsed, isNotNull);
    expect(parsed!.title, 'תור לרופא');
    expect(parsed.startsAt, DateTime(2026, 9, 1, 18));
    expect(parsed.endsAt, DateTime(2026, 9, 1, 19));
    expect(parsed.durationMinutes, 60);
    expect(parsed.durationInferred, isTrue);
  });

  test('parses exact slash date and time', () {
    final parsed = parseCalendarEvent(
      '15/9 בשעה 10:30 פגישה',
      now: now,
    );
    expect(parsed, isNotNull);
    expect(parsed!.title, 'פגישה');
    expect(parsed.startsAt, DateTime(2026, 9, 15, 10, 30));
    expect(parsed.endsAt, DateTime(2026, 9, 15, 11, 30));
  });

  test('parses tomorrow with explicit duration', () {
    final parsed = parseCalendarEvent(
      'מחר ב־18 ישיבת צוות שעתיים',
      now: now,
    );
    expect(parsed, isNotNull);
    expect(parsed!.title, 'ישיבת צוות');
    expect(parsed.startsAt, DateTime(2026, 8, 30, 18));
    expect(parsed.endsAt, DateTime(2026, 8, 30, 20));
    expect(parsed.durationInferred, isFalse);
  });

  test('parses Hebrew month morning appointment', () {
    final parsed = parseCalendarEvent(
      '20 בספטמבר בשעה 9 בבוקר בדיקה',
      now: now,
    );
    expect(parsed, isNotNull);
    expect(parsed!.title, 'בדיקה');
    expect(parsed.startsAt, DateTime(2026, 9, 20, 9));
  });

  test('returns null without a date cue', () {
    expect(parseCalendarEvent('רק טקסט בלי תאריך', now: now), isNull);
  });
}
