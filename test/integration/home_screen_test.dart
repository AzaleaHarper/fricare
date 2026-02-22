import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/infrastructure/services/installed_apps_service.dart';
import 'package:fricare/presentation/providers/friction_apps_provider.dart';
import 'package:fricare/presentation/screens/home_screen.dart';
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
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets('renders two tabs: Protected and Browse', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Protected'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
  });

  testWidgets('displays Fricare title', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Fricare'), findsOneWidget);
  });

  testWidgets('badge shows correct app count', (tester) async {
    repo.seedApps([
      sampleApp(packageName: 'com.a', appName: 'A'),
      sampleApp(packageName: 'com.b', appName: 'B'),
    ]);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('settings icon is present', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
