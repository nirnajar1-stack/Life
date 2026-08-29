import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../data/models/calendar_event_model.dart';
import '../../domain/models/event_parse.dart';
import '../../domain/providers/calendar_providers.dart';
import '../widgets/calendar_event_tile.dart';
import 'calendar_event_form_screen.dart';

final _dayFormat = DateFormat('EEEE, d MMMM', 'he');
final _timeFormat = DateFormat('HH:mm', 'he');

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    await showAdaptiveForm(
      context: context,
      form: const CalendarEventFormScreen(),
    );
    ref.read(upcomingCalendarEventsProvider.notifier).reload();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CalendarEventModel event,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('למחוק אירוע?'),
        content: Text(event.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('מחיקה'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(upcomingCalendarEventsProvider.notifier).delete(event.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(upcomingCalendarEventsProvider);
    final isDesktop = AppLayout.isDesktop(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('יומן'),
              automaticallyImplyLeading: false,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.event_available),
        label: const Text('אירוע'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(upcomingCalendarEventsProvider.notifier).reload(),
        child: AppLayout.constrain(
          context: context,
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              padding: AppLayout.pagePadding,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'לא ניתן לטעון אירועים: $error',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
            data: (events) {
              if (events.isEmpty) {
                return ListView(
                  padding: AppLayout.pagePadding,
                  children: [
                    if (isDesktop)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'יומן',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    AppEmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'אין אירועים קרובים',
                      message:
                          'שלחו בטלגרם: «יום שלישי בשעה 6 תור לרופא» — או הוסיפו כאן ידנית.',
                      actionLabel: 'אירוע חדש',
                      onAction: () => _openForm(context, ref),
                    ),
                  ],
                );
              }

              final grouped = <String, List<CalendarEventModel>>{};
              for (final event in events) {
                final key = _dayFormat.format(event.startsAt);
                grouped.putIfAbsent(key, () => []).add(event);
              }

              return ListView(
                padding: AppLayout.pagePadding.copyWith(bottom: 96),
                children: [
                  if (isDesktop)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'יומן',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  Text(
                    'אירועים מטלגרם, מ־Google Calendar ומהאפליקציה',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in grouped.entries) ...[
                    AppSectionHeader(title: entry.key),
                    const SizedBox(height: 8),
                    for (final event in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CalendarEventTile(
                          event: event,
                          onDelete: () => _delete(context, ref, event),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Compact home panel of the next few events.
class UpcomingEventsPanel extends ConsumerWidget {
  const UpcomingEventsPanel({
    super.key,
    this.limit = 4,
    this.onOpenAll,
  });

  final int limit;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(upcomingCalendarEventsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        final items = events.take(limit).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'יומן',
              actionLabel: onOpenAll == null ? null : 'הכל',
              onAction: onOpenAll,
            ),
            const SizedBox(height: 8),
            for (final event in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CalendarEventTile(event: event, compact: true),
              ),
          ],
        );
      },
    );
  }
}

String formatEventTimeRange(CalendarEventModel event) {
  return '${_timeFormat.format(event.startsAt)}–${_timeFormat.format(event.endsAt)}';
}

String describeParsePreview(String raw) {
  final parsed = parseCalendarEvent(raw);
  if (parsed == null) return 'חסר תאריך או יום בשבוע';
  final day = _dayFormat.format(parsed.startsAt);
  final time = _timeFormat.format(parsed.startsAt);
  final dur = parsed.durationMinutes;
  return '$day · $time · $dur דק׳ · ${parsed.title}';
}
