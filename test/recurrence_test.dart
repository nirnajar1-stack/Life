import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/tasks/domain/models/recurrence.dart';

void main() {
  group('RecurrenceConfig weekly with lead', () {
    test('first due from Monday for Friday event with 2-day lead is Wednesday', () {
      final config = RecurrenceConfig(
        mode: RecurrenceMode.weekly,
        weekday: DateTime.friday,
        leadDays: 2,
      );
      // Monday 2026-08-17
      final due = config.firstDueFrom(DateTime(2026, 8, 17));
      expect(due.weekday, DateTime.wednesday);
      expect(due.day, 19);
    });

    test('next due after completion advances one week', () {
      final config = RecurrenceConfig(
        mode: RecurrenceMode.weekly,
        weekday: DateTime.friday,
        leadDays: 2,
      );
      final next = config.nextDueAfter(DateTime(2026, 8, 19));
      expect(next.day, 26);
      expect(next.weekday, DateTime.wednesday);
    });
  });

  group('RecurrenceConfig interval', () {
    test('every 7 days from today', () {
      final config = RecurrenceConfig(
        mode: RecurrenceMode.interval,
        interval: 7,
      );
      final due = config.firstDueFrom(DateTime(2026, 8, 17));
      expect(due.day, 24);
    });

    test('next interval due adds 7 days', () {
      final config = RecurrenceConfig(
        mode: RecurrenceMode.interval,
        interval: 7,
      );
      final next = config.nextDueAfter(DateTime(2026, 8, 24));
      expect(next.day, 31);
    });
  });
}
