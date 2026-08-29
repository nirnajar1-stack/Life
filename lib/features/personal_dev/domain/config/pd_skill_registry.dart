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

/// All registered skills — add new entries here, not new UI screens.
final pdSkillRegistry = <String, PdSkillConfig>{
  'self_regulation': selfRegulationSkill,
};

PdSkillConfig? pdSkillById(String id) => pdSkillRegistry[id];

List<PdSkillConfig> get allPdSkills => pdSkillRegistry.values.toList();
