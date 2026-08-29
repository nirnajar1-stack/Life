import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/models/calendar_event_model.dart';
import '../../data/repositories/calendar_repository.dart';
import '../models/event_parse.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(supabaseClientProvider));
});

final upcomingCalendarEventsProvider =
    AsyncNotifierProvider<UpcomingCalendarEventsController,
        List<CalendarEventModel>>(UpcomingCalendarEventsController.new);

class UpcomingCalendarEventsController
    extends AsyncNotifier<List<CalendarEventModel>> {
  @override
  Future<List<CalendarEventModel>> build() {
    return ref.read(calendarRepositoryProvider).fetchUpcoming();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(calendarRepositoryProvider).fetchUpcoming(),
    );
  }

  Future<CalendarEventModel> addFromText(String raw) async {
    final parsed = parseCalendarEvent(raw);
    if (parsed == null) {
      throw ArgumentError(
        'לא הצלחתי להבין תאריך/שעה. נסו למשל: יום שלישי בשעה 6 תור לרופא',
      );
    }
    final now = DateTime.now();
    final event = CalendarEventModel(
      id: '',
      title: parsed.title,
      startsAt: parsed.startsAt,
      endsAt: parsed.endsAt,
      source: 'app',
      rawText: raw.trim(),
      createdAt: now,
      updatedAt: now,
    );
    final saved = await ref.read(calendarRepositoryProvider).insertEvent(event);
    await reload();
    return saved;
  }

  Future<void> delete(String id) async {
    await ref.read(calendarRepositoryProvider).deleteEvent(id);
    await reload();
  }
}
