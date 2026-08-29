/// Configuration for a single development skill (config-driven engine).
class PdSkillConfig {
  const PdSkillConfig({
    required this.id,
    required this.nameHe,
    required this.descriptionHe,
    required this.layer,
    required this.stages,
    required this.microBehaviors,
  });

  final String id;
  final String nameHe;
  final String descriptionHe;
  final int layer;
  final List<PdStageConfig> stages;
  final List<PdMicroBehavior> microBehaviors;

  PdStageConfig? stageById(String id) {
    for (final stage in stages) {
      if (stage.id == id) return stage;
    }
    return null;
  }

  PdStageConfig get firstStage => stages.first;

  PdStageConfig? nextStageAfter(String stageId) {
    final index = stages.indexWhere((s) => s.id == stageId);
    if (index < 0 || index >= stages.length - 1) return null;
    return stages[index + 1];
  }
}

class PdStageConfig {
  const PdStageConfig({
    required this.id,
    required this.nameHe,
    required this.descriptionHe,
    required this.order,
    required this.minEvents,
    required this.minAvgScore,
    required this.minBehaviorRate,
  });

  final String id;
  final String nameHe;
  final String descriptionHe;
  final int order;
  final int minEvents;
  final double minAvgScore;
  final double minBehaviorRate;
}

class PdMicroBehavior {
  const PdMicroBehavior({
    required this.id,
    required this.labelHe,
    required this.stageId,
  });

  final String id;
  final String labelHe;
  final String stageId;
}
