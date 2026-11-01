import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/providers.dart';
import '../theme/portal_theme.dart';

class TaskDetailPanel extends ConsumerStatefulWidget {
  const TaskDetailPanel({super.key, required this.taskId, this.onClose});

  final String taskId;
  final VoidCallback? onClose;

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  final _message = TextEditingController();
  bool _busy = false;
  String _channel = 'internal';

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final canChangeStatus = profile?.isCaseManager == true ||
        profile?.hasRole(AppRole.superAdmin) == true ||
        profile?.hasRole(AppRole.systemAdmin) == true ||
        profile?.hasRole(AppRole.departmentManager) == true;
    final canPostInternal = canChangeStatus ||
        profile?.hasRole(AppRole.headquartersStaff) == true;
    final isGov = profile?.isGovRep == true && !canChangeStatus;

    return FutureBuilder(
      future: ref.read(taskServiceProvider).getTask(widget.taskId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final task = snap.data;
        if (task == null) {
          return const Center(child: Text('המשימה לא נמצאה או שאין הרשאה.'));
        }

        final channel = isGov ? 'interagency' : _channel;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.titleHe,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(taskStatusLabelHe(task.status))),
                  Chip(label: Text(taskPriorityLabelHe(task.priority))),
                  if (task.isOverdue)
                    const Chip(
                      label: Text('חורגת'),
                      backgroundColor: Color(0xFFFDE8E8),
                    ),
                  if (task.unitCode != null) Chip(label: Text(task.unitCode!)),
                ],
              ),
            ),
            if (task.descriptionHe != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(task.descriptionHe!),
              ),
            if (canChangeStatus)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final s in [
                      TaskStatus.inProgress,
                      TaskStatus.waitingExternal,
                      TaskStatus.blocked,
                      TaskStatus.completed,
                      TaskStatus.cancelled,
                    ])
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                try {
                                  await ref
                                      .read(taskServiceProvider)
                                      .updateStatus(task.id, s);
                                  ref.invalidate(tasksProvider);
                                  setState(() {});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'סטטוס עודכן ל-${taskStatusLabelHe(s)}',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('עדכון נכשל: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              },
                        child: Text(taskStatusLabelHe(s)),
                      ),
                  ],
                ),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isGov ? 'שיחה בין-משרדית' : 'תקשורת משימה',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (canPostInternal)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'internal', label: Text('פנימי')),
                    ButtonSegment(value: 'interagency', label: Text('בין-משרדי')),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (s) => setState(() => _channel = s.first),
                ),
              ),
            Expanded(
              child: FutureBuilder(
                future: ref.read(taskServiceProvider).listTaskMessages(
                      treatmentUnitId: task.treatmentUnitId,
                      channel: channel,
                    ),
                builder: (context, msgSnap) {
                  final msgs = msgSnap.data ?? [];
                  if (msgSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (msgs.isEmpty) {
                    return const Center(child: Text('אין הודעות עדיין.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      return Card(
                        child: ListTile(
                          title: Text(m.authorNameHe ?? m.authorId),
                          subtitle: Text(m.bodyHe),
                          trailing: Text(
                            m.createdAt.toLocal().toString().substring(0, 16),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (!profile!.isFamily)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        decoration: const InputDecoration(
                          hintText: 'הוספת הודעה…',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              final body = _message.text.trim();
                              if (body.isEmpty) return;
                              setState(() => _busy = true);
                              try {
                                await ref.read(taskServiceProvider).postUnitMessage(
                                      treatmentUnitId: task.treatmentUnitId,
                                      channel: channel,
                                      bodyHe: body,
                                    );
                                _message.clear();
                                setState(() {});
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('שליחה נכשלה: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      child: const Text('שליחה'),
                    ),
                  ],
                ),
              ),
            if (profile.isFamily)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'בני משפחה אינם רואים תקשורת פנימית/בין-משרדית של משימות.',
                  style: TextStyle(color: PortalColors.muted),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('פרטי משימה')),
      body: TaskDetailPanel(taskId: taskId),
    );
  }
}
