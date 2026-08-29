import 'pd_skill_config.dart';

/// Self Regulation — first skill, Layer 1 (Self Foundation).
const selfRegulationSkill = PdSkillConfig(
  id: 'self_regulation',
  nameHe: 'ויסות עצמי',
  descriptionHe:
      'זיהוי מצב פנימי, עצירה לפני תגובה, ובחירה מודעת — בסיס לכל Skill מתקדם.',
  layer: 1,
  stages: [
    PdStageConfig(
      id: 'awareness',
      nameHe: 'מודעות',
      descriptionHe: 'מזהה מתי מופעלת תגובה רגשית או גופנית.',
      order: 1,
      minEvents: 3,
      minAvgScore: 2.5,
      minBehaviorRate: 0.3,
    ),
    PdStageConfig(
      id: 'pause',
      nameHe: 'עצירה',
      descriptionHe: 'יוצר רווח לפני תגובה אוטומטית.',
      order: 2,
      minEvents: 4,
      minAvgScore: 3.0,
      minBehaviorRate: 0.4,
    ),
    PdStageConfig(
      id: 'label',
      nameHe: 'תיוג',
      descriptionHe: 'מזהה וממיין את הרגש או הצורך שמתחת לתגובה.',
      order: 3,
      minEvents: 5,
      minAvgScore: 3.2,
      minBehaviorRate: 0.5,
    ),
    PdStageConfig(
      id: 'choice',
      nameHe: 'בחירה',
      descriptionHe: 'בוחר תגובה מכוונת במקום אוטומטית.',
      order: 4,
      minEvents: 6,
      minAvgScore: 3.5,
      minBehaviorRate: 0.55,
    ),
    PdStageConfig(
      id: 'integrated_mastery',
      nameHe: 'שליטה משולבת',
      descriptionHe: 'ויסות טבעי גם תחת לחץ ועומס.',
      order: 5,
      minEvents: 8,
      minAvgScore: 4.0,
      minBehaviorRate: 0.65,
    ),
  ],
  microBehaviors: [
    PdMicroBehavior(
      id: 'noticed_activation',
      labelHe: 'שמתי לב להפעלה (רגש/גוף)',
      stageId: 'awareness',
    ),
    PdMicroBehavior(
      id: 'paused_before_reacting',
      labelHe: 'עצרתי לפני שתגבתי',
      stageId: 'pause',
    ),
    PdMicroBehavior(
      id: 'named_emotion',
      labelHe: 'תייגתי את הרגש או הצורך',
      stageId: 'label',
    ),
    PdMicroBehavior(
      id: 'noticed_body_signal',
      labelHe: 'זיהיתי אות גופני (מתח, דופק, נשימה)',
      stageId: 'awareness',
    ),
    PdMicroBehavior(
      id: 'chose_response',
      labelHe: 'בחרתי תגובה במקום לפעול אוטומטית',
      stageId: 'choice',
    ),
    PdMicroBehavior(
      id: 'reflected_after',
      labelHe: 'עשיתי רפלקציה קצרה אחרי האירוע',
      stageId: 'integrated_mastery',
    ),
    PdMicroBehavior(
      id: 'used_breath_or_grounding',
      labelHe: 'השתמשתי בנשימה או grounding',
      stageId: 'pause',
    ),
  ],
);

