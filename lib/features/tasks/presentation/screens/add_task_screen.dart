import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/task_model.dart';
import '../../domain/providers/task_providers.dart';

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
  late int _priority;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController.text = t?.title ?? '';
    _descriptionController.text = t?.description ?? '';
    _selectedCategory = t?.category ?? 'כללי';
    _priority = t?.priority ?? 2;
    _dueDate = t?.dueDate;
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
    final repo = ref.read(taskRepositoryProvider);

    try {
      if (widget.isEditing) {
        final updated = widget.task!.copyWith(
          title: title,
          description: description.isEmpty ? null : description,
          clearDescription: description.isEmpty,
          category: _selectedCategory,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        );
        await repo.updateTask(updated);
      } else {
        final created = TaskModel(
          id: '',
          title: title,
          description: description.isEmpty ? null : description,
          isCompleted: false,
          priority: _priority,
          category: _selectedCategory,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
        );
        await repo.createTask(created);
      }

      ref.invalidate(activeTasksProvider);
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
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'עריכת משימה' : 'משימה חדשה'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: isWideScreen
                  ? BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    )
                  : null,
              padding: isWideScreen ? const EdgeInsets.all(32) : EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'מה המשימה?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'פרטים נוספים (אופציונלי)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'קטגוריית תחום חיים:',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat.name;
                      return ChoiceChip(
                        label: Text(cat.name),
                        avatar: Icon(
                          cat.icon,
                          color: selected ? Colors.white : cat.color,
                        ),
                        selected: selected,
                        selectedColor: cat.color,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                        ),
                        onSelected: (v) {
                          if (v) {
                            setState(() => _selectedCategory = cat.name);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'עדיפות',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('גבוהה')),
                      ButtonSegment(value: 2, label: Text('בינונית')),
                      ButtonSegment(value: 3, label: Text('נמוכה')),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (v) =>
                        setState(() => _priority = v.first),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
