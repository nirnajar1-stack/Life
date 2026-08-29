import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/models/pd_enums.dart';
import '../../domain/providers/personal_dev_providers.dart';

/// Minimal practice / drill entry — logs as practice event type.
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.skillId});

  final String skillId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final _notesController = TextEditingController();
  final _checked = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(PdEventType type) async {
    final skill = pdSkillRegistry[widget.skillId];
    if (skill == null) return;

    final progress =
        await ref.read(pdSkillProgressProvider(widget.skillId).future);
    final stageId = progress?.currentStageId ?? skill.firstStage.id;

    setState(() => _saving = true);
    try {
      await ref.read(personalDevControllerProvider.notifier).logEvent(
            skillId: widget.skillId,
            eventType: type,
            microBehaviors: _checked.toList(),
            stageAtEvent: stageId,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            difficulty: PdContextLevel.low,
            emotionalActivation: PdContextLevel.low,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('התרגול נרשם')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = pdSkillRegistry[widget.skillId];
    if (skill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('תרגול')),
        body: const Center(child: Text('Skill לא נמצא')),
      );
    }

    final progressAsync = ref.watch(pdSkillProgressProvider(widget.skillId));
    final stageId =
        progressAsync.valueOrNull?.currentStageId ?? skill.firstStage.id;
    final stage = skill.stageById(stageId) ?? skill.firstStage;
    final stageBehaviors =
        skill.microBehaviors.where((b) => b.stageId == stageId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('תרגול')),
      body: AppLayout.constrain(
        context: context,
        compact: 640,
        child: ListView(
          padding: AppLayout.listPadding,
          children: [
            Text(
              '${skill.nameHe} · ${stage.nameHe}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'תרגל התנהגויות observable לשלב הנוכחי. '
              'Phase 0 — כניסה מהירה לתרגול מבוקר.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 16),
            if (stageBehaviors.isEmpty)
              Text(
                'אין micro-behaviors ייעודיים לשלב — סמן מה שרלוונטי:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...stageBehaviors.map((behavior) {
              return CheckboxListTile(
                value: _checked.contains(behavior.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _checked.add(behavior.id);
                    } else {
                      _checked.remove(behavior.id);
                    }
                  });
                },
                title: Text(behavior.labelHe),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'מה תרגלת?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _save(PdEventType.practice),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.development,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('שמור תרגול'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => _save(PdEventType.drill),
              child: const Text('Drill קצר'),
            ),
          ],
        ),
      ),
    );
  }
}
