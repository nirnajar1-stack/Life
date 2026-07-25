import 'package:flutter/material.dart';

/// Describes a single top-level module (feature) shown on the home dashboard.
///
/// To add a new module to the app you only need to create one [AppModule]
/// entry in the registry (`app_modules.dart`) pointing to its entry screen.
class AppModule {
  const AppModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.builder,
    this.subtitle,
    this.enabled = true,
  });

  /// Stable identifier (e.g. 'tasks', 'expenses').
  final String id;

  /// Display name shown on the tile.
  final String title;

  /// Optional short description shown under the title.
  final String? subtitle;

  /// Tile icon.
  final IconData icon;

  /// Accent color for the tile.
  final Color color;

  /// Whether the module is available for entry yet.
  final bool enabled;

  /// Builds the module's entry screen.
  final WidgetBuilder builder;
}
