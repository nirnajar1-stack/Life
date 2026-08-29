import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/providers/personal_dev_providers.dart';
import 'event_log_screen.dart';
import 'practice_screen.dart';

class SkillScreen extends ConsumerWidget {
  const SkillScreen({super.key, required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skill = pdSkillRegistry[skillId];
    if (skill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skill')),
        body: const Center(child: Text('Skill לא נמצא')),
      );
    }

    final progressAsync = ref.watch(pdSkillProgressProvider(skillId));
    final evaluationAsync = ref.watch(pdStageEvaluationProvider(skillId));
    final eventsAsync = ref.watch(pdEventsForSkillProvider(skillId));
    final stageId =
        progressAsync.valueOrNull?.currentStageId ?? skill.firstStage.id;
    final stage = skill.stageById(stageId) ?? skill.firstStage;

    return Scaffold(
      appBar: AppBar(title: Text(skill.nameHe)),
      body: AppLayout.constrain(
        context: context,
        compact: 720,
        child: ListView(
          padding: AppLayout.listPadding,
          children: [
            Text(
              skill.descriptionHe,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'שלב נוכחי: ${stage.nameHe}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(stage.descriptionHe),
                    const SizedBox(height: 12),
                    Text(
                      'דרישות לשלב הבא: ${stage.minEvents} אירועים, '
                      'ציון ≥${stage.minAvgScore}, '
                      'התנהגויות ≥${(stage.minBehaviorRate * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventLogScreen(skillId: skillId),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('רישום אירוע'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.development,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PracticeScreen(skillId: skillId),
                      ),
                    ),
                    icon: const Icon(Icons.self_improvement_outlined),
                    label: const Text('תרגול'),
                  ),
                ),
              ],
            ),
            if (evaluationAsync.valueOrNull?.readyToAdvance == true) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () async {
                  try {
                    await ref
                        .read(personalDevControllerProvider.notifier)
                        .tryAdvanceStage(skillId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('עברת לשלב הבא')),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('שגיאה: $error')),
                    );
                  }
                },
                child: const Text('העבר לשלב הבא'),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'שלבים',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            ...skill.stages.map((s) {
              final active = s.id == stageId;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: active
                    ? AppColors.development.withValues(alpha: 0.06)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: active
                        ? AppColors.development
                        : AppColors.line,
                    child: Text(
                      '${s.order}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                  title: Text(s.nameHe),
                  subtitle: Text(s.descriptionHe),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              'אירועים אחרונים',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('שגיאה: $e'),
              data: (events) {
                if (events.isEmpty) {
                  return Text(
                    'עדיין אין אירועים — התחל ברישום או תרגול.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  );
                }
                final fmt = DateFormat('d/M HH:mm', 'he');
                return Column(
                  children: [
                    for (final record in events.take(8))
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(record.event.eventType.labelHe),
                          subtitle: Text(
                            '${fmt.format(record.event.occurredAt)} · '
                            'ציון ${record.eventSkill.performanceScore ?? "—"}',
                          ),
                          trailing: Text(
                            '${record.eventSkill.microBehaviors.length} התנהגויות',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
