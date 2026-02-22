import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/overlay/overlay_main.dart';
import 'package:fricare/presentation/widgets/friction_confirmation.dart';
import 'package:fricare/presentation/widgets/friction_hold_button.dart';
import 'package:fricare/presentation/widgets/friction_math.dart';

void main() {
  late Map<String, dynamic> configResponse;
  late List<String> invokedMethods;

  setUp(() {
    invokedMethods = [];
    configResponse = {
      'kind': 0,
      'delaySeconds': 3,
      'confirmationSteps': 2,
      'puzzleTaps': 5,
      'mathProblems': 3,
      'chainStepsJson': '[]',
      'appName': 'TestApp',
      'packageName': 'com.test',
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.fricare/overlay'), (
          call,
        ) async {
          invokedMethods.add(call.method);
          if (call.method == 'getFrictionConfig') {
            return configResponse;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fricare/overlay'),
          null,
        );
  });

  testWidgets('loads config and renders hold button for kind 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const OverlayScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FrictionHoldButton), findsOneWidget);
  });

  testWidgets('renders math widget for kind 4', (tester) async {
    configResponse['kind'] = 4;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const OverlayScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FrictionMath), findsOneWidget);
  });

  testWidgets('chain mode shows step indicator and renders first step', (
    tester,
  ) async {
    configResponse['chainStepsJson'] = jsonEncode([
      const ChainStep(kind: FrictionKind.math, mathProblems: 1).toJson(),
      const ChainStep(kind: FrictionKind.confirmation).toJson(),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const OverlayScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.byType(FrictionMath), findsOneWidget);
  });

  testWidgets('cancel button calls frictionCancelled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const OverlayScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(invokedMethods, contains('frictionCancelled'));
  });

  testWidgets('error state shows retry button', (tester) async {
    // Make channel throw
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.fricare/overlay'), (
          call,
        ) async {
          if (call.method == 'getFrictionConfig') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const OverlayScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed to load friction'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('chain mode advances to second step after completing first', (
    tester,
  ) async {
    // Chain: confirmation(1 step) → hold
    configResponse['chainStepsJson'] = jsonEncode([
      const ChainStep(
        kind: FrictionKind.confirmation,
        confirmationSteps: 1,
      ).toJson(),
      const ChainStep(kind: FrictionKind.holdToOpen).toJson(),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const OverlayScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: confirmation with 1 step
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.byType(FrictionConfirmation), findsOneWidget);

    // Complete the confirmation (tap "Open App" since totalSteps=1)
    await tester.tap(find.text('Open App'));
    await tester.pumpAndSettle();

    // Should advance to step 2: hold
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.byType(FrictionHoldButton), findsOneWidget);
  });
}
