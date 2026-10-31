import 'pd_character_trait_config.dart';

const curiosityTrait = PdCharacterTraitConfig(
  traitId: 'curiosity',
  nameHe: 'Curiosity',
  descriptionHe: 'נטייה לחקור, לשאול ולהבין לפני שמסיקים או פועלים.',
  behavioralDefinitionHe:
      'דפוס פעולה של בירור, שאילת שאלות ובדיקת הנחות לפני פתרון או שיפוט.',
  category: 'intellectual',
  characterMissions: [
    'שאל שאלה אחת לפני שאתה נותן את דעתך.',
    'בדוק הנחה אחת שהיית לך היום לפני שתגיב.',
  ],
  indicators: [
    PdCharacterIndicatorConfig(
      indicatorId: 'asked_before_advising',
      traitId: 'curiosity',
      labelHe: 'שאלתי שאלה לפני שהצעתי פתרון',
      descriptionHe: 'עצרתי לשאול לפני שמסרתי עצה או פתרון.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'tested_assumption',
      traitId: 'curiosity',
      labelHe: 'בדקתי הנחה שהייתה לי',
      descriptionHe: 'זיהיתי הנחה ובדקתי אותה במקום לקבל אותה כמובן מאליו.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'understood_before_judging',
      traitId: 'curiosity',
      labelHe: 'ביקשתי להבין את הסיבה לפני ששפטתי',
      descriptionHe: 'חיפשתי להבין את ההקשר לפני מסקנה או שיפוט.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'sought_info_before_decision',
      traitId: 'curiosity',
      labelHe: 'חיפשתי מידע נוסף לפני החלטה',
      descriptionHe: 'אספתי מידע נוסף לפני שקיבלתי החלטה.',
    ),
  ],
);

const reliabilityTrait = PdCharacterTraitConfig(
  traitId: 'reliability',
  nameHe: 'Reliability',
  descriptionHe: 'עקביות בין התחייבות לביצוע, ותקשורת מוקדמת כשיש שינוי.',
  behavioralDefinitionHe:
      'דפוס של עמידה בהתחייבויות, עדכון מראש, וסגירת loops פתוחים.',
  category: 'execution',
  characterMissions: [
    'סגור loop אחד פתוח היום.',
    'עדכן מראש אם לא תוכל לעמוד בהתחייבות.',
  ],
  indicators: [
    PdCharacterIndicatorConfig(
      indicatorId: 'kept_commitment',
      traitId: 'reliability',
      labelHe: 'עמדתי בהתחייבות',
      descriptionHe: 'ביצעתי את מה שהבטחתי בזמן ובאופן שניתן לסמוך עליו.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'updated_when_couldnt',
      traitId: 'reliability',
      labelHe: 'עדכנתי מראש אם לא יכולתי לעמוד בה',
      descriptionHe: 'הודעתי מוקדם כשלא יכולתי לעמוד בהתחייבות.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'closed_open_loop',
      traitId: 'reliability',
      labelHe: 'סגרתי Loop פתוח',
      descriptionHe: 'סגרתי follow-up או משימה שהייתה תלויה.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'avoided_unrealistic_commitment',
      traitId: 'reliability',
      labelHe: 'נמנעתי מהתחייבות לא ריאלית',
      descriptionHe: 'לא הבטחתי מעבר ליכולת או לזמן הזמין.',
    ),
  ],
);

const intellectualHumilityTrait = PdCharacterTraitConfig(
  traitId: 'intellectual_humility',
  nameHe: 'Intellectual Humility',
  descriptionHe: 'פתיחות לטעות, למידה ושינוי עמדה מול מידע חדש.',
  behavioralDefinitionHe:
      'דפוס של הודאה בגבולות הידע, חיפוש מידע מסתיר ועדכון עמדה.',
  category: 'intellectual',
  characterMissions: [
    'אמור "אני לא יודע" פעם אחת היום כשזה נכון.',
    'חפש מידע אחד שסותר את דעתך הנוכחית.',
  ],
  indicators: [
    PdCharacterIndicatorConfig(
      indicatorId: 'said_i_dont_know',
      traitId: 'intellectual_humility',
      labelHe: 'אמרתי "אני לא יודע" כשלא ידעתי',
      descriptionHe: 'הודיתי בחוסר ידע במקום לנחש או להמציא.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'sought_contradicting_info',
      traitId: 'intellectual_humility',
      labelHe: 'ביקשתי מידע שסותר את דעתי',
      descriptionHe: 'חיפשתי בכוונה נקודת מבט שונה.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'changed_mind_with_new_info',
      traitId: 'intellectual_humility',
      labelHe: 'שיניתי עמדה בעקבות מידע חדש',
      descriptionHe: 'עדכנתי עמדה כשהופיע מידע רלוונטי.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'admitted_mistake',
      traitId: 'intellectual_humility',
      labelHe: 'הודיתי בטעות בלי להגן עליה',
      descriptionHe: 'הכרתי בטעות בלי justify או הגנה.',
    ),
  ],
);

