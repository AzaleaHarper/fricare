import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/overlay/overlay_main.dart';
import 'package:fricare/presentation/theme/app_theme.dart';
import 'package:fricare/presentation/widgets/friction_confirmation.dart';
import 'package:fricare/presentation/widgets/friction_hold_button.dart';
import 'package:fricare/presentation/widgets/friction_math.dart';

void main() {
  const channel = MethodChannel('com.fricare/overlay');
  late Map<String, dynamic> configResponse;
  late List<String> invokedMethods;

  setUp(() {
    invokedMethods = [];
    configResponse = {
      'kind': 1, // holdToOpen
      'delaySeconds': 3,
      'confirmationSteps': 2,
      'puzzleTaps': 5,
      'mathProblems': 3,
      'chainStepsJson': '[]',
      'appName': 'TestApp',
      'packageName': 'com.test',
      'accentColorIndex': 0,
      'amoledDark': false,
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invokedMethods.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Pump the widget and push config via the showFriction method call.
  Future<void> pumpAndPushConfig(
    WidgetTester tester,
    Map<String, dynamic> config,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(accentColorIndex: 0, brightness: Brightness.dark),
        home: const OverlayScreen(),
      ),
    );
    await tester.pump();

    // Simulate Kotlin pushing config to Dart
    final data = const StandardMethodCodec().encodeMethodCall(
      MethodCall('showFriction', config),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      data,
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loads config and renders hold button for kind 1', (
    tester,
  ) async {
    await pumpAndPushConfig(tester, configResponse);
    expect(find.byType(FrictionHoldButton), findsOneWidget);
  });

  testWidgets('renders math widget for kind 4', (tester) async {
    configResponse['kind'] = 4;
    await pumpAndPushConfig(tester, configResponse);
    expect(find.byType(FrictionMath), findsOneWidget);
  });

  testWidgets('chain mode shows step indicator and renders first step', (
    tester,
  ) async {
    configResponse['chainStepsJson'] = jsonEncode([
      const ChainStep(kind: FrictionKind.math, mathProblems: 1).toJson(),
      const ChainStep(kind: FrictionKind.confirmation).toJson(),
    ]);

    await pumpAndPushConfig(tester, configResponse);

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.byType(FrictionMath), findsOneWidget);
  });

  testWidgets('cancel button calls frictionCancelled', (tester) async {
    await pumpAndPushConfig(tester, configResponse);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(invokedMethods, contains('frictionCancelled'));
  });

  testWidgets('shows empty widget before config is pushed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(accentColorIndex: 0, brightness: Brightness.dark),
        home: const OverlayScreen(),
      ),
    );
    await tester.pump();

    // No friction widget rendered yet
    expect(find.byType(FrictionHoldButton), findsNothing);
    expect(find.byType(Scaffold), findsNothing);
  });

  testWidgets('chain mode advances to second step after completing first', (
    tester,
  ) async {
    configResponse['chainStepsJson'] = jsonEncode([
      const ChainStep(
        kind: FrictionKind.confirmation,
        confirmationSteps: 1,
      ).toJson(),
      const ChainStep(kind: FrictionKind.holdToOpen).toJson(),
    ]);

    await pumpAndPushConfig(tester, configResponse);

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
