import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/calendar_event_model.dart';

class CalendarRepository {
  CalendarRepository(this._client);

  final SupabaseClient _client;

  Future<List<CalendarEventModel>> fetchUpcoming({
    DateTime? from,
    int limit = 50,
  }) async {
    final start = (from ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await _client
        .from('calendar_events')
        .select()
        .gte('ends_at', start)
        .order('starts_at')
        .limit(limit);
    return (rows as List)
        .map(
          (row) =>
              CalendarEventModel.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<CalendarEventModel>> fetchRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _client
        .from('calendar_events')
        .select()
        .lt('starts_at', end.toUtc().toIso8601String())
        .gt('ends_at', start.toUtc().toIso8601String())
        .order('starts_at');
    return (rows as List)
        .map(
          (row) =>
              CalendarEventModel.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<CalendarEventModel> insertEvent(CalendarEventModel event) async {
    final row = await _client
        .from('calendar_events')
        .insert(event.toJson())
        .select()
        .single();
    return CalendarEventModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteEvent(String id) async {
    await _client.from('calendar_events').delete().eq('id', id);
  }
}
