import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/infrastructure/services/installed_apps_service.dart';
import 'package:fricare/presentation/providers/friction_apps_provider.dart';
import 'package:fricare/presentation/screens/protected_apps_tab.dart';
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

  Widget buildTab(FakeRepository repo) {
    final mockAppsService = MockInstalledAppsService();
    when(
      () => mockAppsService.getLaunchableApps(),
    ).thenAnswer((_) async => <InstalledAppInfo>[]);

    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        installedAppsServiceProvider.overrideWithValue(mockAppsService),
      ],
      child: const MaterialApp(home: Scaffold(body: ProtectedAppsTab())),
    );
  }

  testWidgets('empty state shows "No apps protected yet"', (tester) async {
    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('No apps protected yet'), findsOneWidget);
  });

  testWidgets('displays global toggle with correct initial state', (
    tester,
  ) async {
    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('Friction is active'), findsOneWidget);
  });

  testWidgets('lists protected apps with correct names', (tester) async {
    repo.seedApps([
      sampleApp(
        packageName: 'com.a',
        appName: 'App Alpha',
        config: sampleConfig(kind: FrictionKind.holdToOpen),
      ),
      sampleApp(
        packageName: 'com.b',
        appName: 'App Beta',
        config: sampleConfig(kind: FrictionKind.puzzle),
      ),
    ]);

    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('App Alpha'), findsOneWidget);
    expect(find.text('App Beta'), findsOneWidget);
  });

  testWidgets('shows correct count label', (tester) async {
    repo.seedApps([
      sampleApp(packageName: 'com.a', appName: 'A'),
      sampleApp(packageName: 'com.b', appName: 'B'),
      sampleApp(packageName: 'com.c', appName: 'C'),
    ]);

    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('3 apps protected'), findsOneWidget);
  });

  testWidgets('shows kind chips for different friction types', (tester) async {
    repo.seedApps([
      sampleApp(
        packageName: 'com.a',
        appName: 'Hold App',
        config: sampleConfig(kind: FrictionKind.holdToOpen),
      ),
      sampleApp(
        packageName: 'com.b',
        appName: 'Math App',
        config: sampleConfig(kind: FrictionKind.math),
      ),
    ]);

    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('Hold'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
  });

  testWidgets('shows chain chip when chain steps configured', (tester) async {
    repo.seedApps([
      sampleApp(
        packageName: 'com.a',
        appName: 'Chained App',
        config: sampleConfig(
          chainSteps: [
            const ChainStep(kind: FrictionKind.math),
            const ChainStep(kind: FrictionKind.confirmation),
          ],
        ),
      ),
    ]);

    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    // Chain chip should show "Math → Confirm"
    expect(find.textContaining('Math'), findsOneWidget);
    expect(find.textContaining('Confirm'), findsOneWidget);
  });

  testWidgets('delete button removes app from list', (tester) async {
    repo.seedApps([sampleApp(packageName: 'com.a', appName: 'App A')]);

    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('App A'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('No apps protected yet'), findsOneWidget);
  });
}
