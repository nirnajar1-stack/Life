import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_app/core/theme/app_theme.dart';

void main() {
  testWidgets('Hebrew web theme renders a scaffold', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Text('ניהול החיים')),
      ),
    );

    expect(find.text('ניהול החיים'), findsOneWidget);
  });
}
