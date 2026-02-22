import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/presentation/screens/test_friction_screen.dart';
import 'package:fricare/presentation/widgets/friction_confirmation.dart';
import 'package:fricare/presentation/widgets/friction_hold_button.dart';
import 'package:fricare/presentation/widgets/friction_math.dart';
import 'package:fricare/presentation/widgets/friction_puzzle.dart';

void main() {
  Widget buildScreen(FrictionKind kind) {
    return MaterialApp(
      home: TestFrictionScreen(
        frictionConfig: FrictionConfig(kind: kind),
        appName: 'TestApp',
      ),
    );
  }

  testWidgets('renders FrictionHoldButton for holdToOpen', (tester) async {
    await tester.pumpWidget(buildScreen(FrictionKind.holdToOpen));
    expect(find.byType(FrictionHoldButton), findsOneWidget);
    expect(find.text('Hold to Open'), findsOneWidget);
  });

  testWidgets('renders FrictionPuzzle for puzzle', (tester) async {
    await tester.pumpWidget(buildScreen(FrictionKind.puzzle));
    expect(find.byType(FrictionPuzzle), findsOneWidget);
    expect(find.text('Tap Sequence'), findsOneWidget);
  });

  testWidgets('renders FrictionConfirmation for confirmation', (tester) async {
    await tester.pumpWidget(buildScreen(FrictionKind.confirmation));
    expect(find.byType(FrictionConfirmation), findsOneWidget);
    expect(find.text('Opening TestApp'), findsOneWidget);
  });

  testWidgets('renders FrictionMath for math', (tester) async {
    await tester.pumpWidget(buildScreen(FrictionKind.math));
    expect(find.byType(FrictionMath), findsOneWidget);
    expect(find.text('Solve to continue'), findsOneWidget);
  });

  testWidgets('renders no-friction text for none', (tester) async {
    await tester.pumpWidget(buildScreen(FrictionKind.none));
    expect(find.text('No friction configured for this tier.'), findsOneWidget);
  });

  testWidgets('has Test Friction app bar title', (tester) async {
    await tester.pumpWidget(buildScreen(FrictionKind.holdToOpen));
    expect(find.text('Test Friction'), findsOneWidget);
  });
}
