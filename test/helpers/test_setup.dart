import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_app.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/infrastructure/services/installed_apps_service.dart';
import 'package:fricare/presentation/providers/friction_apps_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'fake_repository.dart';

class MockInstalledAppsService extends Mock implements InstalledAppsService {}

/// Captured sync JSON from the com.fricare/sync channel.
List<String> capturedSyncCalls = [];

/// Sets up method channel mocks for both friction and sync channels.
void setupMethodChannelMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  capturedSyncCalls = [];

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('com.fricare/sync'), (
        call,
      ) async {
        if (call.method == 'syncApps') {
          capturedSyncCalls.add(call.arguments['json'] as String);
        }
        return null;
      });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('com.fricare/friction'), (
        call,
      ) async {
        switch (call.method) {
          case 'isServiceRunning':
            return false;
          case 'startMonitoringService':
          case 'stopMonitoringService':
            return null;
          case 'hasUsageStatsPermission':
          case 'hasOverlayPermission':
            return true;
          case 'isBatteryOptimized':
            return false;
          default:
            return null;
        }
      });
}

/// Tears down method channel mocks.
void teardownMethodChannelMocks() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('com.fricare/sync'), null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.fricare/friction'),
        null,
      );
}

/// Creates a [ProviderContainer] with the fake repository and mock services.
ProviderContainer createTestContainer({required FakeRepository repo}) {
  final mockAppsService = MockInstalledAppsService();
  when(() => mockAppsService.getLaunchableApps()).thenAnswer((_) async => []);

  return ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
      installedAppsServiceProvider.overrideWithValue(mockAppsService),
    ],
  );
}

/// Convenience factory for a sample [FrictionApp].
FrictionApp sampleApp({
  String packageName = 'com.example.app',
  String appName = 'Example App',
  bool enabled = true,
  FrictionConfig? config,
}) {
  return FrictionApp(
    packageName: packageName,
    appName: appName,
    enabled: enabled,
    frictionConfig: config,
  );
}

/// Convenience factory for a sample [FrictionConfig].
FrictionConfig sampleConfig({
  FrictionKind kind = FrictionKind.holdToOpen,
  int delaySeconds = 3,
  int puzzleTaps = 5,
  int mathProblems = 3,
  int confirmationSteps = 2,
  List<ChainStep>? chainSteps,
}) {
  return FrictionConfig(
    kind: kind,
    delaySeconds: delaySeconds,
    puzzleTaps: puzzleTaps,
    mathProblems: mathProblems,
    confirmationSteps: confirmationSteps,
    chainSteps: chainSteps,
  );
}
