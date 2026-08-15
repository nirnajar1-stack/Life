import 'package:flutter/material.dart';

/// Opens [form] as a compact dialog on desktop web, full-screen route on mobile.
Future<T?> showAdaptiveForm<T>({
  required BuildContext context,
  required Widget form,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 900;
  if (!isDesktop) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => form),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: form,
      ),
    ),
  );
}

bool isFormDialog(BuildContext context) =>
    context.findAncestorWidgetOfExactType<Dialog>() != null;
