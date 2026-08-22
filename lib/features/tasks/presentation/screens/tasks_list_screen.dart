import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_form.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/project_model.dart';
import '../../data/models/task_model.dart';
import '../../domain/models/capture_parse.dart';
import '../../domain/models/task_enums.dart';
import '../../domain/providers/task_providers.dart';
import '../../../habits/domain/habit_engine.dart';
import '../../../habits/domain/models/habit_enums.dart';
import '../../../habits/domain/providers/habit_providers.dart';
import '../../../habits/presentation/widgets/today_habits_panel.dart';
import '../widgets/task_row.dart';
import 'add_task_screen.dart';

final _dayFormat = DateFormat('EEEE d/M', 'he');

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen> {
  final _capture = TextEditingController();
  final _captureFocus = FocusNode();
  int _reviewStep = 0;
  DateTime _calendarDay = DateTime.now();

  @override
  void dispose() {
    _capture.dispose();
    _captureFocus.dispose();
    super.dispose();
  }

  bool get _typing {
    final widget = FocusManager.instance.primaryFocus?.context?.widget;
    return widget is EditableText;
  }

  Future<void> _openForm(TaskModel? task) async {
    await showAdaptiveForm(
      context: context,
      form: AddTaskScreen(task: task),
    );
    ref.read(tasksControllerProvider.notifier).reload();
  }

  Future<void> _deleteTask(TaskModel task) async {
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
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(tasksControllerProvider.notifier).deleteTask(task.id);
      if (ref.read(selectedTaskIdProvider) == task.id) {
        ref.read(selectedTaskIdProvider.notifier).state = null;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נמחק: ${task.title}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('מחיקה נכשלה: $error')),
      );
    }
  }

  Future<void> _submitCapture() async {
    final text = _capture.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(tasksControllerProvider.notifier).capture(text);
      _capture.clear();
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שמירה נכשלה: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(captureFocusTickProvider, (_, __) {
      ref.read(tasksWorkspaceViewProvider.notifier).state =
          TasksWorkspaceView.inbox;
      _captureFocus.requestFocus();
    });

    final tasksAsync = ref.watch(tasksControllerProvider);
    final view = ref.watch(tasksWorkspaceViewProvider);
    final selectedId = ref.watch(selectedTaskIdProvider);
    final projects = ref.watch(projectsProvider).valueOrNull ?? const [];
    final projectsById = {for (final p in projects) p.id: p};

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _captureFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _captureFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyC): () {
          if (!_typing) _captureFocus.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (_typing) return;
          final items = tasksAsync.valueOrNull ?? const <TaskModel>[];
          TaskModel? selected;
          for (final task in items) {
            if (task.id == selectedId) {
              selected = task;
              break;
            }
          }
          if (selected != null) {
            ref.read(tasksControllerProvider.notifier).toggleComplete(selected);
          }
        },
        const SingleActivator(LogicalKeyboardKey.digit1): () => ref
            .read(tasksWorkspaceViewProvider.notifier)
            .state = TasksWorkspaceView.inbox,
        const SingleActivator(LogicalKeyboardKey.digit2): () => ref
            .read(tasksWorkspaceViewProvider.notifier)
            .state = TasksWorkspaceView.today,
        const SingleActivator(LogicalKeyboardKey.digit3): () => ref
            .read(tasksWorkspaceViewProvider.notifier)
            .state = TasksWorkspaceView.matrix,
        const SingleActivator(LogicalKeyboardKey.digit4): () => ref
            .read(tasksWorkspaceViewProvider.notifier)
            .state = TasksWorkspaceView.calendar,
        const SingleActivator(LogicalKeyboardKey.digit5): () => ref
            .read(tasksWorkspaceViewProvider.notifier)
            .state = TasksWorkspaceView.review,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('משימות'),
            automaticallyImplyLeading: false,
          ),
          body: AppLayout.constrain(
            context: context,
            compact: 980,
            child: Column(
              children: [
                _CaptureBar(
                  controller: _capture,
                  focusNode: _captureFocus,
                  onSubmit: _submitCapture,
                  onChanged: () => setState(() {}),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<TasksWorkspaceView>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TasksWorkspaceView.inbox,
                        label: Text('תיבה'),
                        tooltip: '1',
                      ),
                      ButtonSegment(
                        value: TasksWorkspaceView.today,
                        label: Text('היום'),
                        tooltip: '2',
                      ),
                      ButtonSegment(
                        value: TasksWorkspaceView.matrix,
                        label: Text('מטריצה'),
                        tooltip: '3',
                      ),
                      ButtonSegment(
                        value: TasksWorkspaceView.calendar,
                        label: Text('יומן'),
                        tooltip: '4',
                      ),
                      ButtonSegment(
                        value: TasksWorkspaceView.review,
                        label: Text('סיכום'),
                        tooltip: '5',
                      ),
                    ],
                    selected: {view},
                    onSelectionChanged: (value) => ref
                        .read(tasksWorkspaceViewProvider.notifier)
                        .state = value.first,
                    ),
                  ),
                ),
                Expanded(
                  child: tasksAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => AppErrorState(
                      title: 'שגיאה בטעינת המשימות',
                      error: error,
                      onRetry: () =>
                          ref.read(tasksControllerProvider.notifier).reload(),
                    ),
                    data: (tasks) {
                      Widget body;
                      switch (view) {
                        case TasksWorkspaceView.inbox:
                          body = _InboxView(
                            tasks: tasks
                                .where((t) => t.status == TaskStatus.inbox)
                                .toList(),
                            selectedId: selectedId,
                            projectsById: projectsById,
                            onOpen: _openForm,
                            onDelete: _deleteTask,
                          );
                        case TasksWorkspaceView.today:
                          body = _TodayView(
                            tasks: tasks,
                            selectedId: selectedId,
                            projectsById: projectsById,
                            onOpen: _openForm,
                            onDelete: _deleteTask,
                          );
                        case TasksWorkspaceView.matrix:
                          body = _MatrixView(
                            tasks: tasks.where((t) => t.isOpen).toList(),
                            selectedId: selectedId,
                            projectsById: projectsById,
                            onOpen: _openForm,
                            onDelete: _deleteTask,
                          );
                        case TasksWorkspaceView.calendar:
                          body = _CalendarView(
                            tasks: tasks.where((t) => t.isOpen).toList(),
                            day: _calendarDay,
                            onDayChanged: (d) => setState(() => _calendarDay = d),
                            selectedId: selectedId,
                            projectsById: projectsById,
                            onOpen: _openForm,
                            onDelete: _deleteTask,
                          );
                        case TasksWorkspaceView.review:
                          body = _ReviewView(
                            tasks: tasks,
                            step: _reviewStep,
                            onStep: (s) => setState(() => _reviewStep = s),
                            selectedId: selectedId,
                            projectsById: projectsById,
                            onOpen: _openForm,
                            onDelete: _deleteTask,
                          );
                      }
                      return body;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final parsed = parseTaskCapture(controller.text);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmit(),
            maxLength: 160,
            decoration: InputDecoration(
              hintText: 'לכידה מהירה · מחר @desk p1 ~45m #פרויקט',
              prefixIcon: const Icon(Icons.bolt_outlined),
              suffixIcon: IconButton(
                tooltip: 'שמור',
                onPressed: onSubmit,
                icon: const Icon(Icons.arrow_back),
              ),
              counterText: '',
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Text(
                [
                  if (parsed.title.isNotEmpty) parsed.title,
                  if (parsed.eisenhowerDb != null) parsed.eisenhowerDb,
                  if (parsed.estimatedMinutes != null)
                    '~${parsed.estimatedMinutes}ד',
                  if (parsed.scheduledDate != null)
                    DateFormat('dd/MM').format(parsed.scheduledDate!),
                  ...parsed.contextTags,
                  if (parsed.projectName != null) '#${parsed.projectName}',
                  if (parsed.recurrenceRule != null) 'חוזר',
                ].join(' · '),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _InboxView extends ConsumerWidget {
  const _InboxView({
    required this.tasks,
    required this.selectedId,
    required this.projectsById,
    required this.onOpen,
    required this.onDelete,
  });

  final List<TaskModel> tasks;
  final String? selectedId;
  final Map<String, ProjectModel> projectsById;
  final ValueChanged<TaskModel> onOpen;
  final ValueChanged<TaskModel> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'התיבה ריקה',
        message: 'כתוב למעלה משימה אחת — בלי שדות חובה. למשל: מחר p1 ~30m @desk',
        compact: true,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskRow(
          task: task,
          selected: task.id == selectedId,
          projectName: projectsById[task.projectId]?.name,
          onSelect: () =>
              ref.read(selectedTaskIdProvider.notifier).state = task.id,
          onToggle: () =>
              ref.read(tasksControllerProvider.notifier).toggleComplete(task),
          onOpen: () => onOpen(task),
          onDelete: () => onDelete(task),
        );
      },
    );
  }
}

class _TodayView extends ConsumerWidget {
  const _TodayView({
    required this.tasks,
    required this.selectedId,
    required this.projectsById,
    required this.onOpen,
    required this.onDelete,
  });

  final List<TaskModel> tasks;
  final String? selectedId;
  final Map<String, ProjectModel> projectsById;
  final ValueChanged<TaskModel> onOpen;
  final ValueChanged<TaskModel> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energy = ref.watch(tasksEnergyFilterProvider);
    final contextTag = ref.watch(tasksContextFilterProvider);
    final tags = {
      for (final task in tasks) ...task.contextTags,
    }.toList()
      ..sort();

    Iterable<TaskModel> apply(Iterable<TaskModel> source) {
      return source.where((task) {
        if (energy != null && task.energyLevel != energy) return false;
        if (contextTag != null && !task.contextTags.contains(contextTag)) {
          return false;
        }
        return true;
      });
    }

    final overdue = apply(tasks.where((t) => t.isOverdue)).toList();
    final today = apply(
      tasks.where((t) => t.isOpen && (t.isDueToday || t.isScheduledToday)),
    ).toList();
    final nextActions = <TaskModel>[];
    final seenProjects = <String>{};
    final sorted = [...tasks.where((t) => t.isOpen)]
      ..sort((a, b) => a.eisenhower.rank.compareTo(b.eisenhower.rank));
    for (final task in sorted) {
      final pid = task.projectId;
      if (pid == null || seenProjects.contains(pid)) continue;
      seenProjects.add(pid);
      nextActions.add(task);
    }

    Widget list(String title, List<TaskModel> items, {bool emptyOk = true}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '$title · ${items.length}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (items.isEmpty && !emptyOk)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('אין פריטים', style: TextStyle(color: AppColors.muted)),
            ),
          for (final task in items)
            TaskRow(
              task: task,
              selected: task.id == selectedId,
              projectName: projectsById[task.projectId]?.name,
              progress: _parentProgress(tasks, task),
              onSelect: () =>
                  ref.read(selectedTaskIdProvider.notifier).state = task.id,
              onToggle: () => ref
                  .read(tasksControllerProvider.notifier)
                  .toggleComplete(task),
              onOpen: () => onOpen(task),
              onDelete: () => onDelete(task),
            ),
        ],
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                showCheckmark: false,
                label: const Text('כל האנרגיה'),
                selected: energy == null,
                onSelected: (_) =>
                    ref.read(tasksEnergyFilterProvider.notifier).state = null,
              ),
              for (final value in EnergyLevel.values)
                FilterChip(
                  showCheckmark: false,
                  label: Text(value.labelHe),
                  selected: energy == value,
                  onSelected: (_) => ref
                      .read(tasksEnergyFilterProvider.notifier)
                      .state = energy == value ? null : value,
                ),
              for (final tag in tags)
                FilterChip(
                  showCheckmark: false,
                  label: Text(tag),
                  selected: contextTag == tag,
                  onSelected: (_) => ref
                      .read(tasksContextFilterProvider.notifier)
                      .state = contextTag == tag ? null : tag,
                ),
            ],
          ),
        ),
        const TodayHabitsPanel(),
        list('באיחור', overdue),
        list('להיום', today),
        list('הפעולה הבאה בכל פרויקט', nextActions),
      ],
    );
  }
}

