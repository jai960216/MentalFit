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
  @HiveField(5)
  String? userId; // 사용자별 분리를 위한 사용자 ID

  AIChatRoom({
    required this.id,
    required this.topic,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.userId,
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
  @HiveField(4)
  String? userId; // 사용자별 분리를 위한 사용자 ID

  AIChatMessage({
    required this.roomId,
    required this.role,
    required this.text,
    required this.createdAt,
    this.userId,
  });
}
