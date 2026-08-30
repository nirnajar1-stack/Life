/// Nine-layer development map (Layer A = Self Foundation).
class PdLayer {
  const PdLayer({
    required this.number,
    required this.nameHe,
    required this.descriptionHe,
  });

  final int number;
  final String nameHe;
  final String descriptionHe;
}

const pdDevelopmentLayers = <PdLayer>[
  PdLayer(
    number: 1,
    nameHe: 'יסוד עצמי',
    descriptionHe: 'ויסות, מודעות פנימית, יציבות רגשית',
  ),
  PdLayer(
    number: 2,
    nameHe: 'תקשורת בסיסית',
    descriptionHe: 'הקשבה, ביטוי ברור, משוב',
  ),
  PdLayer(
    number: 3,
    nameHe: 'אסרטיביות',
    descriptionHe: 'גבולות, בקשות, סירוב בריא',
  ),
  PdLayer(
    number: 4,
    nameHe: 'ניהול קונפליקט',
    descriptionHe: 'הבחנה, דה-אסקלציה, פשרה',
  ),
  PdLayer(
    number: 5,
    nameHe: 'קבלת החלטות',
    descriptionHe: 'הערכת מידע, עדיפויות, פעולה',
  ),
  PdLayer(
    number: 6,
    nameHe: 'מנהיגות בין-אישית',
    descriptionHe: 'השפעה, אמון, אחריות',
  ),
  PdLayer(
    number: 7,
    nameHe: 'מומחיות מצבית',
    descriptionHe: 'ביצוע תחת לחץ, הקשרים מורכבים',
  ),
  PdLayer(
    number: 8,
    nameHe: 'אינטגרציה',
    descriptionHe: 'חיבור Skills לתכונות אופי',
  ),
  PdLayer(
    number: 9,
    nameHe: 'שליטה מצבית',
    descriptionHe: 'ביצועים גבוהים בהקשרים קריטיים',
  ),
];
