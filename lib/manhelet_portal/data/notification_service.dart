import '../domain/models.dart';
import 'portal_client.dart';

class NotificationService {
  Future<List<PortalNotification>> listMine({bool unreadOnly = false}) async {
    var filtered = portalClient
        .from('notifications')
        .select('id, title_he, body_he, link_path, created_at, read_at');
    if (unreadOnly) {
      filtered = filtered.isFilter('read_at', null);
    }
    final rows = await filtered.order('created_at', ascending: false).limit(100);
    return (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return PortalNotification(
        id: m['id'] as String,
        titleHe: m['title_he'] as String,
        bodyHe: m['body_he'] as String?,
        linkPath: m['link_path'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toUtc(),
        readAt: m['read_at'] == null
            ? null
            : DateTime.tryParse(m['read_at'] as String)?.toUtc(),
      );
    }).toList();
  }

  Future<void> markRead(String id) async {
    await portalClient.from('notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
