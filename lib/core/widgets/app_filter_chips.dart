import 'package:flutter/material.dart';

import '../layout/app_layout.dart';
import '../theme/app_theme.dart';

/// Soft UI filter / period chips that always wrap (never clip).
///
/// Selected = navy fill + white label. Unselected = white + line border.
class SoftFilterChip extends StatelessWidget {
  const SoftFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: selected ? Colors.white : AppColors.ink,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.line,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
  }
}

/// Wraps a list of filter chips with Soft UI spacing rhythm.
class AppFilterChipBar extends StatelessWidget {
  const AppFilterChipBar({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: children,
      ),
    );
  }
}
