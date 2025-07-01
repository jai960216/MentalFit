import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

// Message 타입을 re-export하여 순환 import 방지
export 'message_model.dart';

class ChatRoom {
  final String id;
  final String title;
  final ChatRoomType type;
  final List<String> participantIds;
  final String? counselorId;
  final String? counselorName;
  final String? counselorImageUrl;
  final Map<String, String>? participantNames; // userId -> userName 매핑
  final List<String> hiddenForUsers; // 이 채팅방을 숨긴 사용자 ID 목록
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
    this.participantNames,
    this.hiddenForUsers = const [],
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
      participantNames: json['participantNames'] != null
          ? Map<String, String>.from(json['participantNames'] as Map)
          : null,
      hiddenForUsers: json['hiddenForUsers'] != null
          ? List<String>.from(json['hiddenForUsers'] as List)
          : [],
      lastMessage:
          json['lastMessage'] != null
              ? _parseLastMessage(json['lastMessage'])
              : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      topic: json['topic'] as String?,
      status: ChatRoomStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
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
      'participantNames': participantNames,
      'hiddenForUsers': hiddenForUsers,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'topic': topic,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Firebase Firestore 저장용 데이터 변환
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type.value,
      'participantIds': participantIds,
      'counselorId': counselorId,
      'counselorName': counselorName,
      'counselorImageUrl': counselorImageUrl,
      'participantNames': participantNames,
      'hiddenForUsers': hiddenForUsers,
      'lastMessage': lastMessage?.toFirestore(),
      'unreadCount': unreadCount,
      'topic': topic,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
    Map<String, String>? participantNames,
    List<String>? hiddenForUsers,
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
      participantNames: participantNames ?? this.participantNames,
      hiddenForUsers: hiddenForUsers ?? this.hiddenForUsers,
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

  // 특정 사용자에게 숨겨진 채팅방인지 확인
  bool isHiddenForUser(String userId) {
    return hiddenForUsers.contains(userId);
  }

  // 사용자가 채팅방을 숨기거나 표시하도록 토글
  ChatRoom toggleHiddenForUser(String userId) {
    final newHiddenList = List<String>.from(hiddenForUsers);
    if (newHiddenList.contains(userId)) {
      newHiddenList.remove(userId);
    } else {
      newHiddenList.add(userId);
    }
    return copyWith(hiddenForUsers: newHiddenList);
  }

  // 현재 사용자에게 보여질 채팅방 제목 (상대방 이름)
  String getDisplayTitle(String currentUserId, [String? currentUserName]) {
    if (type == ChatRoomType.ai) {
      return title; // AI 채팅은 기존 제목 사용
    }
    
    // 1:1 채팅방에서 상대방 찾기
    if (participantIds.length == 2) {
      final otherUserId = participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      
      if (otherUserId.isEmpty) {
        return '채팅상대';
      }
      
      // participantNames에서 상대방 이름 찾기 (최우선)
      if (participantNames != null && 
          participantNames!.containsKey(otherUserId)) {
        final otherUserName = participantNames![otherUserId]!;
        if (otherUserName.isNotEmpty) {
          return otherUserName;
        }
      }
      
      // 상담사 정보 기반 판단
      if (counselorId != null && counselorName != null) {
        // 현재 사용자가 상담사인 경우 → 상대방은 일반 사용자
        if (counselorId == currentUserId) {
          return '일반 사용자';
        }
        // 상대방이 상담사인 경우 → 상담사 이름 표시
        else if (counselorId == otherUserId) {
          return counselorName!;
        }
      }
      
      // 기본 제목 사용
      return title.isNotEmpty && title != 'Private Chat' ? title : '채팅상대';
    }
    
    return title; // 그룹 채팅 등은 기존 제목 사용
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, title: $title, type: $type)';
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

  /// Firebase lastMessage 파싱 헬퍼
  static Message? _parseLastMessage(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Map<String, dynamic>) {
        return Message.fromJson(value);
      }
      return null;
    } catch (e) {
      return null;
    }
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
