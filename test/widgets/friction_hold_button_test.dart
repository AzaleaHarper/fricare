import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/presentation/widgets/friction_hold_button.dart';

void main() {
  Widget buildWidget({int holdDurationSeconds = 1, VoidCallback? onComplete}) {
    return MaterialApp(
      home: Scaffold(
        body: FrictionHoldButton(
          holdDurationSeconds: holdDurationSeconds,
          onComplete: onComplete ?? () {},
        ),
      ),
    );
  }

  testWidgets('displays initial Hold to Open state', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Hold to Open'), findsOneWidget);
    expect(find.text('Hold the button for 1 seconds'), findsOneWidget);
    expect(find.text('Press and hold'), findsOneWidget);
  });

  testWidgets('holding for full duration calls onComplete', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      buildWidget(holdDurationSeconds: 1, onComplete: () => completed = true),
    );

    // Start a long press on the GestureDetector
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GestureDetector)),
    );
    // Trigger the long press recognition
    await tester.pump(kLongPressTimeout);
    // Extra frame so the gesture handler fires _controller.forward()
    await tester.pump();
    // Hold for the full animation duration + buffer
    await tester.pump(const Duration(milliseconds: 1100));

    await gesture.up();
    await tester.pump();

    expect(completed, true);
  });

  testWidgets('releasing before completion resets progress', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      buildWidget(holdDurationSeconds: 3, onComplete: () => completed = true),
    );

    // Start long press
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GestureDetector)),
    );
    await tester.pump(kLongPressTimeout);
    // Hold for only 1 second of a 3 second requirement
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump();

    expect(completed, false);
    expect(find.text('Press and hold'), findsOneWidget);
  });

  testWidgets('shows countdown during hold', (tester) async {
    await tester.pumpWidget(buildWidget(holdDurationSeconds: 3));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GestureDetector)),
    );
    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 500));

    // During hold, should show remaining time
    expect(find.textContaining('remaining'), findsOneWidget);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('shows correct hold duration in instructions', (tester) async {
    await tester.pumpWidget(buildWidget(holdDurationSeconds: 5));
    expect(find.text('Hold the button for 5 seconds'), findsOneWidget);
  });
}
