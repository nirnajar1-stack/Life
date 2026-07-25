/// Maps noisy raw category labels from the DB into a small set of
/// parent categories used for clean financial insights.
class ExpenseCategoryTaxonomy {
  const ExpenseCategoryTaxonomy._();

  static const String housing = 'דיור';
  static const String food = 'מזון';
  static const String transport = 'תחבורה';
  static const String health = 'בריאות';
  static const String leisure = 'פנאי';
  static const String tech = 'טכנולוגיה וציוד';
  static const String gifts = 'מתנות ותרומות';
  static const String personal = 'אישי ואחר';

  static const List<String> allParents = [
    housing,
    food,
    transport,
    health,
    leisure,
    tech,
    gifts,
    personal,
  ];

  /// Exact-match map after trim (covers the known DB labels).
  static const Map<String, String> _exact = {
    'דירה': housing,
    'ריהוט ועיצוב הבית': housing,
    'מוצרים לבית': housing,
    'צרכי בית ופנאי': housing,
    'מזון': food,
    'מזון ומשקאות': food,
    'אוכל': food,
    'אוכל ושתיה': food,
    'מזון ושתיה': food,
    'אוכל בחוץ': food,
    'מסעדות וברים': food,
    'משקאות': food,
    'תחבורה': transport,
    'רכב': transport,
    'רכב ותחבורה': transport,
    'בריאות': health,
    'בריאות ונפש': health,
    'בריאות ויופי': health,
    'בריאות וכושר': health,
    'יופי וטיפוח': health,
    'נופש ופנאי': leisure,
    'בילויים': leisure,
    'בילוי': leisure,
    'בידור': leisure,
    'ציוד': tech,
    'מדיה/טכנולגיה': tech,
    'אלקטרוניקה': tech,
    'שירותים דיגיטליים': tech,
    'מתנות': gifts,
    'תרומות': gifts,
    'הוצאות אישיות': personal,
    'הוצאות עבודה': personal,
    'קניות': personal,
    'שונות': personal,
    'צרכי יום יום': personal,
    'צרכים יומיומיים': personal,
    'שירותים ואחר': personal,
  };

  /// Keyword fallbacks for future / unknown labels.
  static const List<(String keyword, String parent)> _keywords = [
    ('דיר', housing),
    ('בית', housing),
    ('ריהוט', housing),
    ('מזון', food),
    ('אוכל', food),
    ('מסעד', food),
    ('שתיה', food),
    ('משקה', food),
    ('תחבורה', transport),
    ('רכב', transport),
    ('בריאות', health),
    ('כושר', health),
    ('יופי', health),
    ('טיפוח', health),
    ('נופש', leisure),
    ('פנאי', leisure),
    ('בילוי', leisure),
    ('בידור', leisure),
    ('טכנול', tech),
    ('מדיה', tech),
    ('אלקטרו', tech),
    ('ציוד', tech),
    ('דיגיטל', tech),
    ('מתנ', gifts),
    ('תרום', gifts),
  ];

  /// Resolves a raw DB category into a parent bucket.
  static String resolveParent(String? rawCategory) {
    final cleaned = (rawCategory ?? '').trim();
    if (cleaned.isEmpty) return personal;

    final exact = _exact[cleaned];
    if (exact != null) return exact;

    final lower = cleaned.toLowerCase();
    for (final (keyword, parent) in _keywords) {
      if (lower.contains(keyword)) return parent;
    }
    return personal;
  }
}
