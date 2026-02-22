// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friction_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FrictionKindAdapter extends TypeAdapter<FrictionKind> {
  @override
  final int typeId = 0;

  @override
  FrictionKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FrictionKind.holdToOpen;
      case 1:
        return FrictionKind.puzzle;
      case 2:
        return FrictionKind.confirmation;
      case 3:
        return FrictionKind.none;
      case 4:
        return FrictionKind.math;
      default:
        return FrictionKind.holdToOpen;
    }
  }

  @override
  void write(BinaryWriter writer, FrictionKind obj) {
    switch (obj) {
      case FrictionKind.holdToOpen:
        writer.writeByte(0);
      case FrictionKind.puzzle:
        writer.writeByte(1);
      case FrictionKind.confirmation:
        writer.writeByte(2);
      case FrictionKind.none:
        writer.writeByte(3);
      case FrictionKind.math:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrictionKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChainStepAdapter extends TypeAdapter<ChainStep> {
  @override
  final int typeId = 6;

  @override
  ChainStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChainStep(
      kind: fields[0] as FrictionKind,
      delaySeconds: fields.containsKey(1) ? fields[1] as int : 3,
      puzzleTaps: fields.containsKey(2) ? fields[2] as int : 5,
      confirmationSteps: fields.containsKey(3) ? fields[3] as int : 2,
      mathProblems: fields.containsKey(4) ? fields[4] as int : 3,
    );
  }

  @override
  void write(BinaryWriter writer, ChainStep obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.kind)
      ..writeByte(1)
      ..write(obj.delaySeconds)
      ..writeByte(2)
      ..write(obj.puzzleTaps)
      ..writeByte(3)
      ..write(obj.confirmationSteps)
      ..writeByte(4)
      ..write(obj.mathProblems);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChainStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FrictionConfigAdapter extends TypeAdapter<FrictionConfig> {
  @override
  final int typeId = 1;

  @override
  FrictionConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FrictionConfig(
      kind: fields[0] as FrictionKind,
      delaySeconds: fields[1] as int,
      randomize: fields[2] as bool,
      confirmationSteps: fields[3] as int,
      // Fields 4-6 (mode, openThreshold, escalationSteps) removed — ignored.
      randomizeRange: fields.containsKey(7) ? fields[7] as int : 2,
      puzzleTaps: fields.containsKey(8) ? fields[8] as int : 5,
      mathProblems: fields.containsKey(9) ? fields[9] as int : 3,
      chainSteps:
          fields.containsKey(10)
              ? (fields[10] as List).cast<ChainStep>()
              : null,
      cooldownMinutes: fields.containsKey(11) ? fields[11] as int : 0,
    );
  }

  @override
  void write(BinaryWriter writer, FrictionConfig obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.kind)
      ..writeByte(1)
      ..write(obj.delaySeconds)
      ..writeByte(2)
      ..write(obj.randomize)
      ..writeByte(3)
      ..write(obj.confirmationSteps)
      ..writeByte(7)
      ..write(obj.randomizeRange)
      ..writeByte(8)
      ..write(obj.puzzleTaps)
      ..writeByte(9)
      ..write(obj.mathProblems)
      ..writeByte(10)
      ..write(obj.chainSteps)
      ..writeByte(11)
      ..write(obj.cooldownMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrictionConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
