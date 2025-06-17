import 'package:hive/hive.dart';

part 'ai_chat_models.g.dart';

@HiveType(typeId: 30)
class AIChatRoom extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String topic;
  @HiveField(2)
  DateTime createdAt;
  @HiveField(3)
  String? lastMessage;
  @HiveField(4)
  DateTime? lastMessageAt;

  AIChatRoom({
    required this.id,
    required this.topic,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
  });
}

@HiveType(typeId: 31)
class AIChatMessage extends HiveObject {
  @HiveField(0)
  String roomId;
  @HiveField(1)
  String role; // 'user' or 'assistant'
  @HiveField(2)
  String text;
  @HiveField(3)
  DateTime createdAt;

  AIChatMessage({
    required this.roomId,
    required this.role,
    required this.text,
    required this.createdAt,
  });
}
