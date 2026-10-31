import 'package:flutter/material.dart';

import '../../domain/config/pd_layer.dart';
import '../../domain/config/pd_skill_config.dart';
import '../../../../core/theme/app_theme.dart';

class DevelopmentMapCard extends StatelessWidget {
  const DevelopmentMapCard({
    super.key,
    required this.skills,
    this.highlightLayer,
  });

  final List<PdSkillConfig> skills;
  final int? highlightLayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'מפת התפתחות',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '9 שכבות — Phase 0 מציג את המסגרת; Skills יתווספו בהדרגה.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 16),
            ...pdDevelopmentLayers.map((layer) {
              final active = highlightLayer == layer.number;
              final layerSkills =
                  skills.where((s) => s.layer == layer.number).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LayerRow(
                  layer: layer,
                  active: active,
                  skills: layerSkills,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.layer,
    required this.active,
    required this.skills,
  });

  final PdLayer layer;
  final bool active;
  final List<PdSkillConfig> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? AppColors.development.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.development : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.development : AppColors.line,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${layer.number}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: active ? Colors.white : AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer.nameHe,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  layer.descriptionHe,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final skill in skills)
                        Chip(
                          label: Text(skill.nameHe),
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              AppColors.development.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: AppColors.development.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
