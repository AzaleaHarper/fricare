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
    expect(data['kind'], 1); // holdToOpen
    expect(data['confirmationSteps'], 3);
    expect(data['puzzleTaps'], 7);
    expect(data['mathProblems'], 4);
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
    expect(chains[1]['kind'], 3); // confirmation
    expect(chains[1]['confirmationSteps'], 3);
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
