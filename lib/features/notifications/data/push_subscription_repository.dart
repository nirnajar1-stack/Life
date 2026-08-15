import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class PushSubscriptionRepository {
  PushSubscriptionRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'push_subscriptions';

  Future<void> saveSubscriptionJson(String subscriptionJson) async {
    final Map<String, dynamic> json =
        jsonDecode(subscriptionJson) as Map<String, dynamic>;
    final endpoint = json['endpoint'] as String?;
    final keys = json['keys'] as Map<String, dynamic>?;
    final p256dh = keys?['p256dh'] as String?;
    final auth = keys?['auth'] as String?;

    if (endpoint == null || p256dh == null || auth == null) {
      throw const FormatException('Invalid push subscription payload');
    }

    await _client.from(_table).upsert(
      {
        'endpoint': endpoint,
        'p256dh': p256dh,
        'auth': auth,
        'user_agent': 'life_app_web',
      },
      onConflict: 'endpoint',
    );
  }
}
