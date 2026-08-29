import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/event_parse.dart';
import '../../domain/providers/calendar_providers.dart';
import 'calendar_screen.dart';

class CalendarEventFormScreen extends ConsumerStatefulWidget {
  const CalendarEventFormScreen({super.key});

  @override
  ConsumerState<CalendarEventFormScreen> createState() =>
      _CalendarEventFormScreenState();
}

class _CalendarEventFormScreenState
    extends ConsumerState<CalendarEventFormScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'כתבו מה לתאם');
      return;
    }
    final parsed = parseCalendarEvent(raw);
    if (parsed == null) {
      setState(
        () => _error =
            'לא הצלחתי להבין תאריך. נסו: יום שלישי בשעה 6 תור לרופא',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(upcomingCalendarEventsProvider.notifier).addFromText(raw);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _controller.text.trim().isEmpty
        ? null
        : describeParsePreview(_controller.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('אירוע חדש'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('שמירה'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'מה לתאם?',
              hintText: 'יום שלישי הקרוב בשעה 6 תור לרופא',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          if (preview != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                preview,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          const Text(
            'דוגמאות',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('• יום שלישי בשעה 6 תור לרופא'),
          const Text('• 15/9 בשעה 10:30 פגישה'),
          const Text('• מחר ב־18 ישיבת צוות שעתיים'),
          const SizedBox(height: 8),
          const Text(
            'ברירת מחדל: משך שעה. שעות 1–7 בלי «בבוקר» נחשבות לערב (למשל 6 → 18:00).',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
