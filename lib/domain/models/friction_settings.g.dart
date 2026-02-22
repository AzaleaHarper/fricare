// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friction_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FrictionSettingsAdapter extends TypeAdapter<FrictionSettings> {
  @override
  final int typeId = 3;

  @override
  FrictionSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FrictionSettings(
      globalEnabled: fields[0] as bool,
      themeModeIndex: fields.containsKey(1) ? fields[1] as int : 0,
      accentColorIndex: fields.containsKey(2) ? fields[2] as int : 0,
      amoledDark: fields.containsKey(3) ? fields[3] as bool : false,
    );
  }

  @override
  void write(BinaryWriter writer, FrictionSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.globalEnabled)
      ..writeByte(1)
      ..write(obj.themeModeIndex)
      ..writeByte(2)
      ..write(obj.accentColorIndex)
      ..writeByte(3)
      ..write(obj.amoledDark);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrictionSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
