import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/friction_app.dart';
import '../../domain/models/friction_settings.dart';
import '../../domain/repositories/friction_app_repository.dart';

class HiveFrictionAppRepository implements FrictionAppRepository {
  static const _appsBoxName = 'friction_apps';
  static const _settingsBoxName = 'friction_settings';
  static const _settingsKey = 'global';

  late Box<FrictionApp> _appsBox;
  late Box<FrictionSettings> _settingsBox;

  Future<void> init() async {
    _appsBox = await _openOrReset<FrictionApp>(_appsBoxName);
    _settingsBox = await _openOrReset<FrictionSettings>(_settingsBoxName);
  }

  /// Opens a Hive box, wiping corrupted data if the schema has changed.
  Future<Box<T>> _openOrReset<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name).catchError((_) => null);
      return await Hive.openBox<T>(name);
    }
  }

  @override
  List<FrictionApp> getAll() => _appsBox.values.toList();

  @override
  FrictionApp? getByPackage(String packageName) => _appsBox.get(packageName);

  @override
  Future<void> save(FrictionApp app) => _appsBox.put(app.packageName, app);

  @override
  Future<void> remove(String packageName) => _appsBox.delete(packageName);

  @override
  FrictionSettings getSettings() =>
      _settingsBox.get(_settingsKey) ?? FrictionSettings();

  @override
  Future<void> saveSettings(FrictionSettings settings) =>
      _settingsBox.put(_settingsKey, settings);
}
