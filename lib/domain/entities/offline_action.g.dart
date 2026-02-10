// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineActionAdapter extends TypeAdapter<OfflineAction> {
  @override
  final int typeId = 0;

  @override
  OfflineAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineAction(
      id: fields[0] as String,
      actionType: fields[1] as ActionType,
      rawData: fields[2] as Object?,
      createdAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineAction obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.actionType)
      ..writeByte(2)
      ..write(obj.rawData)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActionTypeAdapter extends TypeAdapter<ActionType> {
  @override
  final int typeId = 1;

  @override
  ActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActionType.create;
      case 1:
        return ActionType.update;
      case 2:
        return ActionType.delete;
      default:
        return ActionType.create;
    }
  }

  @override
  void write(BinaryWriter writer, ActionType obj) {
    switch (obj) {
      case ActionType.create:
        writer.writeByte(0);
        break;
      case ActionType.update:
        writer.writeByte(1);
        break;
      case ActionType.delete:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
