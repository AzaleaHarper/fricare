// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friction_app.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FrictionAppAdapter extends TypeAdapter<FrictionApp> {
  @override
  final int typeId = 2;

  @override
  FrictionApp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FrictionApp(
      packageName: fields[0] as String,
      appName: fields[1] as String,
      enabled: fields[2] as bool,
      frictionConfig: fields[3] as FrictionConfig,
    );
  }

  @override
  void write(BinaryWriter writer, FrictionApp obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.enabled)
      ..writeByte(3)
      ..write(obj.frictionConfig);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrictionAppAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
