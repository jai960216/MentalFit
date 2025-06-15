import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String? senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatRoomId: json['chatRoomId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      content: json['content'] as String,
      type: MessageType.fromString(json['type'] as String),
      timestamp: _parseDateTime(json['timestamp']),
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.value,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  /// Firebase Firestore 저장용 데이터 변환
  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.value,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'metadata': metadata ?? {},
    };
  }

  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  // 내가 보낸 메시지인지 확인
  bool isMine(String currentUserId) {
    return senderId == currentUserId;
  }

  // AI 메시지인지 확인
  bool get isFromAI => senderId == 'ai' || senderId == 'system';

  // 이미지 메시지인지 확인
  bool get isImage => type == MessageType.image;

  // 파일 메시지인지 확인
  bool get isFile => type == MessageType.file;

  // 시스템 메시지인지 확인
  bool get isSystem => type == MessageType.system;

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, content: $content)';
  }

  /// Firebase DateTime 파싱 헬퍼
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      return DateTime.now();
    }
  }
}

enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  system('system'),
  aiResponse('ai_response');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}
