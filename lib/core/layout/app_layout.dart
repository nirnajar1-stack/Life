import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'breakpoints.dart';

/// Soft UI × LawPro spacing + page layout tokens (see design-system/life-app/MASTER.md).
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppLayout {
  const AppLayout._();

  /// Cards use [AppRadii.lg] (20) — Soft UI Evolution.
  static const double cardRadius = AppRadii.lg;
  static const double chipRadius = AppRadii.pill;
  static const double pageGutter = AppSpacing.md;

  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.sm + AppSpacing.xs,
    AppSpacing.md,
    96,
  );

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.sm,
    AppSpacing.md,
    AppSpacing.xl,
  );

  /// Vertical gap between major dashboard sections.
  static const double sectionGap = AppSpacing.md;

  /// Vertical gap inside a soft card / list block.
  static const double blockGap = AppSpacing.sm;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

  static bool isWide(BuildContext context, {double from = 720}) =>
      MediaQuery.sizeOf(context).width >= from;

  static Widget constrain({
    required BuildContext context,
    required Widget child,
    double compact = 720,
  }) {
    final maxWidth = contentMaxWidthFor(
      MediaQuery.sizeOf(context).width,
      compact: compact,
    );
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
