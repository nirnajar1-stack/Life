import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../data/models/habit_models.dart';
import '../../domain/models/habit_enums.dart';
import '../../domain/providers/habit_providers.dart';

const _weekdayChips = [
  (7, 'א׳'),
  (1, 'ב׳'),
  (2, 'ג׳'),
  (3, 'ד׳'),
  (4, 'ה׳'),
  (5, 'ו׳'),
  (6, 'ש׳'),
];

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key, this.habit});

  final Habit? habit;

  bool get isEditing => habit != null;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _title = TextEditingController();
  final _intention = TextEditingController();
  final _cue = TextEditingController();
  final _unit = TextEditingController();
  final _target = TextEditingController();
  final _interval = TextEditingController();
  late HabitType _type;
  late HabitTimeOfDay _time;
  late HabitFrequency _frequency;
  late HabitDifficulty _difficulty;
  late List<int> _customDays;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _title.text = habit?.title ?? '';
    _intention.text = habit?.description ?? '';
    _cue.text = habit?.cueTrigger ?? '';
    _unit.text = habit?.unit ?? '';
    _target.text = habit?.targetValue == null
        ? ''
        : (habit!.targetValue == habit.targetValue!.roundToDouble()
            ? habit.targetValue!.toInt().toString()
            : habit.targetValue!.toString());
    _interval.text = '${habit?.intervalDays ?? 2}';
    _type = habit?.habitType ?? HabitType.boolean;
    _time = habit?.timeOfDay ?? HabitTimeOfDay.morning;
    _frequency = habit?.frequency ?? HabitFrequency.daily;
    _difficulty = habit?.difficulty ?? HabitDifficulty.easy;
    _customDays = [...(habit?.customDays ?? const [1, 3, 5])];
  }

  @override
  void dispose() {
    _title.dispose();
    _intention.dispose();
    _cue.dispose();
    _unit.dispose();
    _target.dispose();
    _interval.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להזין שם להרגל')),
      );
      return;
    }
    setState(() => _saving = true);
    final target = double.tryParse(_target.text.trim());
    final interval = int.tryParse(_interval.text.trim()) ?? 1;
    final draft = (widget.habit ??
            Habit(
              id: '',
              title: title,
              habitType: _type,
              timeOfDay: _time,
              frequency: _frequency,
              currentStreak: 0,
              longestStreak: 0,
              totalCompletions: 0,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      title: title,
      description:
          _intention.text.trim().isEmpty ? null : _intention.text.trim(),
      clearDescription: _intention.text.trim().isEmpty,
      cueTrigger: _cue.text.trim().isEmpty ? null : _cue.text.trim(),
      clearCue: _cue.text.trim().isEmpty,
      habitType: _type,
      targetValue: _type == HabitType.measurable ? target : null,
      clearTarget: _type != HabitType.measurable || target == null,
      unit: _type == HabitType.measurable && _unit.text.trim().isNotEmpty
          ? _unit.text.trim()
          : null,
      clearUnit:
          _type != HabitType.measurable || _unit.text.trim().isEmpty,
      timeOfDay: _time,
      frequency: _frequency,
      difficulty: _difficulty,
      customDays: _frequency == HabitFrequency.specificDays
          ? _customDays
          : const [],
      intervalDays:
          _frequency == HabitFrequency.interval && interval > 0 ? interval : 1,
    );

    try {
      if (widget.isEditing) {
        await ref.read(habitsControllerProvider.notifier).update(draft);
      } else {
        await ref.read(habitsControllerProvider.notifier).create(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שמירה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inDialog = isFormDialog(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: inDialog ? Colors.white : AppColors.surface,
        appBar: AppBar(
          backgroundColor: inDialog ? Colors.white : null,
          title: Text(widget.isEditing ? 'עריכת הרגל' : 'הרגל חדש'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextField(
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'שם ההרגל',
                hintText: 'למשל: מקלחת קרה, 20 עמודים',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _intention,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'כוונת יישום',
                hintText: 'אחרי [טריגר], אני אעשה [הרגל]',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cue,
              decoration: const InputDecoration(
                labelText: 'טריגר',
                hintText: 'אחרי שפיכת הקפה של הבוקר',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('בוצע / לא'),
                  selected: _type == HabitType.boolean,
                  onSelected: (_) => setState(() => _type = HabitType.boolean),
                ),
                ChoiceChip(
                  label: const Text('מדיד'),
                  selected: _type == HabitType.measurable,
                  onSelected: (_) =>
                      setState(() => _type = HabitType.measurable),
                ),
              ],
            ),
            if (_type == HabitType.measurable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _target,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(labelText: 'יעד'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unit,
                      decoration: const InputDecoration(
                        labelText: 'יחידה',
                        hintText: 'עמודים, דק׳, מ״ל',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text('קושי', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in HabitDifficulty.values)
                  ChoiceChip(
                    label: Text(
                      value == HabitDifficulty.easy
                          ? 'קל · סיום אחרי 30 יום'
                          : 'קשה · סיום אחרי 60 יום',
                    ),
                    selected: _difficulty == value,
                    onSelected: (_) => setState(() => _difficulty = value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('שעת היום', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in HabitTimeOfDay.values)
                  ChoiceChip(
                    label: Text(value.labelHe),
                    selected: _time == value,
                    onSelected: (_) => setState(() => _time = value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('תדירות', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in HabitFrequency.values)
                  ChoiceChip(
                    label: Text(value.labelHe),
                    selected: _frequency == value,
                    onSelected: (_) => setState(() => _frequency = value),
                  ),
              ],
            ),
            if (_frequency == HabitFrequency.specificDays) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final day in _weekdayChips)
                    FilterChip(
                      label: Text(day.$2),
                      selected: _customDays.contains(day.$1),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _customDays = [..._customDays, day.$1]..sort();
                          } else {
                            _customDays = _customDays
                                .where((value) => value != day.$1)
                                .toList();
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
            if (_frequency == HabitFrequency.interval) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _interval,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'כל כמה ימים',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
