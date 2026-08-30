import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/character/config/pd_character_registry.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/providers/personal_dev_providers.dart';
import '../screens/character_screen.dart';
import '../widgets/development_map_card.dart';
import '../widgets/focus_progress_cards.dart';
import '../widgets/skill_list_tile.dart';
import 'event_log_screen.dart';
import 'practice_screen.dart';

class PersonalDevScreen extends ConsumerWidget {
  const PersonalDevScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(pdFocusCycleProvider);
    final focus = focusAsync.valueOrNull;
    final primarySkillId = focus?.primarySkillId ?? allPdSkills.first.id;
    final primarySkill = pdSkillRegistry[primarySkillId] ?? allPdSkills.first;
    final secondarySkill = focus?.secondarySkillId != null
        ? pdSkillRegistry[focus!.secondarySkillId!]
        : null;
    final characterTrait = focus?.traitFocus != null
        ? pdCharacterRegistry[focus!.traitFocus!]
        : null;

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
              primarySkill: primarySkill,
              secondarySkill: secondarySkill,
              characterTrait: characterTrait,
              notes: focus?.notes,
            ),
            const SizedBox(height: 16),
            AppSectionHeader(
              title: 'Character',
              actionLabel: 'פתח',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CharacterScreen()),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.auto_stories_outlined,
                    color: AppColors.development),
                title: const Text('Character Layer'),
                subtitle: const Text(
                  'ראיות התנהגותיות — לא Skills ולא ציונים',
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CharacterScreen()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppSectionHeader(title: 'Progress / Stage'),
            ...allPdSkills.map(
              (skill) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkillProgressCard(skillId: skill.id),
              ),
            ),
            const SizedBox(height: 4),
            AppSectionHeader(title: 'Skills'),
            ...allPdSkills.map(
              (skill) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SkillListTile(skillId: skill.id),
              ),
            ),
            const SizedBox(height: 16),
            DevelopmentMapCard(
              skills: allPdSkills,
              highlightLayer: primarySkill.layer,
            ),
            const SizedBox(height: 16),
            AppSectionHeader(title: 'פעולות — Primary Focus'),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EventLogScreen(skillId: primarySkill.id),
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
                        builder: (_) =>
                            PracticeScreen(skillId: primarySkill.id),
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

/// Compact progress card driven by skillId — works for any registered skill.
class SkillProgressCard extends ConsumerWidget {
  const SkillProgressCard({super.key, required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skill = pdSkillRegistry[skillId];
    if (skill == null) return const SizedBox.shrink();

    final progressAsync = ref.watch(pdSkillProgressProvider(skillId));
    final evaluationAsync = ref.watch(pdStageEvaluationProvider(skillId));
    final stageId =
        progressAsync.valueOrNull?.currentStageId ?? skill.firstStage.id;

    return ProgressStageCard(
      skill: skill,
      currentStageId: stageId,
      evaluation: evaluationAsync.valueOrNull,
    );
  }
}
