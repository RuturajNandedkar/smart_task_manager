// Smoke test for Smart Task Manager.
// Full integration tests requiring Firebase should use an emulator.
// This test only verifies the widget tree renders without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smart_task_manager/providers/theme_provider.dart';

void main() {
  testWidgets('ThemeProvider renders without errors', (WidgetTester tester) async {
    // withMode() bypasses SharedPreferences — safe for unit tests.
    final themeProvider = ThemeProvider.withMode(ThemeMode.light);

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Test scaffold')),
          ),
        ),
      ),
    );

    expect(find.text('Test scaffold'), findsOneWidget);
  });
}
