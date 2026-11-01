import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('אין התראות.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final n = items[i];
            return ListTile(
              leading: Icon(
                n.isUnread
                    ? Icons.notifications_active
                    : Icons.notifications_none,
              ),
              title: Text(
                n.titleHe,
                style: TextStyle(
                  fontWeight: n.isUnread ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              subtitle: Text(n.bodyHe ?? ''),
              onTap: () async {
                if (n.isUnread) {
                  await ref.read(notificationServiceProvider).markRead(n.id);
                  ref.invalidate(notificationsProvider);
                }
                final link = n.linkPath;
                if (link != null && link.contains('/tasks/')) {
                  final id = link.split('/tasks/').last;
                  if (context.mounted) context.go('/tasks/$id');
                }
              },
            );
          },
        );
      },
    );
  }
}