const personalResponsibilityTrait = PdCharacterTraitConfig(
  traitId: 'personal_responsibility',
  nameHe: 'Personal Responsibility',
  descriptionHe: 'לקיחת אחריות על החלק שלי ומעבר מבעיה לפעולה.',
  behavioralDefinitionHe:
      'דפוס של זיהוי מה בשליטה, אחריות אישית, ופעולה במקום האשמה.',
  category: 'agency',
  characterMissions: [
    'זהה מה בשליטתך באירוע אחד היום.',
    'עבור מבעיה לפעולה קונקרטית אחת.',
  ],
  indicators: [
    PdCharacterIndicatorConfig(
      indicatorId: 'identified_what_in_control',
      traitId: 'personal_responsibility',
      labelHe: 'זיהיתי מה בשליטתי',
      descriptionHe: 'הפרדתי בין מה שתלוי בי לבין מה שלא.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'took_ownership_of_my_part',
      traitId: 'personal_responsibility',
      labelHe: 'לקחתי אחריות על החלק שלי',
      descriptionHe: 'הכרתי בתרומה שלי למצב בלי להעביר אחריות.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'moved_from_problem_to_action',
      traitId: 'personal_responsibility',
      labelHe: 'עברתי מבעיה לפעולה',
      descriptionHe: 'הגדרתי צעד פעולה במקום להישאר בבעיה.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'avoided_blame_shifting',
      traitId: 'personal_responsibility',
      labelHe: 'נמנעתי מהעברת אחריות אוטומטית לאחר',
      descriptionHe: 'לא האשמתי אחרים באופן אוטומטי.',
    ),
  ],
);

const integrityTrait = PdCharacterTraitConfig(
  traitId: 'integrity',
  nameHe: 'Integrity',
  descriptionHe: 'עקביות בין עקרונות, מילים ופעולות.',
  behavioralDefinitionHe:
      'דפוס של פעולה בהתאם לערכים, אמת גם כשלא נוח, ועדכון כשמשתנה.',
  category: 'values',
  characterMissions: [
    'פעל בהתאם למה שאמרת באירוע אחד היום.',
    'עדכן במפורש אם שינית התחייבות.',
  ],
  indicators: [
    PdCharacterIndicatorConfig(
      indicatorId: 'acted_as_said',
      traitId: 'integrity',
      labelHe: 'פעלתי בהתאם למה שאמרתי',
      descriptionHe: 'התנהגותי תאמה את מה שהבטחתי או הצהרתי.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'told_truth_when_uncomfortable',
      traitId: 'integrity',
      labelHe: 'אמרתי אמת גם כשהיא פחות נוחה',
      descriptionHe: 'דיברתי בכנות גם כשזה לא נוח.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'kept_or_updated_commitment',
      traitId: 'integrity',
      labelHe: 'שמרתי על התחייבות או עדכנתי על שינוי',
      descriptionHe: 'עמדתי בהתחייבות או עדכנתי שקוף על שינוי.',
    ),
    PdCharacterIndicatorConfig(
      indicatorId: 'avoided_contradicting_principle',
      traitId: 'integrity',
      labelHe: 'נמנעתי מפעולה שסותרת עיקרון שהגדרתי',
      descriptionHe: 'לא פעלתי נגד עיקרון שהגדרתי לעצמי.',
    ),
  ],
);

final pdCharacterRegistry = <String, PdCharacterTraitConfig>{
  curiosityTrait.traitId: curiosityTrait,
  reliabilityTrait.traitId: reliabilityTrait,
  intellectualHumilityTrait.traitId: intellectualHumilityTrait,
  personalResponsibilityTrait.traitId: personalResponsibilityTrait,
  integrityTrait.traitId: integrityTrait,
};

List<PdCharacterTraitConfig> get allPdCharacterTraits =>
    pdCharacterRegistry.values.where((t) => t.active).toList();

PdCharacterTraitConfig? pdCharacterTraitById(String id) =>
    pdCharacterRegistry[id];
