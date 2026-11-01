import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/providers.dart';
import '../theme/portal_theme.dart';
import 'task_detail_panel.dart';

class TaskCenterScreen extends ConsumerStatefulWidget {
  const TaskCenterScreen({super.key, this.openCompose = false});

  final bool openCompose;

  @override
  ConsumerState<TaskCenterScreen> createState() => _TaskCenterScreenState();
}

class _TaskCenterScreenState extends ConsumerState<TaskCenterScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.openCompose) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final units = await ref.read(myUnitsProvider.future);
    if (!mounted || units.isEmpty) return;
    final titleCtrl = TextEditingController();
    String unitId = units.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('פתיחת משימה'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'כותרת'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: unitId,
                  items: [
                    for (final u in units)
                      DropdownMenuItem(value: u.id, child: Text(u.titleHe)),
                  ],
                  onChanged: (v) => unitId = v ?? unitId,
                  decoration: const InputDecoration(labelText: 'יחידת טיפול'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('שמירה'),
            ),
          ],
        );
      },
    );
    if (ok != true || titleCtrl.text.trim().isEmpty) return;
    try {
      final task = await ref.read(taskServiceProvider).createTask(
            titleHe: titleCtrl.text.trim(),
            treatmentUnitId: unitId,
          );
      ref.invalidate(tasksProvider);
      ref.read(selectedTaskIdProvider.notifier).state = task.id;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המשימה נשמרה במסד הנתונים')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שמירה נכשלה: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(taskCenterViewModeProvider);
    final filters = ref.watch(taskFiltersProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final selectedId = ref.watch(selectedTaskIdProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'חיפוש משימה / משפחה / אדם',
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    ref.read(taskFiltersProvider.notifier).state =
                        filters.copyWith(search: v);
                  },
                ),
              ),
              SegmentedButton<TaskCenterViewMode>(
                segments: const [
                  ButtonSegment(
                    value: TaskCenterViewMode.byTasks,
                    label: Text('לפי משימות'),
                    icon: Icon(Icons.view_list),
                  ),
                  ButtonSegment(
                    value: TaskCenterViewMode.byUnits,
                    label: Text('לפי יחידות'),
                    icon: Icon(Icons.account_tree),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) {
                  ref.read(taskCenterViewModeProvider.notifier).state =
                      s.first;
                },
              ),
              FilterChip(
                label: const Text('פתוחות'),
                selected: filters.openOnly,
                onSelected: (v) {
                  ref.read(taskFiltersProvider.notifier).state =
                      filters.copyWith(openOnly: v);
                },
              ),
              FilterChip(
                label: const Text('חורגות'),
                selected: filters.onlyOverdue,
                onSelected: (v) {
                  ref.read(taskFiltersProvider.notifier).state =
                      filters.copyWith(onlyOverdue: v);
                },
              ),
              FilledButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('משימה חדשה'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('שגיאה בטעינת משימות: $e')),
            data: (tasks) {
              final list = mode == TaskCenterViewMode.byTasks
                  ? _TasksList(
                      tasks: tasks,
                      selectedId: selectedId,
                      onSelect: (id) {
                        ref.read(selectedTaskIdProvider.notifier).state = id;
                        if (!wide) context.push('/tasks/$id');
                      },
                    )
                  : _TasksByUnit(
                      tasks: tasks,
                      selectedId: selectedId,
                      onSelect: (id) {
                        ref.read(selectedTaskIdProvider.notifier).state = id;
                        if (!wide) context.push('/tasks/$id');
                      },
                    );

              if (!wide) return list;
              return Row(
                children: [
                  Expanded(flex: 3, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 2,
                    child: selectedId == null
                        ? const Center(child: Text('בחרו משימה להצגה'))
                        : TaskDetailPanel(
                            taskId: selectedId,
                            onClose: () => ref
                                .read(selectedTaskIdProvider.notifier)
                                .state = null,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TasksList extends StatelessWidget {
  const _TasksList({
    required this.tasks,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PortalTask> tasks;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('אין משימות התואמות לסינון.'));
    }
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = tasks[i];
        return ListTile(
          selected: t.id == selectedId,
          title: Text(t.titleHe),
          subtitle: Text(
            [
              t.personNameHe,
              t.unitCode,
              taskStatusLabelHe(t.status),
              if (t.isOverdue) 'חורגת',
            ].whereType<String>().join(' · '),
          ),
          trailing: t.requiresAttention
              ? const Icon(Icons.warning_amber, color: PortalColors.warning)
              : Text(
                  _relative(t.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          onTap: () => onSelect(t.id),
        );
      },
    );
  }
}

class _TasksByUnit extends StatelessWidget {
  const _TasksByUnit({
    required this.tasks,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PortalTask> tasks;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<PortalTask>>{};
    for (final t in tasks) {
      grouped.putIfAbsent(t.treatmentUnitId, () => []).add(t);
    }
    if (grouped.isEmpty) {
      return const Center(child: Text('אין משימות להצגה.'));
    }
    return ListView(
      children: [
        for (final entry in grouped.entries)
          ExpansionTile(
            initiallyExpanded: grouped.length <= 6,
            title: Text(entry.value.first.unitCode ?? entry.key),
            subtitle: Text(
              '${entry.value.length} משימות · ${entry.value.where((t) => t.requiresAttention).length} דורשות תשומת לב',
            ),
            children: [
              for (final t in entry.value)
                ListTile(
                  selected: t.id == selectedId,
                  dense: true,
                  title: Text(t.titleHe),
                  subtitle: Text(taskStatusLabelHe(t.status)),
                  onTap: () => onSelect(t.id),
                ),
            ],
          ),
      ],
    );
  }
}

String _relative(DateTime dt) {
  final d = DateTime.now().toUtc().difference(dt);
  if (d.inMinutes < 60) return 'לפני ${d.inMinutes} דק׳';
  if (d.inHours < 48) return 'לפני ${d.inHours} שע׳';
  return 'לפני ${d.inDays} ימים';
}
