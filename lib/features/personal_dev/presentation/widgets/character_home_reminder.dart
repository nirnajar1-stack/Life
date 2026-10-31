import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/shell/app_tab.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/character/config/pd_character_trait_config.dart';
import '../../domain/character/config/pd_character_registry.dart';
import '../../domain/character/providers/character_providers.dart';
import '../screens/character_screen.dart';

/// Small Home reminder — Character is separate from Skills.
class CharacterHomeReminder extends ConsumerWidget {
  const CharacterHomeReminder({super.key});

  String _missionForToday(PdCharacterTraitConfig trait) {
    if (trait.characterMissions.isEmpty) return '';
    return trait.characterMissions[DateTime.now().day % trait.characterMissions.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusTraitId = ref.watch(pdCharacterFocusTraitIdProvider).valueOrNull;
    if (focusTraitId == null) return const SizedBox.shrink();

    final trait = pdCharacterRegistry[focusTraitId];
    if (trait == null) return const SizedBox.shrink();

    final mission = _missionForToday(trait);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(appTabProvider.notifier).state = AppTab.development;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CharacterScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_stories_outlined, color: AppColors.development),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Character Focus",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.development,
                          ),
                    ),
                    Text(
                      trait.nameHe,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (mission.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mission: $mission',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
