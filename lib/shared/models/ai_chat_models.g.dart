// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIChatRoomAdapter extends TypeAdapter<AIChatRoom> {
  @override
  final int typeId = 30;

  @override
  AIChatRoom read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIChatRoom(
      id: fields[0] as String,
      topic: fields[1] as String,
      createdAt: fields[2] as DateTime,
      lastMessage: fields[3] as String?,
      lastMessageAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AIChatRoom obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.topic)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.lastMessage)
      ..writeByte(4)
      ..write(obj.lastMessageAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIChatRoomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AIChatMessageAdapter extends TypeAdapter<AIChatMessage> {
  @override
  final int typeId = 31;

  @override
  AIChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIChatMessage(
      roomId: fields[0] as String,
      role: fields[1] as String,
      text: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AIChatMessage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.roomId)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
