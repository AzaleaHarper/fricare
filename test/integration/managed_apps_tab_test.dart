import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/infrastructure/services/installed_apps_service.dart';
import 'package:fricare/presentation/providers/friction_apps_provider.dart';
import 'package:fricare/presentation/screens/managed_apps_tab.dart';
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
      child: const MaterialApp(home: Scaffold(body: ManagedAppsTab())),
    );
  }

  testWidgets('empty state shows "No apps managed yet"', (tester) async {
    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('No apps managed yet'), findsOneWidget);
  });

  testWidgets('displays global toggle with correct initial state', (
    tester,
  ) async {
    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    expect(find.text('Friction is active'), findsOneWidget);
  });

  testWidgets('lists managed apps with correct names', (tester) async {
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

    expect(find.text('3 apps managed'), findsOneWidget);
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

  testWidgets('no per-tile delete button exists', (tester) async {
    repo.seedApps([sampleApp(packageName: 'com.a', appName: 'App A')]);

    await tester.pumpWidget(buildTab(repo));
    await tester.pumpAndSettle();

    // Delete icon should not be present outside selection mode.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  group('multi-select', () {
    testWidgets('long press enters selection mode', (tester) async {
      repo.seedApps([
        sampleApp(packageName: 'com.a', appName: 'App A'),
        sampleApp(packageName: 'com.b', appName: 'App B'),
      ]);

      await tester.pumpWidget(buildTab(repo));
      await tester.pumpAndSettle();

      // Long press first app.
      await tester.longPress(find.text('App A'));
      await tester.pumpAndSettle();

      // Selection bar should appear.
      expect(find.text('1 selected'), findsOneWidget);
      // Checkboxes should appear.
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('close button exits selection mode', (tester) async {
      repo.seedApps([sampleApp(packageName: 'com.a', appName: 'App A')]);

      await tester.pumpWidget(buildTab(repo));
      await tester.pumpAndSettle();

      // Enter selection mode.
      await tester.longPress(find.text('App A'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      // Tap close.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Selection bar gone, count header back.
      expect(find.text('1 selected'), findsNothing);
      expect(find.text('1 app managed'), findsOneWidget);
    });

    testWidgets('single-app delete shows singular dialog title', (
      tester,
    ) async {
      repo.seedApps([
        sampleApp(packageName: 'com.a', appName: 'App A'),
        sampleApp(packageName: 'com.b', appName: 'App B'),
      ]);

      await tester.pumpWidget(buildTab(repo));
      await tester.pumpAndSettle();

      // Long press to select one app, then delete.
      await tester.longPress(find.text('App A'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(Card),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();

      // Singular title.
      expect(find.text('Remove app?'), findsOneWidget);

      // Confirm and verify removal.
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('App A'), findsNothing);
      expect(find.text('App B'), findsOneWidget);
    });

    testWidgets('bulk delete shows plural dialog and removes selected apps', (
      tester,
    ) async {
      repo.seedApps([
        sampleApp(packageName: 'com.a', appName: 'App A'),
        sampleApp(packageName: 'com.b', appName: 'App B'),
        sampleApp(packageName: 'com.c', appName: 'App C'),
      ]);

      await tester.pumpWidget(buildTab(repo));
      await tester.pumpAndSettle();

      // Long press first app to enter selection.
      await tester.longPress(find.text('App A'));
      await tester.pumpAndSettle();

      // Tap second app to add to selection.
      await tester.tap(find.text('App B'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      // Tap delete icon in selection bar.
      await tester.tap(
        find.descendant(
          of: find.byType(Card),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();

      // Plural title.
      expect(find.text('Remove 2 apps?'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Only App C should remain.
      expect(find.text('App A'), findsNothing);
      expect(find.text('App B'), findsNothing);
      expect(find.text('App C'), findsOneWidget);
    });
  });
}
