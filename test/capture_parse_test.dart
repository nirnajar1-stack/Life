import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/features/tasks/domain/models/capture_parse.dart';

void main() {
  test('parses GTD capture tokens', () {
    final parsed = parseTaskCapture(
      'Prepare quarterly report tomorrow @desk p1 ~45m #ProjectA',
      now: DateTime(2026, 8, 15),
    );
    expect(parsed.title, 'Prepare quarterly report');
    expect(parsed.eisenhowerDb, 'P1_DO');
    expect(parsed.estimatedMinutes, 45);
    expect(parsed.contextTags, ['@desk']);
    expect(parsed.projectName, 'ProjectA');
    expect(parsed.scheduledDate, DateTime(2026, 8, 16));
  });

  test('requires only a title', () {
    final parsed = parseTaskCapture('לקנות חלב');
    expect(parsed.title, 'לקנות חלב');
    expect(parsed.eisenhowerDb, isNull);
  });
}
