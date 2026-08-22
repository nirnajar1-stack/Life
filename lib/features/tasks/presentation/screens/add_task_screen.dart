import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/task_model.dart';
import '../../domain/models/recurrence.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/providers/task_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

class _CategoryOption {
  const _CategoryOption(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

const _categories = [
  _CategoryOption('כללי', Icons.assignment_outlined, Colors.grey),
  _CategoryOption(
      'פיננסי', Icons.account_balance_wallet_outlined, Colors.green),
  _CategoryOption('בריאותי', Icons.favorite_border, Colors.red),
  _CategoryOption('אישי', Icons.person_outline, Colors.blue),
];

/// Create or edit a task.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key, this.task});

  final TaskModel? task;

  bool get isEditing => task != null;

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedCategory;
  late Eisenhower _eisenhower;
  late TaskStatus _status;
  late EnergyLevel _energy;
  DateTime? _dueDate;
  bool _isSaving = false;
  bool _recurring = false;
  RecurrenceMode _recurrenceMode = RecurrenceMode.weekly;
  int _weekday = DateTime.friday;
  int _weekInterval = 1;
  int _intervalDays = 7;
  int _leadDays = 0;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController.text = t?.title ?? '';
    _descriptionController.text = t?.description ?? '';
    _selectedCategory = t?.category ?? 'כללי';
    _eisenhower = t?.eisenhower ?? Eisenhower.schedule;
    _status = t?.status ?? TaskStatus.ready;
    _energy = t?.energyLevel ?? EnergyLevel.medium;
    _dueDate = t?.dueDate;
    final recurrence = RecurrenceConfig.fromRule(t?.recurrenceRule);
    if (recurrence != null) {
      _recurring = true;
      _recurrenceMode = recurrence.mode;
      _weekday = recurrence.weekday;
      _weekInterval = recurrence.mode == RecurrenceMode.weekly
          ? recurrence.interval
          : 1;
      _intervalDays = recurrence.mode == RecurrenceMode.interval
          ? recurrence.interval
          : 7;
      _leadDays = recurrence.leadDays;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  RecurrenceConfig? _buildRecurrence() {
    if (!_recurring) return null;
    switch (_recurrenceMode) {
      case RecurrenceMode.weekly:
        return RecurrenceConfig(
          mode: RecurrenceMode.weekly,
          weekday: _weekday,
          interval: _weekInterval,
          leadDays: _leadDays,
        );
      case RecurrenceMode.interval:
        return RecurrenceConfig(
          mode: RecurrenceMode.interval,
          interval: _intervalDays,
          leadDays: _leadDays,
        );
    }
  }

  Future<void> _deleteTask() async {
    final task = widget.task;
    if (task == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('מחיקת משימה'),
          content: Text('למחוק את "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(tasksControllerProvider.notifier).deleteTask(task.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להזין כותרת למשימה')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final description = _descriptionController.text.trim();
    final recurrence = _buildRecurrence();
    final recurrenceRule = recurrence?.toRule();
    var dueDate = _dueDate;
    if (recurrence != null && dueDate == null) {
      dueDate = recurrence.firstDueFrom(DateTime.now());
    }

    try {
      if (widget.isEditing) {
        final updated = widget.task!.copyWith(
          title: title,
          description: description.isEmpty ? null : description,
          clearDescription: description.isEmpty,
          category: _selectedCategory,
          eisenhower: _eisenhower,
          status: _status,
          energyLevel: _energy,
          dueDate: dueDate,
          clearDueDate: dueDate == null,
          recurrenceRule: recurrenceRule,
          clearRecurrenceRule: !_recurring,
        );
        await ref.read(tasksControllerProvider.notifier).updateTask(updated);
      } else {
        final created = TaskModel(
          id: '',
          title: title,
          description: description.isEmpty ? null : description,
          status: _status,
          eisenhower: _eisenhower,
          category: _selectedCategory,
          dueDate: dueDate,
          energyLevel: _energy,
          recurrenceRule: recurrenceRule,
          createdAt: DateTime.now(),
        );
        await ref.read(taskRepositoryProvider).createTask(created);
        await ref.read(tasksControllerProvider.notifier).reload();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'המשימה עודכנה'
              : 'המשימה "$title" נשמרה'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
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
          title: Text(widget.isEditing ? 'עריכת משימה' : 'משימה חדשה'),
          leading: IconButton(
            tooltip: 'סגור',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    autofocus: !widget.isEditing,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'מה המשימה?',
                      prefixIcon: Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'פרטים נוספים (אופציונלי)',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'קטגוריה',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat.name;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(cat.name),
                        avatar: Icon(
                          cat.icon,
                          color: selected ? Colors.white : cat.color,
                        ),
                        selected: selected,
                        selectedColor: cat.color,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (v) {
                          if (v) {
                            setState(() => _selectedCategory = cat.name);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'סטטוס',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in TaskStatus.values)
                        ChoiceChip(
                          showCheckmark: false,
                          label: Text(value.labelHe),
                          selected: _status == value,
                          onSelected: (_) => setState(() => _status = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'אייזנהאואר',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in Eisenhower.values)
                        ChoiceChip(
                          showCheckmark: false,
                          label: Text('${value.shortLabel} · ${value.labelHe}'),
                          selected: _eisenhower == value,
                          onSelected: (_) =>
                              setState(() => _eisenhower = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'אנרגיה',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in EnergyLevel.values)
                        ChoiceChip(
                          showCheckmark: false,
                          label: Text(value.labelHe),
                          selected: _energy == value,
                          onSelected: (_) => setState(() => _energy = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      _dueDate == null
                          ? 'ללא תאריך יעד'
                          : 'יעד: ${_dateFormat.format(_dueDate!)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dueDate != null)
                          IconButton(
                            tooltip: 'נקה',
                            onPressed: () => setState(() => _dueDate = null),
                            icon: const Icon(Icons.clear),
                          ),
                        TextButton(
                          onPressed: _pickDueDate,
                          child: const Text('בחר תאריך'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('משימה חוזרת'),
                    subtitle: const Text(
                      'יום בשבוע עם התראה מראש, או כל מספר ימים',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _recurring,
                    onChanged: (value) => setState(() => _recurring = value),
                  ),
                  if (_recurring) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('יום בשבוע'),
                          selected: _recurrenceMode == RecurrenceMode.weekly,
                          onSelected: (_) => setState(
                              () => _recurrenceMode = RecurrenceMode.weekly),
                        ),
                        ChoiceChip(
                          label: const Text('כל X ימים'),
                          selected: _recurrenceMode == RecurrenceMode.interval,
                          onSelected: (_) => setState(
                              () => _recurrenceMode = RecurrenceMode.interval),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_recurrenceMode == RecurrenceMode.weekly) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var day = DateTime.monday;
                              day <= DateTime.sunday;
                              day++)
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text(_weekdayShort(day)),
                              selected: _weekday == day,
                              onSelected: (_) => setState(() => _weekday = day),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '$_weekInterval',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'כל כמה שבועות',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value.trim());
                                if (parsed != null && parsed > 0) {
                                  setState(() => _weekInterval = parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else
                      TextFormField(
                        initialValue: '$_intervalDays',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'כל כמה ימים',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value.trim());
                          if (parsed != null && parsed > 0) {
                            setState(() => _intervalDays = parsed);
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: '$_leadDays',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ימים לפני (להקפיץ מוקדם)',
                        hintText: 'למשל 2 = משימה יופיע 2 ימים לפני',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value.trim());
                        if (parsed != null && parsed >= 0) {
                          setState(() => _leadDays = parsed);
                        }
                      },
                    ),
                    if (_buildRecurrence() != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _buildRecurrence()!.labelHe,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveTask,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isEditing ? 'שמור שינויים' : 'שמור משימה',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _deleteTask,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('מחק משימה'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _weekdayShort(int weekday) {
    const labels = ['ב', 'ג', 'ד', 'ה', 'ו', 'ש', 'א'];
    return labels[(weekday.clamp(1, 7)) - 1];
  }
}
