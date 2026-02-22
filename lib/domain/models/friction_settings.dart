import 'package:hive_flutter/hive_flutter.dart';

part 'friction_settings.g.dart';

@HiveType(typeId: 3)
class FrictionSettings extends HiveObject {
  @HiveField(0)
  bool globalEnabled;

  /// ThemeMode index: 0 = system, 1 = light, 2 = dark.
  @HiveField(1)
  int themeModeIndex;

  /// Index into the predefined accent color list.
  @HiveField(2)
  int accentColorIndex;

  /// When true and dark mode is active, use true black backgrounds.
  @HiveField(3)
  bool amoledDark;

  FrictionSettings({
    this.globalEnabled = true,
    this.themeModeIndex = 0,
    this.accentColorIndex = 0,
    this.amoledDark = false,
  });
}
