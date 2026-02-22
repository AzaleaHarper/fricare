import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/presentation/widgets/friction_math.dart';

void main() {
  Widget buildWidget({int totalProblems = 2, VoidCallback? onComplete}) {
    return MaterialApp(
      home: Scaffold(
        body: FrictionMath(
          totalProblems: totalProblems,
          onComplete: onComplete ?? () {},
        ),
      ),
    );
  }

  /// Extracts the answer from the displayed equation text.
  int solveDisplayedProblem(WidgetTester tester) {
    // Find the equation text (e.g., "47 + 23 = ?")
    final textFinder = find.textContaining('= ?');
    final text = (tester.widget<Text>(textFinder)).data!;
    // Parse: "47 + 23 = ?"
    final parts = text.replaceAll(' = ?', '').split(' ');
    final a = int.parse(parts[0]);
    final op = parts[1];
    final b = int.parse(parts[2]);
    return op == '+' ? a + b : a - b;
  }

  testWidgets('displays problem counter and equation', (tester) async {
    await tester.pumpWidget(buildWidget(totalProblems: 3));
    await tester.pumpAndSettle();

    expect(find.text('Problem 1 of 3'), findsOneWidget);
    expect(find.text('Solve to continue'), findsOneWidget);
    expect(find.textContaining('= ?'), findsOneWidget);
  });

  testWidgets('correct answer advances to next problem', (tester) async {
    await tester.pumpWidget(buildWidget(totalProblems: 2));
    await tester.pumpAndSettle();

    final answer = solveDisplayedProblem(tester);
    await tester.enterText(find.byType(TextField), '$answer');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Problem 2 of 2'), findsOneWidget);
  });

  testWidgets('wrong answer does not advance', (tester) async {
    await tester.pumpWidget(buildWidget(totalProblems: 2));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '99999');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Problem 1 of 2'), findsOneWidget);
  });

  testWidgets('completing all problems calls onComplete', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      buildWidget(totalProblems: 1, onComplete: () => completed = true),
    );
    await tester.pumpAndSettle();

    final answer = solveDisplayedProblem(tester);
    await tester.enterText(find.byType(TextField), '$answer');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(completed, true);
  });

  testWidgets('empty submit does nothing', (tester) async {
    await tester.pumpWidget(buildWidget(totalProblems: 2));
    await tester.pumpAndSettle();

    // Submit with empty text
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Problem 1 of 2'), findsOneWidget);
  });

  testWidgets('wrong answer clears input field', (tester) async {
    await tester.pumpWidget(buildWidget(totalProblems: 2));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '99999');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });
}
