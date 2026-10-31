import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/notifications/notifications.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/notification_providers.dart';

class NotificationCard extends ConsumerStatefulWidget {
  const NotificationCard({super.key});

  @override
  ConsumerState<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<NotificationCard> {
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    try {
      final json = await WebPushClient.subscribe(SupabaseConfig.vapidPublicKey);
      await ref.read(pushSubscriptionRepositoryProvider).saveSubscriptionJson(json);
      ref.read(webPushRefreshProvider.notifier).state++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('התראות הופעלו במכשיר הזה')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = '$error'.contains('denied')
          ? 'ההרשאה נחסמה בדפדפן. אפשר להפעיל מחדש בהגדרות האתר.'
          : 'לא ניתן להפעיל התראות: $error';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _test() {
    final ok = WebPushClient.showLocal(
      'ניהול החיים',
      'ככה תיראה תזכורת של משימות להיום',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'נשלחה התראת בדיקה' : 'אין הרשאה להתראות'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permission = ref.watch(webPushPermissionProvider);
    if (permission == 'unsupported') {
      return const SizedBox.shrink();
    }

    final enabled = permission == 'granted';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (enabled ? AppColors.expenses : AppColors.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(
              enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: enabled ? AppColors.expenses : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? 'תזכורות בוקר פעילות' : 'תזכורות במכשיר',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  enabled
                      ? 'כל בוקר ב־8:00 אם יש משימות להיום או באיחור'
                      : 'קבל תזכורת בוקר על משימות להיום',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          if (enabled)
            TextButton(
              onPressed: _busy ? null : _test,
              child: const Text('בדיקה'),
            )
          else
            FilledButton(
              onPressed: _busy ? null : _enable,
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('הפעל'),
            ),
        ],
      ),
    );
  }
}
