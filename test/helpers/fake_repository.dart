import 'package:fricare/domain/models/friction_app.dart';
import 'package:fricare/domain/models/friction_settings.dart';
import 'package:fricare/domain/repositories/friction_app_repository.dart';

/// In-memory implementation of [FrictionAppRepository] for tests.
class FakeRepository implements FrictionAppRepository {
  final Map<String, FrictionApp> _apps = {};
  FrictionSettings _settings = FrictionSettings();

  @override
  List<FrictionApp> getAll() => _apps.values.toList();

  @override
  FrictionApp? getByPackage(String packageName) => _apps[packageName];

  @override
  Future<void> save(FrictionApp app) async {
    _apps[app.packageName] = app;
  }

  @override
  Future<void> remove(String packageName) async {
    _apps.remove(packageName);
  }

  @override
  FrictionSettings getSettings() => _settings;

  @override
  Future<void> saveSettings(FrictionSettings settings) async {
    _settings = settings;
  }

  void seedApps(List<FrictionApp> apps) {
    _apps.clear();
    for (final app in apps) {
      _apps[app.packageName] = app;
    }
  }

  void clear() {
    _apps.clear();
    _settings = FrictionSettings();
  }
}
