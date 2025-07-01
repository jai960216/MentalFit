import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_chat_models.dart';
import 'package:uuid/uuid.dart';

class AIChatLocalService {
  static const String roomBoxName = 'ai_chat_rooms';
  static const String messageBoxName = 'ai_chat_messages';

  static Future<Box<AIChatRoom>> _roomBox() async =>
      await Hive.openBox<AIChatRoom>(roomBoxName);
  static Future<Box<AIChatMessage>> _messageBox() async =>
      await Hive.openBox<AIChatMessage>(messageBoxName);

  /// 현재 로그인한 사용자 ID 가져오기
  static String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// 현재 사용자의 방만 필터링
  static List<AIChatRoom> _filterUserRooms(List<AIChatRoom> rooms) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return [];
    
    return rooms.where((room) => 
      room.userId == currentUserId || 
      room.userId == null // 마이그레이션을 위해 null도 포함 (임시)
    ).toList();
  }

  /// 현재 사용자의 메시지만 필터링
  static List<AIChatMessage> _filterUserMessages(List<AIChatMessage> messages) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return [];
    
    return messages.where((message) => 
      message.userId == currentUserId || 
      message.userId == null // 마이그레이션을 위해 null도 포함 (임시)
    ).toList();
  }

  // 상담방 생성
  static Future<AIChatRoom> createRoom(String topic) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }
      
      debugPrint('[AIChatLocalService] 방 생성 시작: topic=$topic, userId=$currentUserId');
      
      final box = await _roomBox();
      final id = 'ai-${const Uuid().v4()}';
      final room = AIChatRoom(
        id: id,
        topic: topic,
        createdAt: DateTime.now(),
        lastMessage: null,
        lastMessageAt: null,
        userId: currentUserId, // 현재 사용자 ID 포함
      );
      
      await box.put(id, room);
      debugPrint('[AIChatLocalService] 방 생성 완료: id=$id');
      
      return room;
    } catch (e) {
      debugPrint('[AIChatLocalService] 방 생성 오류: $e');
      rethrow;
    }
  }

  // 상담방 목록 (현재 사용자만)
  static Future<List<AIChatRoom>> getRooms() async {
    final box = await _roomBox();
    final allRooms = box.values.toList();
    final userRooms = _filterUserRooms(allRooms);
    
    userRooms.sort(
      (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
        a.lastMessageAt ?? a.createdAt,
      ),
    );
    
    debugPrint('[AIChatLocalService] 사용자 방 목록 조회: ${userRooms.length}개 (전체 ${allRooms.length}개)');
    return userRooms;
  }

  // 상담방 삭제
  static Future<void> deleteRoom(String roomId) async {
    final box = await _roomBox();
    final msgBox = await _messageBox();
    await box.delete(roomId);
    final msgs = msgBox.values.where((m) => m.roomId == roomId).toList();
    for (final m in msgs) {
      await m.delete();
    }
  }

  // 메시지 추가
  static Future<void> addMessage(
    String roomId,
    String role,
    String text,
  ) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }
      
      debugPrint('[AIChatLocalService] 메시지 추가 시작: roomId=$roomId, role=$role, text=${text.length}자, userId=$currentUserId');
      
      final msgBox = await _messageBox();
      final roomBox = await _roomBox();
      
      final msg = AIChatMessage(
        roomId: roomId,
        role: role,
        text: text,
        createdAt: DateTime.now(),
        userId: currentUserId, // 현재 사용자 ID 포함
      );
      
      await msgBox.add(msg);
      debugPrint('[AIChatLocalService] 메시지 저장 완료');
      
      // 방의 최근 메시지/시간 갱신
      final room = roomBox.get(roomId);
      if (room != null && (room.userId == currentUserId || room.userId == null)) {
        room.lastMessage = text;
        room.lastMessageAt = msg.createdAt;
        // 방에 userId가 없으면 현재 사용자로 설정 (마이그레이션)
        if (room.userId == null) {
          room.userId = currentUserId;
        }
        await room.save();
        debugPrint('[AIChatLocalService] 방 정보 업데이트 완료');
      } else {
        debugPrint('[AIChatLocalService] 경고: roomId=$roomId인 방을 찾을 수 없거나 권한이 없음');
      }
      
      debugPrint('[AIChatLocalService] 메시지 추가 완료');
    } catch (e) {
      debugPrint('[AIChatLocalService] 메시지 추가 오류: $e');
      rethrow;
    }
  }

  // 메시지 목록(최신순, 현재 사용자만)
  static Future<List<AIChatMessage>> getMessages(String roomId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        debugPrint('[AIChatLocalService] 로그인되지 않음');
        return [];
      }
      
      debugPrint('[AIChatLocalService] 메시지 조회 시작: roomId=$roomId, userId=$currentUserId');
      
      final box = await _messageBox();
      final allMessages = box.values.where((m) => m.roomId == roomId).toList();
      final userMessages = _filterUserMessages(allMessages);
      userMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // userId가 null인 메시지들을 현재 사용자로 마이그레이션
      for (final message in userMessages.where((m) => m.userId == null)) {
        message.userId = currentUserId;
        await message.save();
      }
      
      debugPrint('[AIChatLocalService] 메시지 조회 완료: ${userMessages.length}개 (전체 ${allMessages.length}개)');
      return userMessages;
    } catch (e) {
      debugPrint('[AIChatLocalService] 메시지 조회 오류: $e');
      return [];
    }
  }

  // 메시지 전체 삭제(방 삭제와 별개)
  static Future<void> deleteMessages(String roomId) async {
    final box = await _messageBox();
    final msgs = box.values.where((m) => m.roomId == roomId).toList();
    for (final m in msgs) {
      await m.delete();
    }
  }

  // === 사용자별 데이터 관리 ===
  
  /// 현재 사용자로 기존 데이터 마이그레이션
  static Future<void> migrateToCurrentUser() async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      debugPrint('[AIChatLocalService] 마이그레이션: 로그인되지 않음');
      return;
    }

    debugPrint('[AIChatLocalService] 기존 데이터를 사용자별로 마이그레이션 시작: $currentUserId');

    final roomBox = await _roomBox();
    final msgBox = await _messageBox();

    // userId가 null인 방들을 현재 사용자로 연결
    final nullUserRooms = roomBox.values.where((room) => room.userId == null).toList();
    for (final room in nullUserRooms) {
      room.userId = currentUserId;
      await room.save();
      debugPrint('[AIChatLocalService] 방 마이그레이션: ${room.id}');
    }

    // userId가 null인 메시지들을 현재 사용자로 연결
    final nullUserMessages = msgBox.values.where((msg) => msg.userId == null).toList();
    for (final message in nullUserMessages) {
      message.userId = currentUserId;
      await message.save();
    }

    debugPrint('[AIChatLocalService] 마이그레이션 완료: 방 ${nullUserRooms.length}개, 메시지 ${nullUserMessages.length}개');
  }

  /// 특정 사용자의 모든 데이터 삭제 (로그아웃 시 사용)
  static Future<void> clearUserData(String userId) async {
    debugPrint('[AIChatLocalService] 사용자 데이터 삭제 시작: $userId');

    final roomBox = await _roomBox();
    final msgBox = await _messageBox();

    // 해당 사용자의 방 삭제
    final userRooms = roomBox.values.where((room) => room.userId == userId).toList();
    for (final room in userRooms) {
      await room.delete();
    }

    // 해당 사용자의 메시지 삭제
    final userMessages = msgBox.values.where((msg) => msg.userId == userId).toList();
    for (final message in userMessages) {
      await message.delete();
    }

    debugPrint('[AIChatLocalService] 사용자 데이터 삭제 완료: 방 ${userRooms.length}개, 메시지 ${userMessages.length}개');
  }

  /// 현재 사용자의 데이터 삭제 (로그아웃 시 사용)
  static Future<void> clearCurrentUserData() async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId != null) {
      await clearUserData(currentUserId);
    }
  }

  /// 로그인하지 않은 상태에서 생성된 임시 데이터 정리
  static Future<void> clearAnonymousData() async {
    debugPrint('[AIChatLocalService] 익명 데이터 정리 시작');

    final roomBox = await _roomBox();
    final msgBox = await _messageBox();

    // userId가 null인 데이터들 삭제
    final anonymousRooms = roomBox.values.where((room) => room.userId == null).toList();
    for (final room in anonymousRooms) {
      await room.delete();
    }

    final anonymousMessages = msgBox.values.where((msg) => msg.userId == null).toList();
    for (final message in anonymousMessages) {
      await message.delete();
    }

    debugPrint('[AIChatLocalService] 익명 데이터 정리 완료: 방 ${anonymousRooms.length}개, 메시지 ${anonymousMessages.length}개');
  }

  // === AI 챗방 ID 마이그레이션 ===
  static Future<void> migrateRoomIds() async {
    final box = await _roomBox();
    final msgBox = await _messageBox();
    final rooms = box.values.toList();
    for (final room in rooms) {
      if (!room.id.startsWith('ai-')) {
        final oldId = room.id;
        final newId = 'ai-$oldId';
        // 방 id 변경 (userId 유지)
        final migratedRoom = AIChatRoom(
          id: newId,
          topic: room.topic,
          createdAt: room.createdAt,
          lastMessage: room.lastMessage,
          lastMessageAt: room.lastMessageAt,
          userId: room.userId, // 기존 userId 유지
        );
        await box.put(newId, migratedRoom);
        await box.delete(oldId);
        // 메시지 roomId도 변경
        final msgs = msgBox.values.where((m) => m.roomId == oldId).toList();
        for (final m in msgs) {
          m.roomId = newId;
          await m.save();
        }
      }
    }
    // box를 닫았다가 다시 열어 캐시 초기화
    await box.close();
    await msgBox.close();
    await _roomBox();
    await _messageBox();
  }

  // === AI 챗방 topic 마이그레이션 ===
  static Future<void> migrateRoomTopics() async {
    final box = await _roomBox();
    final rooms = box.values.toList();
    for (final room in rooms) {
      String newTopic = room.topic;
      if (newTopic == 'anxiety_stress') newTopic = 'anxiety';
      if (newTopic == 'rehab') newTopic = 'injury';
      if (newTopic == '일반 상담') newTopic = 'general';
      if (room.topic != newTopic) {
        room.topic = newTopic;
        await room.save();
      }
    }
  }

  /// 전체 마이그레이션 실행 (앱 시작시 한 번 실행)
  static Future<void> runMigrations() async {
    try {
      debugPrint('[AIChatLocalService] 마이그레이션 시작');
      
      // 기존 마이그레이션들
      await migrateRoomIds();
      await migrateRoomTopics();
      
      // 사용자별 데이터 마이그레이션
      await migrateToCurrentUser();
      
      debugPrint('[AIChatLocalService] 마이그레이션 완료');
    } catch (e) {
      debugPrint('[AIChatLocalService] 마이그레이션 오류: $e');
    }
  }
}
