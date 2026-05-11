// Widget smoke test for the Task Manager app.
//
// NOTE: Firebase is not initialised in this test environment, so we only
// verify that the app widget tree can be built inside a ProviderScope.
// Full integration tests should be run against a Firebase emulator.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignments/main.dart';

void main() {
  testWidgets('TaskManagerApp builds without throwing', (
    WidgetTester tester,
  ) async {
    // Build the app inside a ProviderScope (required by Riverpod).
    await tester.pumpWidget(const ProviderScope(child: TaskManagerApp()));

    // The splash screen should be rendered immediately.
    expect(find.byType(TaskManagerApp), findsOneWidget);
  });
}
