import 'message_model.dart';

class ChatRoom {
  final String id;
  final String title;
  final ChatRoomType type;
  final List<String> participantIds;
  final String? counselorId;
  final String? counselorName;
  final String? counselorImageUrl;
  final Message? lastMessage;
  final int unreadCount;
  final String? topic;
  final ChatRoomStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoom({
    required this.id,
    required this.title,
    required this.type,
    required this.participantIds,
    this.counselorId,
    this.counselorName,
    this.counselorImageUrl,
    this.lastMessage,
    required this.unreadCount,
    this.topic,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ChatRoomType.fromString(json['type'] as String),
      participantIds: List<String>.from(json['participantIds'] as List),
      counselorId: json['counselorId'] as String?,
      counselorName: json['counselorName'] as String?,
      counselorImageUrl: json['counselorImageUrl'] as String?,
      lastMessage:
          json['lastMessage'] != null
              ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
              : null,
      unreadCount: json['unreadCount'] as int,
      topic: json['topic'] as String?,
      status: ChatRoomStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.value,
      'participantIds': participantIds,
      'counselorId': counselorId,
      'counselorName': counselorName,
      'counselorImageUrl': counselorImageUrl,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'topic': topic,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatRoom copyWith({
    String? id,
    String? title,
    ChatRoomType? type,
    List<String>? participantIds,
    String? counselorId,
    String? counselorName,
    String? counselorImageUrl,
    Message? lastMessage,
    int? unreadCount,
    String? topic,
    ChatRoomStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      counselorId: counselorId ?? this.counselorId,
      counselorName: counselorName ?? this.counselorName,
      counselorImageUrl: counselorImageUrl ?? this.counselorImageUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // AI 상담방인지 확인
  bool get isAIChat => type == ChatRoomType.ai;

  // 활성 상담방인지 확인
  bool get isActive => status == ChatRoomStatus.active;

  @override
  String toString() {
    return 'ChatRoom(id: $id, title: $title, type: $type)';
  }
}

enum ChatRoomType {
  ai('ai'),
  counselor('counselor'),
  group('group');

  const ChatRoomType(this.value);
  final String value;

  static ChatRoomType fromString(String value) {
    return ChatRoomType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatRoomType.ai,
    );
  }
}

enum ChatRoomStatus {
  active('active'),
  completed('completed'),
  archived('archived');

  const ChatRoomStatus(this.value);
  final String value;

  static ChatRoomStatus fromString(String value) {
    return ChatRoomStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ChatRoomStatus.active,
    );
  }
}