/// Assertiveness — Layer 3, validated via config-only addition (Phase 1).
const assertivenessSkill = PdSkillConfig(
  id: 'assertiveness',
  nameHe: 'אסרטיביות',
  descriptionHe:
      'יכולת להביע עמדה, צורך, בקשה או גבול בצורה ברורה ורגועה, '
      'גם כאשר קיימת התנגדות או פער סמכות.',
  layer: 3,
  contextDimensions: [
    PdContextDimension.relationshipType,
    PdContextDimension.powerGap,
    PdContextDimension.outcomeImportance,
    PdContextDimension.difficulty,
    PdContextDimension.emotionalActivation,
  ],
  relationshipTypeSuggestions: const [
    'עמיתים',
    'מנהל בכיר',
    'צוות',
    'לקוח',
    'משפחה',
  ],
  stages: [
    PdStageConfig(
      id: 'awareness',
      nameHe: 'מודעות',
      descriptionHe: 'מזהה מתי מוותר, מתנצל מיותר, או לא מביע עמדה.',
      order: 1,
      minEvents: 3,
      minAvgScore: 2.5,
      minBehaviorRate: 0.3,
    ),
    PdStageConfig(
      id: 'low_stakes_practice',
      nameHe: 'תרגול סיכון נמוך',
      descriptionHe: 'מתרגל ביטוי ישיר במצבים קלים ומוגנים.',
      order: 2,
      minEvents: 4,
      minAvgScore: 3.0,
      minBehaviorRate: 0.4,
    ),
    PdStageConfig(
      id: 'real_world_application',
      nameHe: 'יישום בעולם האמיתי',
      descriptionHe: 'מביע עמדה ובקשות במצבים אמיתיים.',
      order: 3,
      minEvents: 5,
      minAvgScore: 3.2,
      minBehaviorRate: 0.5,
    ),
    PdStageConfig(
      id: 'high_stakes_application',
      nameHe: 'יישום סיכון גבוה',
      descriptionHe: 'שומר על עמדה גם מול pushback או פער סמכות.',
      order: 4,
      minEvents: 6,
      minAvgScore: 3.5,
      minBehaviorRate: 0.55,
    ),
    PdStageConfig(
      id: 'integrated_mastery',
      nameHe: 'שליטה משולבת',
      descriptionHe: 'אסרטיביות טבעית, רגועה ועקבית.',
      order: 5,
      minEvents: 8,
      minAvgScore: 4.0,
      minBehaviorRate: 0.65,
    ),
  ],
  microBehaviors: [
    PdMicroBehavior(
      id: 'expressed_actual_opinion',
      labelHe: 'הבעתי עמדה אמיתית',
      stageId: 'awareness',
    ),
    PdMicroBehavior(
      id: 'made_clear_request',
      labelHe: 'ביצעתי בקשה ברורה',
      stageId: 'low_stakes_practice',
    ),
    PdMicroBehavior(
      id: 'avoided_unnecessary_apology',
      labelHe: 'נמנעתי מהתנצלות / גמגום מיותר',
      stageId: 'low_stakes_practice',
    ),
    PdMicroBehavior(
      id: 'maintained_position_after_pushback',
      labelHe: 'שמרתי על עמדה אחרי pushback',
      stageId: 'high_stakes_application',
    ),
    PdMicroBehavior(
      id: 'used_calm_direct_language',
      labelHe: 'השתמשתי בשפה רגועה וישירה',
      stageId: 'real_world_application',
    ),
  ],
  drills: [
    PdDrillConfig(
      id: 'clear_request_drill',
      nameHe: 'Clear Request Drill',
      descriptionHe: 'תרגל בקשה ישירה בלי התנצלות מיותרת — משפט אחד, ברור.',
      suggestedBehaviorIds: ['made_clear_request', 'avoided_unnecessary_apology'],
      stageId: 'low_stakes_practice',
    ),
    PdDrillConfig(
      id: 'disagreement_without_apology_drill',
      nameHe: 'Disagreement Without Apology Drill',
      descriptionHe: 'תרגל אי-הסכמה קצרה בלי "סליחה" או גמגום.',
      suggestedBehaviorIds: [
        'expressed_actual_opinion',
        'avoided_unnecessary_apology',
        'used_calm_direct_language',
      ],
      stageId: 'low_stakes_practice',
    ),
  ],
  realWorldMissions: [
    PdMissionConfig(
      id: 'express_preference',
      labelHe: 'להביע העדפה במקום "לא משנה לי"',
      stageId: 'real_world_application',
    ),
    PdMissionConfig(
      id: 'direct_request',
      labelHe: 'לבקש משהו בצורה ישירה',
      stageId: 'real_world_application',
    ),
    PdMissionConfig(
      id: 'disagree_without_apology',
      labelHe: 'להביע אי הסכמה אחת בלי להתנצל',
      stageId: 'real_world_application',
    ),
    PdMissionConfig(
      id: 'set_small_boundary',
      labelHe: 'להציב גבול קטן',
      stageId: 'real_world_application',
    ),
    PdMissionConfig(
      id: 'maintain_position_pushback',
      labelHe: 'לשמור על עמדה אחרי pushback',
      stageId: 'high_stakes_application',
    ),
  ],
);

/// All registered skills — add new entries here, not new UI screens.
final pdSkillRegistry = <String, PdSkillConfig>{
  'self_regulation': selfRegulationSkill,
  'assertiveness': assertivenessSkill,
};

PdSkillConfig? pdSkillById(String id) => pdSkillRegistry[id];

List<PdSkillConfig> get allPdSkills => pdSkillRegistry.values.toList();
