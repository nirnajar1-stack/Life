import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_event_model.dart';

final _timeFormat = DateFormat('HH:mm', 'he');

class CalendarEventTile extends StatelessWidget {
  const CalendarEventTile({
    super.key,
    required this.event,
    this.compact = false,
    this.onDelete,
  });

  final CalendarEventModel event;
  final bool compact;
  final VoidCallback? onDelete;

  String get _sourceLabel {
    switch (event.source) {
      case 'telegram':
      case 'n8n':
        return 'טלגרם';
      case 'google':
        return 'Google';
      case 'app':
        return 'אפליקציה';
      default:
        return event.source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${_timeFormat.format(event.startsAt)}–${_timeFormat.format(event.endsAt)}';

    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 4 : 8,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.event, color: AppColors.primary),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$time · $_sourceLabel',
          style: const TextStyle(color: AppColors.muted),
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: 'מחיקה',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
      ),
    );
  }
}
