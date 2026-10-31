import 'pd_character_trait_config.dart';

/// Config-driven links: Skill micro-behavior → Character indicator evidence.
const pdSkillCharacterMappings = <PdSkillCharacterMapping>[
  PdSkillCharacterMapping(
    skillId: 'clear_communication',
    microBehaviorId: 'main_point_stated_early',
    traitId: 'curiosity',
    indicatorId: 'asked_before_advising',
  ),
  PdSkillCharacterMapping(
    skillId: 'assertiveness',
    microBehaviorId: 'maintained_position_after_pushback',
    traitId: 'integrity',
    indicatorId: 'kept_or_updated_commitment',
  ),
  PdSkillCharacterMapping(
    skillId: 'self_regulation',
    microBehaviorId: 'reflected_after',
    traitId: 'intellectual_humility',
    indicatorId: 'admitted_mistake',
  ),
];

List<PdSkillCharacterMapping> mappingsForEvent({
  required String skillId,
  required List<String> checkedBehaviorIds,
}) {
  return pdSkillCharacterMappings
      .where(
        (m) =>
            m.skillId == skillId && checkedBehaviorIds.contains(m.microBehaviorId),
      )
      .toList();
}