double? _parentProgress(List<TaskModel> all, TaskModel parent) {
  final children = all.where((t) => t.parentTaskId == parent.id).toList();
  if (children.isEmpty) return null;
  final done = children.where((t) => t.isCompleted).length;
  return done / children.length;
}

class _MatrixView extends ConsumerWidget {
  const _MatrixView({
    required this.tasks,
    required this.selectedId,
    required this.projectsById,
    required this.onOpen,
    required this.onDelete,
  });

  final List<TaskModel> tasks;
  final String? selectedId;
  final Map<String, ProjectModel> projectsById;
  final ValueChanged<TaskModel> onOpen;
  final ValueChanged<TaskModel> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget quadrant(Eisenhower value) {
      final items =
          tasks.where((t) => t.eisenhower == value && t.isOpen).toList();
      return DragTarget<TaskModel>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          ref
              .read(tasksControllerProvider.notifier)
              .moveEisenhower(details.data, value);
        },
        builder: (context, candidate, _) {
          final hover = candidate.isNotEmpty;
          return Card(
            color: hover ? AppColors.primary.withValues(alpha: 0.06) : null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${value.shortLabel} · ${value.labelHe}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    value.hintHe,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final task in items)
                          LongPressDraggable<TaskModel>(
                            data: task,
                            feedback: Material(
                              elevation: 6,
                              child: SizedBox(
                                width: 240,
                                child: ListTile(title: Text(task.title)),
                              ),
                            ),
                            child: TaskRow(
                              task: task,
                              selected: task.id == selectedId,
                              projectName: projectsById[task.projectId]?.name,
                              onSelect: () => ref
                                  .read(selectedTaskIdProvider.notifier)
                                  .state = task.id,
                              onToggle: () => ref
                                  .read(tasksControllerProvider.notifier)
                                  .toggleComplete(task),
                              onOpen: () => onOpen(task),
                              onDelete: () => onDelete(task),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: quadrant(Eisenhower.doNow)),
                const SizedBox(width: 8),
                Expanded(child: quadrant(Eisenhower.schedule)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: quadrant(Eisenhower.delegate)),
                const SizedBox(width: 8),
                Expanded(child: quadrant(Eisenhower.eliminate)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends ConsumerWidget {
  const _CalendarView({
    required this.tasks,
    required this.day,
    required this.onDayChanged,
    required this.selectedId,
    required this.projectsById,
    required this.onOpen,
    required this.onDelete,
  });

  final List<TaskModel> tasks;
  final DateTime day;
  final ValueChanged<DateTime> onDayChanged;
  final String? selectedId;
  final Map<String, ProjectModel> projectsById;
  final ValueChanged<TaskModel> onOpen;
  final ValueChanged<TaskModel> onDelete;

  DateTime get _day => DateTime(day.year, day.month, day.day);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots =
        ref.watch(habitsControllerProvider).valueOrNull ?? const [];
    final dueHabits = snapshots
        .where((item) => habitIsDueOn(item.habit, _day))
        .toList();
    final anytimeHabits = dueHabits
        .where((item) => item.habit.timeOfDay.calendarHour == null)
        .toList();
    final unscheduled = tasks
        .where((t) => t.timeStart == null || t.timeStart!.isEmpty)
        .toList();
    final hours = [for (var h = 7; h <= 20; h++) h];

    Widget unscheduledList() {
      return Card(
        child: ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'לא משובץ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            if (unscheduled.isEmpty && anytimeHabits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'אין משימות פתוחות בלי שעה',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            for (final snapshot in anytimeHabits)
              CalendarHabitChip(snapshot: snapshot, day: _day),
            for (final task in unscheduled)
              LongPressDraggable<TaskModel>(
                data: task,
                feedback: Material(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(task.title),
                  ),
                ),
                child: TaskRow(
                  task: task,
                  selected: task.id == selectedId,
                  projectName: projectsById[task.projectId]?.name,
                  onSelect: () =>
                      ref.read(selectedTaskIdProvider.notifier).state = task.id,
                  onToggle: () => ref
                      .read(tasksControllerProvider.notifier)
                      .toggleComplete(task),
                  onOpen: () => onOpen(task),
                  onDelete: () => onDelete(task),
                ),
              ),
          ],
        ),
      );
    }

    Widget timeline() {
      return Card(
        child: ListView(
          children: [
            for (final hour in hours)
              DragTarget<TaskModel>(
                onAcceptWithDetails: (details) {
                  final start = '${hour.toString().padLeft(2, '0')}:00';
                  final end = '${(hour + 1).toString().padLeft(2, '0')}:00';
                  ref.read(tasksControllerProvider.notifier).scheduleInSlot(
                        task: details.data,
                        day: _day,
                        start: start,
                        end: end,
                      );
                },
                builder: (context, candidate, _) {
                  final items = tasks.where((t) {
                    if (!t.hasTimeSlot || t.scheduledDate == null) return false;
                    final scheduled = DateTime(
                      t.scheduledDate!.year,
                      t.scheduledDate!.month,
                      t.scheduledDate!.day,
                    );
                    return scheduled == _day &&
                        (t.timeStart ?? '').startsWith(
                          hour.toString().padLeft(2, '0'),
                        );
                  }).toList();
                  final hourHabits = dueHabits
                      .where((item) => item.habit.timeOfDay.calendarHour == hour)
                      .toList();
                  return Container(
                    constraints: const BoxConstraints(minHeight: 58),
                    decoration: BoxDecoration(
                      color: candidate.isNotEmpty
                          ? AppColors.tasks.withValues(alpha: 0.08)
                          : null,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.line),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty && hourHabits.isEmpty
                              ? const SizedBox.shrink()
                              : Column(
                                  children: [
                                    for (final snapshot in hourHabits)
                                      CalendarHabitChip(
                                        snapshot: snapshot,
                                        day: _day,
                                      ),
                                    for (final task in items)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: InputChip(
                                          label: Text(
                                            '${task.title} · ${task.timeStart}-${task.timeEnd}',
                                          ),
                                          onPressed: () => onOpen(task),
                                          onDeleted: () => ref
                                              .read(tasksControllerProvider
                                                  .notifier)
                                              .toggleComplete(task),
                                          deleteIcon:
                                              const Icon(Icons.check, size: 16),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onDayChanged(_day.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right),
          ),
          Expanded(
            child: Center(
              child: Text(
                _dayFormat.format(_day),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onDayChanged(_day.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );

    final isWide = MediaQuery.sizeOf(context).width >= 900;
    if (isWide) {
      return Column(
        children: [
          header,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  SizedBox(width: 320, child: unscheduledList()),
                  const SizedBox(width: 8),
                  Expanded(child: timeline()),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        Expanded(child: unscheduledList()),
        const SizedBox(height: 8),
        Expanded(flex: 2, child: timeline()),
      ],
    );
  }
}

class _ReviewView extends ConsumerWidget {
  const _ReviewView({
    required this.tasks,
    required this.step,
    required this.onStep,
    required this.selectedId,
    required this.projectsById,
    required this.onOpen,
    required this.onDelete,
  });

  final List<TaskModel> tasks;
  final int step;
  final ValueChanged<int> onStep;
  final String? selectedId;
  final Map<String, ProjectModel> projectsById;
  final ValueChanged<TaskModel> onOpen;
  final ValueChanged<TaskModel> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = tasks.where((t) => t.status == TaskStatus.inbox).toList();
    final overdue = tasks.where((t) => t.isOverdue).toList();
    final tomorrowCandidates = [...tasks.where((t) => t.isOpen)]
      ..sort((a, b) => a.eisenhower.rank.compareTo(b.eisenhower.rank));
    final titles = ['ניקוי תיבה', 'שיבוץ באיחור', 'שלישייה למחר'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => onStep(i),
                    style: FilledButton.styleFrom(
                      backgroundColor: step == i
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : null,
                    ),
                    child: Text('${i + 1}. ${titles[i]}'),
                  ),
                ),
                if (i < 2) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: step == 0
                ? _reviewList(
                    ref,
                    empty: 'התיבה נקייה.',
                    items: inbox,
                    helper: 'העבר למוכן, או השלם וסגור.',
                  )
                : step == 1
                    ? _reviewList(
                        ref,
                        empty: 'אין משימות באיחור.',
                        items: overdue,
                        helper: 'קבע תאריך חדש בכרטיס או סמן כהושלם.',
                      )
                    : _TopThree(
                        tasks: tomorrowCandidates.take(12).toList(),
                        selectedId: selectedId,
                        onOpen: onOpen,
                      ),
          ),
          Row(
            children: [
              if (step > 0)
                TextButton(
                  onPressed: () => onStep(step - 1),
                  child: const Text('חזרה'),
                ),
              const Spacer(),
              if (step < 2)
                FilledButton(
                  onPressed: () => onStep(step + 1),
                  child: const Text('המשך'),
                )
              else
                FilledButton(
                  onPressed: () {
                    onStep(0);
                    ref.read(tasksWorkspaceViewProvider.notifier).state =
                        TasksWorkspaceView.today;
                  },
                  child: const Text('סגור יום'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewList(
    WidgetRef ref, {
    required String empty,
    required List<TaskModel> items,
    required String helper,
  }) {
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.check_circle_outline,
        title: empty,
        message: helper,
        compact: true,
      );
    }
    return ListView(
      children: [
        Text(helper, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        for (final task in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: TaskRow(
              task: task,
              selected: task.id == selectedId,
              projectName: projectsById[task.projectId]?.name,
              onSelect: () =>
                  ref.read(selectedTaskIdProvider.notifier).state = task.id,
              onToggle: () =>
                  ref.read(tasksControllerProvider.notifier).toggleComplete(task),
              onOpen: () => onOpen(task),
              onDelete: () => onDelete(task),
            ),
          ),
      ],
    );
  }
}

class _TopThree extends ConsumerWidget {
  const _TopThree({
    required this.tasks,
    required this.selectedId,
    required this.onOpen,
  });

  final List<TaskModel> tasks;
  final String? selectedId;
  final ValueChanged<TaskModel> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final day = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    return ListView(
      children: [
        const Text(
          'בחר עד 3 משימות למחר — לחיצה משבצת להן תאריך למחר.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        for (final task in tasks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              selected: task.id == selectedId,
              title: Text(task.title),
              subtitle: Text(
                '${task.eisenhower.labelHe} · ${task.status.labelHe}',
              ),
              trailing: TextButton(
                onPressed: () {
                  ref.read(tasksControllerProvider.notifier).updateTask(
                        task.copyWith(
                          scheduledDate: day,
                          dueDate: DateTime(day.year, day.month, day.day, 18),
                          status: TaskStatus.ready,
                        ),
                      );
                },
                child: const Text('למחר'),
              ),
              onTap: () => onOpen(task),
            ),
          ),
      ],
    );
  }
}
