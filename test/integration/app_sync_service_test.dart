import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_app.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/infrastructure/services/app_sync_service.dart';

void main() {
  late List<String> capturedJson;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    capturedJson = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.fricare/sync'), (
          call,
        ) async {
          if (call.method == 'syncApps') {
            capturedJson.add(call.arguments['json'] as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fricare/sync'),
          null,
        );
  });

  test('sends only enabled apps', () async {
    final apps = [
      FrictionApp(packageName: 'com.a', appName: 'A', enabled: true),
      FrictionApp(packageName: 'com.b', appName: 'B', enabled: false),
      FrictionApp(packageName: 'com.c', appName: 'C', enabled: true),
    ];
    await AppSyncService.syncToNative(apps);

    final data = jsonDecode(capturedJson.last) as List;
    expect(data.length, 2);
    expect(data.map((d) => d['packageName']), containsAll(['com.a', 'com.c']));
  });

  test('serializes core config fields correctly', () async {
    final app = FrictionApp(
      packageName: 'com.test',
      appName: 'Test',
      frictionConfig: FrictionConfig(
        kind: FrictionKind.holdToOpen,
        delaySeconds: 5,
        confirmationSteps: 3,
        puzzleTaps: 7,
        mathProblems: 4,
      ),
    );
    await AppSyncService.syncToNative([app]);

    final data = (jsonDecode(capturedJson.last) as List).first;
    expect(data['packageName'], 'com.test');
    expect(data['appName'], 'Test');
    expect(data['kind'], 0); // holdToOpen
    expect(data['confirmationSteps'], 3);
    expect(data['puzzleTaps'], 7);
    expect(data['mathProblems'], 4);
  });

  test('serializes escalation steps', () async {
    final app = FrictionApp(
      packageName: 'com.test',
      appName: 'Test',
      frictionConfig: FrictionConfig(
        kind: FrictionKind.puzzle,
        mode: FrictionMode.escalating,
        escalationSteps: [
          const EscalationStep(
            fromOpen: 1,
            kind: FrictionKind.none,
            delaySeconds: 0,
          ),
          const EscalationStep(
            fromOpen: 5,
            kind: FrictionKind.puzzle,
            delaySeconds: 8,
          ),
        ],
      ),
    );
    await AppSyncService.syncToNative([app]);

    final data = (jsonDecode(capturedJson.last) as List).first;
    final steps = data['escalationSteps'] as List;
    expect(steps.length, 2);
    expect(steps[0]['fromOpen'], 1);
    expect(steps[0]['kind'], 3); // none
    expect(steps[1]['fromOpen'], 5);
    expect(steps[1]['kind'], 1); // puzzle
    expect(steps[1]['delaySeconds'], 8);
  });

  test('serializes chain steps via toJson()', () async {
    final app = FrictionApp(
      packageName: 'com.test',
      appName: 'Test',
      frictionConfig: FrictionConfig(
        kind: FrictionKind.holdToOpen,
        chainSteps: [
          const ChainStep(kind: FrictionKind.math, mathProblems: 2),
          const ChainStep(
            kind: FrictionKind.confirmation,
            confirmationSteps: 3,
          ),
        ],
      ),
    );
    await AppSyncService.syncToNative([app]);

    final data = (jsonDecode(capturedJson.last) as List).first;
    final chains = data['chainSteps'] as List;
    expect(chains.length, 2);
    expect(chains[0]['kind'], 4); // math
    expect(chains[0]['mathProblems'], 2);
    expect(chains[1]['kind'], 2); // confirmation
    expect(chains[1]['confirmationSteps'], 3);
  });

  test('serializes mode and openThreshold', () async {
    final app = FrictionApp(
      packageName: 'com.test',
      appName: 'Test',
      frictionConfig: FrictionConfig(
        kind: FrictionKind.holdToOpen,
        mode: FrictionMode.afterOpens,
        openThreshold: 5,
      ),
    );
    await AppSyncService.syncToNative([app]);

    final data = (jsonDecode(capturedJson.last) as List).first;
    expect(data['mode'], 1); // afterOpens
    expect(data['openThreshold'], 5);
  });

  test('sends empty array when no apps enabled', () async {
    final apps = [
      FrictionApp(packageName: 'com.a', appName: 'A', enabled: false),
    ];
    await AppSyncService.syncToNative(apps);

    final data = jsonDecode(capturedJson.last) as List;
    expect(data, isEmpty);
  });
}
