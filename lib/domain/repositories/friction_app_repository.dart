import '../models/friction_app.dart';
import '../models/friction_settings.dart';

abstract class FrictionAppRepository {
  List<FrictionApp> getAll();
  FrictionApp? getByPackage(String packageName);
  Future<void> save(FrictionApp app);
  Future<void> remove(String packageName);
  FrictionSettings getSettings();
  Future<void> saveSettings(FrictionSettings settings);
}
