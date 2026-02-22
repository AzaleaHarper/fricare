import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friction_app.dart';
import '../../domain/models/friction_type.dart';
import '../../infrastructure/platform/method_channels.dart';
import '../../infrastructure/repositories/hive_friction_app_repository.dart';
import '../../infrastructure/services/app_sync_service.dart';
import '../../infrastructure/services/installed_apps_service.dart';

final repositoryProvider = Provider<HiveFrictionAppRepository>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final installedAppsServiceProvider = Provider<InstalledAppsService>((ref) {
  return InstalledAppsService();
});

final installedAppsProvider = FutureProvider<List<InstalledAppInfo>>((ref) {
  return ref.read(installedAppsServiceProvider).getLaunchableApps();
});

/// Maps package name → icon bytes for use in protected apps tab.
final appIconsProvider = Provider<Map<String, Uint8List?>>((ref) {
  final appsAsync = ref.watch(installedAppsProvider);
  return appsAsync.when(
    data: (apps) => {for (final app in apps) app.packageName: app.icon},
    loading: () => {},
    error: (_, __) => {},
  );
});

final frictionAppsProvider =
    NotifierProvider<FrictionAppsNotifier, List<FrictionApp>>(
  FrictionAppsNotifier.new,
);

class FrictionAppsNotifier extends Notifier<List<FrictionApp>> {
  @override
  List<FrictionApp> build() {
    return ref.read(repositoryProvider).getAll();
  }

  Future<void> _syncToNative() async {
    await AppSyncService.syncToNative(state);
    // Re-send startCommand so the running service reloads its app list.
    if (await FricarePlatform.isServiceRunning()) {
      await FricarePlatform.startMonitoringService();
    }
  }

  Future<void> addApp(String packageName, String appName) async {
    final repo = ref.read(repositoryProvider);
    final app = FrictionApp(packageName: packageName, appName: appName);
    await repo.save(app);
    state = repo.getAll();
    await _syncToNative();
  }

  Future<void> addAppWithConfig(
    String packageName,
    String appName,
    FrictionConfig config,
  ) async {
    final repo = ref.read(repositoryProvider);
    final app = FrictionApp(
      packageName: packageName,
      appName: appName,
      frictionConfig: config,
    );
    await repo.save(app);
    state = repo.getAll();
    await _syncToNative();
  }

  Future<void> removeApp(String packageName) async {
    final repo = ref.read(repositoryProvider);
    await repo.remove(packageName);
    state = repo.getAll();
    await _syncToNative();
  }

  Future<void> toggleApp(String packageName, bool enabled) async {
    final repo = ref.read(repositoryProvider);
    final app = repo.getByPackage(packageName);
    if (app == null) return;
    app.enabled = enabled;
    await repo.save(app);
    state = repo.getAll();
    await _syncToNative();
  }

  Future<void> updateFrictionConfig(
    String packageName, {
    FrictionKind? kind,
    int? delaySeconds,
    bool? randomize,
    int? randomizeRange,
    int? confirmationSteps,
    int? puzzleTaps,
    int? mathProblems,
    FrictionMode? mode,
    int? openThreshold,
    List<EscalationStep>? escalationSteps,
    List<ChainStep>? chainSteps,
  }) async {
    final repo = ref.read(repositoryProvider);
    final app = repo.getByPackage(packageName);
    if (app == null) return;
    app.frictionConfig = app.frictionConfig.copyWith(
      kind: kind,
      delaySeconds: delaySeconds,
      randomize: randomize,
      randomizeRange: randomizeRange,
      confirmationSteps: confirmationSteps,
      puzzleTaps: puzzleTaps,
      mathProblems: mathProblems,
      mode: mode,
      openThreshold: openThreshold,
      escalationSteps: escalationSteps,
      chainSteps: chainSteps,
    );
    await repo.save(app);
    state = repo.getAll();
    await _syncToNative();
  }

  bool isAppSelected(String packageName) {
    return state.any((a) => a.packageName == packageName);
  }
}
