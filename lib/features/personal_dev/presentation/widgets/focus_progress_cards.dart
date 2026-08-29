import 'package:flutter/material.dart';

import '../../domain/config/pd_skill_config.dart';
import '../../domain/engine/skill_engine.dart';
import '../../../../core/theme/app_theme.dart';

class CurrentFocusCard extends StatelessWidget {
  const CurrentFocusCard({
    super.key,
    required this.primarySkill,
    this.secondarySkill,
    this.notes,
  });

  final PdSkillConfig primarySkill;
  final PdSkillConfig? secondarySkill;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.development.withValues(alpha: 0.12),
              Colors.white,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.center_focus_strong, color: AppColors.development),
                const SizedBox(width: 8),
                Text(
                  'Current Focus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FocusRow(
              label: 'Primary Skill',
              skill: primarySkill,
              emphasized: true,
            ),
            if (secondarySkill != null) ...[
              const SizedBox(height: 12),
              _FocusRow(
                label: 'Secondary Skill',
                skill: secondarySkill!,
                emphasized: false,
              ),
            ],
            if (notes != null && notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({
    required this.label,
    required this.skill,
    required this.emphasized,
  });

  final String label;
  final PdSkillConfig skill;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          skill.nameHe,
          style: emphasized
              ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )
              : Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
        ),
        Text(
          skill.descriptionHe,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
      ],
    );
  }
}

class ProgressStageCard extends StatelessWidget {
  const ProgressStageCard({
    super.key,
    required this.skill,
    required this.currentStageId,
    this.evaluation,
  });

  final PdSkillConfig skill;
  final String currentStageId;
  final PdStageEvaluation? evaluation;

  @override
  Widget build(BuildContext context) {
    final stage = skill.stageById(currentStageId) ?? skill.firstStage;
    final stageIndex = skill.stages.indexWhere((s) => s.id == stage.id);
    final progress = skill.stages.isEmpty
        ? 0.0
        : (stageIndex + 1) / skill.stages.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    skill.nameHe,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  '${stageIndex + 1}/${skill.stages.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.development,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.nameHe,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        stage.descriptionHe,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.line,
                color: AppColors.development,
              ),
            ),
            if (evaluation != null) ...[
              const SizedBox(height: 12),
              _MetricRow(
                label: 'אירועים בשלב',
                value:
                    '${evaluation!.eventsInStage}/${stage.minEvents}',
              ),
              _MetricRow(
                label: 'ציון ממוצע',
                value: evaluation!.avgScore.toStringAsFixed(1),
              ),
              _MetricRow(
                label: 'שיעור התנהגויות',
                value: '${(evaluation!.behaviorRate * 100).round()}%',
              ),
              if (evaluation!.readyToAdvance) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.development.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'מוכן לשלב הבא — רשום אירוע נוסף או העבר שלב.',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
