class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    this.location,
    required this.source,
    this.telegramChatId,
    this.telegramMessageId,
    this.googleEventId,
    this.googleCalendarId,
    this.rawText,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? location;
  final String source;
  final String? telegramChatId;
  final String? telegramMessageId;
  final String? googleEventId;
  final String? googleCalendarId;
  final String? rawText;
  final DateTime createdAt;
  final DateTime updatedAt;

  Duration get duration => endsAt.difference(startsAt);

  bool get isToday {
    final now = DateTime.now();
    return startsAt.year == now.year &&
        startsAt.month == now.month &&
        startsAt.day == now.day;
  }

  bool get isUpcoming => endsAt.isAfter(DateTime.now());

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      location: json['location'] as String?,
      source: json['source'] as String? ?? 'telegram',
      telegramChatId: json['telegram_chat_id'] as String?,
      telegramMessageId: json['telegram_message_id'] as String?,
      googleEventId: json['google_event_id'] as String?,
      googleCalendarId: json['google_calendar_id'] as String?,
      rawText: json['raw_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'location': location,
      'source': source,
      'telegram_chat_id': telegramChatId,
      'telegram_message_id': telegramMessageId,
      'google_event_id': googleEventId,
      'google_calendar_id': googleCalendarId,
      'raw_text': rawText,
    };
  }

  CalendarEventModel copyWith({
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    String? location,
    String? source,
  }) {
    return CalendarEventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      location: location ?? this.location,
      source: source ?? this.source,
      telegramChatId: telegramChatId,
      telegramMessageId: telegramMessageId,
      googleEventId: googleEventId,
      googleCalendarId: googleCalendarId,
      rawText: rawText,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
