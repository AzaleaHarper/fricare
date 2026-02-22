import 'package:hive_flutter/hive_flutter.dart';
import 'friction_type.dart';

part 'friction_app.g.dart';

@HiveType(typeId: 2)
class FrictionApp extends HiveObject {
  @HiveField(0)
  String packageName;

  @HiveField(1)
  String appName;

  @HiveField(2)
  bool enabled;

  @HiveField(3)
  FrictionConfig frictionConfig;

  FrictionApp({
    required this.packageName,
    required this.appName,
    this.enabled = true,
    FrictionConfig? frictionConfig,
  }) : frictionConfig =
           frictionConfig ?? FrictionConfig(kind: FrictionKind.holdToOpen);

  FrictionApp copyWith({
    String? packageName,
    String? appName,
    bool? enabled,
    FrictionConfig? frictionConfig,
  }) {
    return FrictionApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      enabled: enabled ?? this.enabled,
      frictionConfig: frictionConfig ?? this.frictionConfig,
    );
  }
}
