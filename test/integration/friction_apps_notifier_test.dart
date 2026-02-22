import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';
import 'package:fricare/presentation/providers/friction_apps_provider.dart';

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

  test('build() loads all apps from repository', () {
    repo.seedApps([
      sampleApp(packageName: 'com.a', appName: 'App A'),
      sampleApp(packageName: 'com.b', appName: 'App B'),
    ]);
    final container = createTestContainer(repo: repo);

    final apps = container.read(frictionAppsProvider);
    expect(apps.length, 2);
    expect(apps.map((a) => a.packageName), containsAll(['com.a', 'com.b']));

    container.dispose();
  });

  test('addApp() persists to repository and updates state', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.addApp('com.twitter', 'Twitter');

    final state = container.read(frictionAppsProvider);
    expect(state.length, 1);
    expect(state.first.packageName, 'com.twitter');
    expect(state.first.appName, 'Twitter');
    expect(state.first.enabled, true);
    expect(state.first.frictionConfig.kind, FrictionKind.holdToOpen);

    final persisted = repo.getByPackage('com.twitter');
    expect(persisted, isNotNull);

    container.dispose();
  });

  test('addAppWithConfig() persists custom config', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);
    final config = sampleConfig(kind: FrictionKind.puzzle, puzzleTaps: 7);

    await notifier.addAppWithConfig('com.app', 'App', config);

    final state = container.read(frictionAppsProvider);
    expect(state.first.frictionConfig.kind, FrictionKind.puzzle);
    expect(state.first.frictionConfig.puzzleTaps, 7);

    container.dispose();
  });

  test('removeApp() deletes from repository and updates state', () async {
    repo.seedApps([
      sampleApp(packageName: 'com.a', appName: 'A'),
      sampleApp(packageName: 'com.b', appName: 'B'),
    ]);
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.removeApp('com.a');

    final state = container.read(frictionAppsProvider);
    expect(state.length, 1);
    expect(state.first.packageName, 'com.b');
    expect(repo.getByPackage('com.a'), isNull);

    container.dispose();
  });

  test('toggleApp() persists enabled change', () async {
    repo.seedApps([sampleApp(packageName: 'com.a', enabled: true)]);
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.toggleApp('com.a', false);

    final state = container.read(frictionAppsProvider);
    expect(state.first.enabled, false);
    expect(repo.getByPackage('com.a')!.enabled, false);

    container.dispose();
  });

  test('toggleApp() for non-existent package is a no-op', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.toggleApp('com.unknown', true);

    expect(container.read(frictionAppsProvider), isEmpty);

    container.dispose();
  });

  test('updateFrictionConfig() updates individual config fields', () async {
    repo.seedApps([
      sampleApp(
        packageName: 'com.a',
        config: sampleConfig(kind: FrictionKind.holdToOpen, delaySeconds: 3),
      ),
    ]);
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.updateFrictionConfig('com.a', delaySeconds: 10);

    final state = container.read(frictionAppsProvider);
    expect(state.first.frictionConfig.delaySeconds, 10);
    expect(state.first.frictionConfig.kind, FrictionKind.holdToOpen);

    container.dispose();
  });

  test('updateFrictionConfig() can change kind', () async {
    repo.seedApps([sampleApp(packageName: 'com.a')]);
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.updateFrictionConfig('com.a', kind: FrictionKind.puzzle);

    final cfg = container.read(frictionAppsProvider).first.frictionConfig;
    expect(cfg.kind, FrictionKind.puzzle);

    container.dispose();
  });

  test('updateFrictionConfig() sets chain steps', () async {
    repo.seedApps([sampleApp(packageName: 'com.a')]);
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.updateFrictionConfig(
      'com.a',
      chainSteps: [
        const ChainStep(kind: FrictionKind.math),
        const ChainStep(kind: FrictionKind.confirmation),
      ],
    );

    final cfg = container.read(frictionAppsProvider).first.frictionConfig;
    expect(cfg.chainSteps.length, 2);
    expect(cfg.chainSteps[0].kind, FrictionKind.math);
    expect(cfg.chainSteps[1].kind, FrictionKind.confirmation);

    container.dispose();
  });

  test('isAppSelected() returns correctly', () {
    repo.seedApps([sampleApp(packageName: 'com.a')]);
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    expect(notifier.isAppSelected('com.a'), true);
    expect(notifier.isAppSelected('com.unknown'), false);

    container.dispose();
  });

  test('addApp() triggers syncToNative via method channel', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    capturedSyncCalls.clear();
    await notifier.addApp('com.twitter', 'Twitter');

    expect(capturedSyncCalls, isNotEmpty);
    expect(capturedSyncCalls.last, contains('com.twitter'));

    container.dispose();
  });

  test('multiple operations maintain state/repository consistency', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(frictionAppsProvider.notifier);

    await notifier.addApp('com.a', 'A');
    await notifier.addApp('com.b', 'B');
    await notifier.addApp('com.c', 'C');
    await notifier.removeApp('com.b');
    await notifier.toggleApp('com.c', false);
    await notifier.updateFrictionConfig('com.a', kind: FrictionKind.math);

    final state = container.read(frictionAppsProvider);
    final repoApps = repo.getAll();

    expect(state.length, repoApps.length);
    expect(state.length, 2);

    final a = state.firstWhere((x) => x.packageName == 'com.a');
    final c = state.firstWhere((x) => x.packageName == 'com.c');
    expect(a.frictionConfig.kind, FrictionKind.math);
    expect(c.enabled, false);

    container.dispose();
  });
}
