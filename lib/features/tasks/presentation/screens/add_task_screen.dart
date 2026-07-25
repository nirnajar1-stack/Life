import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_model.dart';
import '../../domain/providers/task_providers.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'כללי';
  bool _isSaving = false;

  // רשימת הקטגוריות עם האייקונים והצבעים שלהן
  final List<Map<String, dynamic>> _categories = [
    {'name': 'כללי', 'icon': Icons.assignment_outlined, 'color': Colors.grey},
    {'name': 'פיננסי', 'icon': Icons.account_balance_wallet_outlined, 'color': Colors.green},
    {'name': 'בריאותי', 'icon': Icons.favorite_border, 'color': Colors.red},
    {'name': 'אישי', 'icon': Icons.person_outline, 'color': Colors.blue},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    // id/createdAt are DB-generated and ignored by toJsonForInsert().
    final task = TaskModel(
      id: '',
      title: title,
      description: description.isEmpty ? null : description,
      isCompleted: false,
      priority: 2,
      category: _selectedCategory,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(taskRepositoryProvider).createTask(task);
      ref.invalidate(activeTasksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('המשימה "$title" נשמרה ב-Supabase! 🎉')),
      );
      Navigator.of(context).pop();
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
    // בדיקה האם מדובר במסך רחב (Web/טאבלט)
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('משימה חדשה תחום חיים'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: isWideScreen
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    )
                  : null,
              padding: isWideScreen ? const EdgeInsets.all(32.0) : EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // שדה כותרת
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'מה המשימה?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // שדה תיאור
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

                  // כותרת לבחירת קטגוריה
                  Text(
                    'קטגוריית תחום חיים:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // כפתורי בחירה מעוצבים (ChoiceChips)
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      final Color color = cat['color'];

                      return ChoiceChip(
                        label: Text(cat['name']),
                        avatar: Icon(cat['icon'], color: isSelected ? Colors.white : color),
                        selected: isSelected,
                        selectedColor: color,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat['name'];
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // כפתור שמירה פיזי
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('שמור משימה', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
