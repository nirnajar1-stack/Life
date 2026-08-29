import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/config/pd_skill_registry.dart';
import '../../domain/models/pd_enums.dart';
import '../../domain/providers/personal_dev_providers.dart';

class EventLogScreen extends ConsumerStatefulWidget {
  const EventLogScreen({super.key, required this.skillId});

  final String skillId;

  @override
  ConsumerState<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends ConsumerState<EventLogScreen> {
  final _notesController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _checked = <String>{};

  PdEventType _eventType = PdEventType.realWorld;
  PdContextLevel? _powerGap;
  PdContextLevel? _outcomeImportance;
  PdContextLevel? _difficulty;
  PdContextLevel? _emotionalActivation;
  PdSafetyLevel? _relationshipSafety;
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final skill = pdSkillRegistry[widget.skillId];
    if (skill == null) return;

    final progress =
        await ref.read(pdSkillProgressProvider(widget.skillId).future);
    final stageId = progress?.currentStageId ?? skill.firstStage.id;

    setState(() => _saving = true);
    try {
      await ref.read(personalDevControllerProvider.notifier).logEvent(
            skillId: widget.skillId,
            eventType: _eventType,
            microBehaviors: _checked.toList(),
            stageAtEvent: stageId,
            relationshipType: _relationshipController.text.trim().isEmpty
                ? null
                : _relationshipController.text.trim(),
            powerGap: _powerGap,
            relationshipSafety: _relationshipSafety,
            outcomeImportance: _outcomeImportance,
            difficulty: _difficulty,
            emotionalActivation: _emotionalActivation,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('האירוע נרשם')),
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
        appBar: AppBar(title: const Text('רישום אירוע')),
        body: const Center(child: Text('Skill לא נמצא')),
      );
    }

    final progressAsync = ref.watch(pdSkillProgressProvider(widget.skillId));
    final stageId =
        progressAsync.valueOrNull?.currentStageId ?? skill.firstStage.id;

    return Scaffold(
      appBar: AppBar(title: const Text('רישום אירוע')),
      body: AppLayout.constrain(
        context: context,
        compact: 640,
        child: ListView(
          padding: AppLayout.listPadding,
          children: [
            Text(
              skill.nameHe,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Text('סוג אירוע', style: _labelStyle(context)),
            Wrap(
              spacing: 8,
              children: PdEventType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.labelHe),
                  selected: _eventType == type,
                  onSelected: (_) => setState(() => _eventType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('הקשר', style: _labelStyle(context)),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                hintText: 'סוג קשר (למשל: מנהל, בן/בת זוג)',
              ),
            ),
            const SizedBox(height: 12),
            _LevelPicker(
              label: 'פער כוח',
              value: _powerGap,
              onChanged: (v) => setState(() => _powerGap = v),
            ),
            _SafetyPicker(
              value: _relationshipSafety,
              onChanged: (v) => setState(() => _relationshipSafety = v),
            ),
            _LevelPicker(
              label: 'חשיבות תוצאה',
              value: _outcomeImportance,
              onChanged: (v) => setState(() => _outcomeImportance = v),
            ),
            _LevelPicker(
              label: 'קושי',
              value: _difficulty,
              onChanged: (v) => setState(() => _difficulty = v),
            ),
            _LevelPicker(
              label: 'הפעלה רגשית',
              value: _emotionalActivation,
              onChanged: (v) => setState(() => _emotionalActivation = v),
            ),
            const SizedBox(height: 16),
            Text('Micro-behaviors ($stageId)', style: _labelStyle(context)),
            const SizedBox(height: 8),
            ...skill.microBehaviors.map((behavior) {
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
                subtitle: Text(
                  'שלב: ${skill.stageById(behavior.stageId)?.nameHe ?? behavior.stageId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'הערות',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.development,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('שמור אירוע'),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final PdContextLevel? value;
  final ValueChanged<PdContextLevel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: const Text('—'),
                selected: value == null,
                onSelected: (_) => onChanged(null),
              ),
              ...PdContextLevel.values.map((level) {
                return ChoiceChip(
                  label: Text(level.labelHe),
                  selected: value == level,
                  onSelected: (_) => onChanged(level),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyPicker extends StatelessWidget {
  const _SafetyPicker({
    required this.value,
    required this.onChanged,
  });

  final PdSafetyLevel? value;
  final ValueChanged<PdSafetyLevel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('בטיחות בקשר',
              style: Theme.of(context).textTheme.bodySmall),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: const Text('—'),
                selected: value == null,
                onSelected: (_) => onChanged(null),
              ),
              ...PdSafetyLevel.values.map((level) {
                return ChoiceChip(
                  label: Text(level.labelHe),
                  selected: value == level,
                  onSelected: (_) => onChanged(level),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
