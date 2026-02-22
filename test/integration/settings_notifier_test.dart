import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/presentation/providers/settings_provider.dart';

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

  test('build() returns default settings from empty repository', () {
    final container = createTestContainer(repo: repo);
    final settings = container.read(settingsProvider);

    expect(settings.globalEnabled, true);
    expect(settings.themeModeIndex, 0);
    expect(settings.accentColorIndex, 0);
    expect(settings.amoledDark, false);

    container.dispose();
  });

  test('toggleGlobal() persists to repository and updates state', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.toggleGlobal(false);

    expect(container.read(settingsProvider).globalEnabled, false);
    expect(repo.getSettings().globalEnabled, false);

    container.dispose();
  });

  test('toggleGlobal() preserves other settings fields', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setThemeMode(2);
    await notifier.setAccentColor(3);
    await notifier.toggleGlobal(false);

    final settings = container.read(settingsProvider);
    expect(settings.globalEnabled, false);
    expect(settings.themeModeIndex, 2);
    expect(settings.accentColorIndex, 3);

    container.dispose();
  });

  test('setThemeMode() persists and updates state', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setThemeMode(2);

    expect(container.read(settingsProvider).themeModeIndex, 2);
    expect(repo.getSettings().themeModeIndex, 2);

    container.dispose();
  });

  test('setAccentColor() persists and updates state', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setAccentColor(5);

    expect(container.read(settingsProvider).accentColorIndex, 5);
    expect(repo.getSettings().accentColorIndex, 5);

    container.dispose();
  });

  test('setAmoledDark() persists and updates state', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setAmoledDark(true);

    expect(container.read(settingsProvider).amoledDark, true);
    expect(repo.getSettings().amoledDark, true);

    container.dispose();
  });

  test('sequential mutations are all reflected in repository', () async {
    final container = createTestContainer(repo: repo);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setThemeMode(1);
    await notifier.setAccentColor(3);
    await notifier.setAmoledDark(true);
    await notifier.toggleGlobal(false);

    final settings = repo.getSettings();
    expect(settings.themeModeIndex, 1);
    expect(settings.accentColorIndex, 3);
    expect(settings.amoledDark, true);
    expect(settings.globalEnabled, false);

    container.dispose();
  });
}
