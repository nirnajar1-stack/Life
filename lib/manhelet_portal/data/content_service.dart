import '../domain/models.dart';
import 'portal_client.dart';

class ContentService {
  Future<List<ContentItem>> listPublished({int limit = 20}) async {
    final rows = await portalClient
        .from('content_items')
        .select('id, title_he, summary_he, status, published_at')
        .eq('status', 'published')
        .isFilter('deleted_at', null)
        .order('published_at', ascending: false)
        .limit(limit);

    return (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ContentItem(
        id: m['id'] as String,
        titleHe: m['title_he'] as String,
        summaryHe: m['summary_he'] as String?,
        status: m['status'] as String,
        publishedAt: m['published_at'] == null
            ? null
            : DateTime.tryParse(m['published_at'] as String)?.toUtc(),
      );
    }).toList();
  }
}
