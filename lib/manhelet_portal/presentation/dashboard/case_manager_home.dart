import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/task_service.dart';
import '../../domain/providers.dart';
import '../theme/portal_theme.dart';

class CaseManagerHome extends ConsumerWidget {
  const CaseManagerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(_dashboardTasksProvider);
    final units = ref.watch(myUnitsProvider);
    final content = ref.watch(publishedContentProvider);
    final notifications = ref.watch(notificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_dashboardTasksProvider);
        ref.invalidate(myUnitsProvider);
        ref.invalidate(publishedContentProvider);
        ref.invalidate(notificationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'סביבת העבודה שלי',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          metrics.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('שגיאה בטעינת מדדים: $e'),
            data: (tasks) {
              final open = tasks.where((t) => t.isOpen).length;
              final overdue = tasks.where((t) => t.isOverdue).length;
              final attention =
                  tasks.where((t) => t.requiresAttention).length;
              final unread = notifications.valueOrNull
                      ?.where((n) => n.isUnread)
                      .length ??
                  0;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    label: 'משימות פתוחות',
                    value: open,
                    color: PortalColors.primary,
                    onTap: () {
                      ref.read(taskFiltersProvider.notifier).state =
                          const TaskFilters(openOnly: true);
                      context.go('/tasks');
                    },
                  ),
                  _MetricCard(
                    label: 'משימות חורגות',
                    value: overdue,
                    color: PortalColors.danger,
                    onTap: () {
                      ref.read(taskFiltersProvider.notifier).state =
                          const TaskFilters(onlyOverdue: true, openOnly: true);
                      context.go('/tasks');
                    },
                  ),
                  _MetricCard(
                    label: 'דורש תשומת לב',
                    value: attention,
                    color: PortalColors.warning,
                    onTap: () {
                      ref.read(taskFiltersProvider.notifier).state =
                          const TaskFilters(
                        onlyRequiresAttention: true,
                        openOnly: true,
                      );
                      context.go('/tasks');
                    },
                  ),
                  _MetricCard(
                    label: 'עדכונים חדשים',
                    value: unread,
                    color: PortalColors.accent,
                    onTap: () => context.go('/notifications'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('פעולות מהירות', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => context.go('/tasks?compose=1'),
                child: const Text('פתיחת משימה'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/families'),
                child: const Text('איתור משפחה'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/units'),
                child: const Text('יחידות טיפול'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('יחידות בטיפול', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          units.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('שגיאה: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Text('אין יחידות זמינות לפי ההרשאות.');
              }
              return Column(
                children: [
                  for (final u in list.take(8))
                    Card(
                      child: ListTile(
                        title: Text(u.titleHe),
                        subtitle: Text(
                          '${u.familyNameHe} · ${u.openTaskCount} משימות פתוחות · ${u.personCount} אנשים',
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.go('/units/${u.id}'),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('תוכן ארגוני', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          content.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('שגיאה: $e'),
            data: (items) {
              if (items.isEmpty) return const Text('אין פרסומים.');
              return Column(
                children: [
                  for (final c in items.take(5))
                    ListTile(
                      leading: const Icon(Icons.campaign_outlined),
                      title: Text(c.titleHe),
                      subtitle: Text(c.summaryHe ?? ''),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

final _dashboardTasksProvider =
    FutureProvider.autoDispose((ref) async {
  ref.watch(sessionProvider);
  return ref.watch(taskServiceProvider).listTasks(
        filters: const TaskFilters(openOnly: false),
      );
});

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PortalColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
