import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notifications.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/push_subscription_repository.dart';

final pushSubscriptionRepositoryProvider =
    Provider<PushSubscriptionRepository>((ref) {
  return PushSubscriptionRepository(ref.watch(supabaseClientProvider));
});

/// Browser permission: granted / denied / default / unsupported.
final webPushPermissionProvider = Provider<String>((ref) {
  ref.watch(webPushRefreshProvider);
  return WebPushClient.permission;
});

final webPushRefreshProvider = StateProvider<int>((ref) => 0);
