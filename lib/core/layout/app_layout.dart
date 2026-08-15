import 'package:flutter/material.dart';

import 'breakpoints.dart';

class AppLayout {
  const AppLayout._();

  static const double cardRadius = 16;
  static const double chipRadius = 20;
  static const double pageGutter = 20;
  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(20, 12, 20, 96);
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 32);

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
