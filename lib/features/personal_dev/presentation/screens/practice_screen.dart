import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/config/pd_skill_config.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/models/pd_enums.dart';
import '../../domain/providers/personal_dev_providers.dart';

/// Practice / drill entry — drills and behaviors come from skill config.
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({
    super.key,
    required this.skillId,
    this.drillId,
  });

  final String skillId;
  final String? drillId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final _notesController = TextEditingController();
  final _checked = <String>{};
  String? _selectedDrillId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDrillId = widget.drillId;
    _applyDrillDefaults();
  }

  void _applyDrillDefaults() {
    final skill = pdSkillRegistry[widget.skillId];
    if (skill == null || _selectedDrillId == null) return;
    PdDrillConfig? drill;
    for (final candidate in skill.drills) {
      if (candidate.id == _selectedDrillId) {
        drill = candidate;
        break;
      }
    }
    if (drill == null) return;
    _checked
      ..clear()
      ..addAll(drill.suggestedBehaviorIds);
    if (_notesController.text.isEmpty) {
      _notesController.text = drill.descriptionHe;
    }
  }

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
    final drillId = _selectedDrillId;

    setState(() => _saving = true);
    try {
      await ref.read(personalDevControllerProvider.notifier).logEvent(
            skillId: widget.skillId,
            eventType: type,
            microBehaviors: _checked.toList(),
            stageAtEvent: stageId,
            situationId: drillId,
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
    final behaviorSource =
        stageBehaviors.isNotEmpty ? stageBehaviors : skill.microBehaviors;

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
              'Drills והתנהגויות מוגדרים ב-config של ה-Skill.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            if (skill.drills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Drills',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              ...skill.drills.map((drill) {
                final selected = _selectedDrillId == drill.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: selected
                      ? AppColors.development.withValues(alpha: 0.06)
                      : null,
                  child: ListTile(
                    title: Text(
                      drill.nameHe,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(drill.descriptionHe),
                    trailing: selected
                        ? Icon(Icons.check_circle, color: AppColors.development)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () {
                      setState(() {
                        _selectedDrillId = drill.id;
                        _applyDrillDefaults();
                      });
                    },
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            Text(
              'Micro-behaviors',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            ...behaviorSource.map((behavior) {
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
            if (_selectedDrillId != null)
              OutlinedButton(
                onPressed: _saving ? null : () => _save(PdEventType.drill),
                child: const Text('שמור כ-Drill'),
              ),
          ],
        ),
      ),
    );
  }
}
