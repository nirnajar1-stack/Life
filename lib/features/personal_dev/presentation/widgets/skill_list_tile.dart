import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/providers/personal_dev_providers.dart';
import '../screens/skill_screen.dart';

class SkillListTile extends ConsumerWidget {
  const SkillListTile({super.key, required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skill = pdSkillRegistry[skillId];
    if (skill == null) return const SizedBox.shrink();

    final progressAsync = ref.watch(pdSkillProgressProvider(skillId));
    final stageId =
        progressAsync.valueOrNull?.currentStageId ?? skill.firstStage.id;
    final stage = skill.stageById(stageId) ?? skill.firstStage;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.development.withValues(alpha: 0.15),
          child: Icon(Icons.psychology_outlined, color: AppColors.development),
        ),
        title: Text(
          skill.nameHe,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('שלב: ${stage.nameHe}'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SkillScreen(skillId: skillId)),
        ),
      ),
    );
  }
}
