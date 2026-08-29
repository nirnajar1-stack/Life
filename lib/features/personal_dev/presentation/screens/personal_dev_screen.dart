import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/config/pd_skill_config.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/providers/personal_dev_providers.dart';
import '../widgets/development_map_card.dart';
import '../widgets/focus_progress_cards.dart';
import 'event_log_screen.dart';
import 'practice_screen.dart';
import 'skill_screen.dart';

class PersonalDevScreen extends ConsumerWidget {
  const PersonalDevScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(pdFocusCycleProvider);
    final primarySkillId =
        focusAsync.valueOrNull?.primarySkillId ?? selfRegulationSkill.id;
    final skill = pdSkillRegistry[primarySkillId] ?? selfRegulationSkill;
    final progressAsync = ref.watch(pdSkillProgressProvider(primarySkillId));
    final evaluationAsync =
        ref.watch(pdStageEvaluationProvider(primarySkillId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('פיתוח'),
      ),
      body: AppLayout.constrain(
        context: context,
        compact: 840,
        child: ListView(
          padding: AppLayout.listPadding,
          children: [
            CurrentFocusCard(
              skill: skill,
              secondarySkill: focusAsync.valueOrNull?.secondarySkillId != null
                  ? pdSkillRegistry[
                      focusAsync.valueOrNull!.secondarySkillId!]
                  : null,
              notes: focusAsync.valueOrNull?.notes,
            ),
            const SizedBox(height: 16),
            ProgressStageCard(
              skill: skill,
              currentStageId: progressAsync.valueOrNull?.currentStageId ??
                  skill.firstStage.id,
              evaluation: evaluationAsync.valueOrNull,
            ),
            const SizedBox(height: 16),
            AppSectionHeader(title: 'Skills'),
            _SkillTile(
              skill: skill,
              stageId: progressAsync.valueOrNull?.currentStageId ??
                  skill.firstStage.id,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SkillScreen(skillId: skill.id),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DevelopmentMapCard(
              skills: allPdSkills,
              highlightLayer: skill.layer,
            ),
            const SizedBox(height: 16),
            AppSectionHeader(title: 'פעולות'),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventLogScreen(skillId: skill.id),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('רישום אירוע'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.development,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PracticeScreen(skillId: skill.id),
                      ),
                    ),
                    icon: const Icon(Icons.self_improvement_outlined),
                    label: const Text('תרגול'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.skill,
    required this.stageId,
    required this.onTap,
  });

  final PdSkillConfig skill;
  final String stageId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stage = skill.stageById(stageId) ?? skill.firstStage;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.development.withValues(alpha: 0.15),
          child: Icon(Icons.psychology_outlined, color: AppColors.development),
        ),
        title: Text(skill.nameHe, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('שלב: ${stage.nameHe}'),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
