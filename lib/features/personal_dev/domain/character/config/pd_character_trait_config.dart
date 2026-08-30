/// Character trait configuration — separate from Skill engine (no stages/scores).
class PdCharacterTraitConfig {
  const PdCharacterTraitConfig({
    required this.traitId,
    required this.nameHe,
    required this.descriptionHe,
    required this.behavioralDefinitionHe,
    required this.category,
    required this.indicators,
    this.characterMissions = const [],
    this.active = true,
  });

  final String traitId;
  final String nameHe;
  final String descriptionHe;
  final String behavioralDefinitionHe;
  final String category;
  final List<PdCharacterIndicatorConfig> indicators;
  final List<String> characterMissions;
  final bool active;

  PdCharacterIndicatorConfig? indicatorById(String id) {
    for (final indicator in indicators) {
      if (indicator.indicatorId == id) return indicator;
    }
    return null;
  }
}

class PdCharacterIndicatorConfig {
  const PdCharacterIndicatorConfig({
    required this.indicatorId,
    required this.traitId,
    required this.labelHe,
    required this.descriptionHe,
  });

  final String indicatorId;
  final String traitId;
  final String labelHe;
  final String descriptionHe;
}

/// Maps a skill micro-behavior to a character indicator (config-driven, optional).
class PdSkillCharacterMapping {
  const PdSkillCharacterMapping({
    required this.skillId,
    required this.microBehaviorId,
    required this.traitId,
    required this.indicatorId,
  });

  final String skillId;
  final String microBehaviorId;
  final String traitId;
  final String indicatorId;
}
