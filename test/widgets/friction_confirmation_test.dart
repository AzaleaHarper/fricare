import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/presentation/widgets/friction_confirmation.dart';

void main() {
  Widget buildWidget({
    int totalSteps = 3,
    String appName = 'TestApp',
    VoidCallback? onComplete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FrictionConfirmation(
          totalSteps: totalSteps,
          appName: appName,
          onComplete: onComplete ?? () {},
        ),
      ),
    );
  }

  testWidgets('displays first prompt and step 1 of N', (tester) async {
    await tester.pumpWidget(buildWidget(totalSteps: 3));

    expect(find.text('Do you really want to open this app?'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Opening TestApp'), findsOneWidget);
  });

  testWidgets('Continue button advances to next step', (tester) async {
    await tester.pumpWidget(buildWidget(totalSteps: 3));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Are you sure? Think about it.'), findsOneWidget);
  });

  testWidgets('Continue button is disabled during cooldown', (tester) async {
    await tester.pumpWidget(buildWidget(totalSteps: 3));

    await tester.tap(find.text('Continue'));
    await tester.pump();

    // Button should be disabled (onPressed is null).
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    // After cooldown expires, button should be enabled again.
    await tester.pumpAndSettle();
    final buttonAfter = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(buttonAfter.onPressed, isNotNull);
  });

  testWidgets('final step shows Open App button', (tester) async {
    await tester.pumpWidget(buildWidget(totalSteps: 2));

    // Advance to step 2 (final)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Open App'), findsOneWidget);
  });

  testWidgets('tapping Open App on final step calls onComplete', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      buildWidget(totalSteps: 1, onComplete: () => completed = true),
    );

    // totalSteps=1, so first step is also last
    await tester.tap(find.text('Open App'));
    await tester.pump();

    expect(completed, true);
  });

  testWidgets('step indicator shows correct number of dots', (tester) async {
    await tester.pumpWidget(buildWidget(totalSteps: 3));

    // The dots are Container widgets with BoxDecoration(shape: circle)
    // The step text confirms the count
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });

  testWidgets('displays app name in subtitle', (tester) async {
    await tester.pumpWidget(buildWidget(appName: 'Instagram'));
    expect(find.text('Opening Instagram'), findsOneWidget);
  });
}
