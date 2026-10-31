import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/character/config/pd_character_registry.dart';
import '../../domain/character/providers/character_providers.dart';

class ManualEvidenceScreen extends ConsumerStatefulWidget {
  const ManualEvidenceScreen({super.key, required this.traitId});

  final String traitId;

  @override
  ConsumerState<ManualEvidenceScreen> createState() =>
      _ManualEvidenceScreenState();
}

class _ManualEvidenceScreenState extends ConsumerState<ManualEvidenceScreen> {
  String? _indicatorId;
  bool _demonstrated = true;
  bool _opportunityDetected = true;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final trait = pdCharacterRegistry[widget.traitId];
    if (trait == null || _indicatorId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(characterControllerProvider.notifier).logManualEvidence(
            traitId: widget.traitId,
            indicatorId: _indicatorId!,
            demonstrated: _demonstrated,
            opportunityDetected: _opportunityDetected,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidence נשמר')),
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
    final trait = pdCharacterRegistry[widget.traitId];
    if (trait == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evidence')),
        body: const Center(child: Text('Trait לא נמצא')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Evidence ידני')),
      body: AppLayout.constrain(
        context: context,
        compact: 640,
        child: ListView(
          padding: AppLayout.listPadding,
          children: [
            Text(
              trait.nameHe,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'קרה משהו שמייצג את התכונה? רשום בקצרה — לא יומן ארוך.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Indicator',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            ...trait.indicators.map((indicator) {
              return RadioListTile<String>(
                value: indicator.indicatorId,
                groupValue: _indicatorId,
                onChanged: (v) => setState(() => _indicatorId = v),
                title: Text(indicator.labelHe),
                contentPadding: EdgeInsets.zero,
              );
            }),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('הייתה הזדמנות (opportunity_detected)'),
              value: _opportunityDetected,
              onChanged: (v) => setState(() => _opportunityDetected = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Demonstrated'),
              subtitle: const Text('כבה = Missed Opportunity'),
              value: _demonstrated,
              onChanged: (v) => setState(() => _demonstrated = v),
            ),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'הערה קצרה (אופציונלי)',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving || _indicatorId == null ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.development,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('שמור Evidence'),
            ),
          ],
        ),
      ),
    );
  }
}
