import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/infrastructure/services/installed_apps_service.dart';
import 'package:fricare/presentation/providers/friction_apps_provider.dart';
import 'package:fricare/presentation/screens/settings_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_repository.dart';
import '../helpers/test_setup.dart';

void main() {
  late FakeRepository repo;

  setUp(() {
    repo = FakeRepository();
    setupMethodChannelMocks();
  });

  tearDown(() {
    repo.clear();
    teardownMethodChannelMocks();
  });

  Widget buildScreen() {
    final mockAppsService = MockInstalledAppsService();
    when(
      () => mockAppsService.getLaunchableApps(),
    ).thenAnswer((_) async => <InstalledAppInfo>[]);

    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        installedAppsServiceProvider.overrideWithValue(mockAppsService),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  testWidgets('displays Settings app bar', (tester) async {
    await tester.pumpWidget(buildScreen());
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('displays theme mode segmented button', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('tapping Dark theme persists themeModeIndex=2', (tester) async {
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(repo.getSettings().themeModeIndex, 2);
  });

  testWidgets('AMOLED toggle persists setting', (tester) async {
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('AMOLED dark mode'));
    await tester.pumpAndSettle();

    expect(repo.getSettings().amoledDark, true);
  });

  testWidgets('displays donation links', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Liberapay'), findsOneWidget);
    expect(find.text('Ko-fi'), findsOneWidget);
  });
}
