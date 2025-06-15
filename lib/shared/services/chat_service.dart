import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_mentalfit/shared/models/chat_room_model.dart';

// ChatRoom 모델이 이미 Message를 포함하고 있으므로 별도 import 불필요
import 'firebase_chat_service.dart';

/// 채팅 서비스 - Firebase 기반 실시간 채팅
/// 기존 Mock ChatService 인터페이스를 유지하면서 Firebase로 교체
class ChatService {
  static ChatService? _instance;

  late FirebaseChatService _firebaseChatService;
  bool _initialized = false;

  // 실시간 스트림 컨트롤러들 (기존 인터페이스 호환성 유지)
  final Map<String, StreamController<Message>> _messageControllers = {};
  final Map<String, StreamController<List<Message>>> _messagesControllers = {};
  final Map<String, StreamController<Map<String, bool>>> _typingControllers =
      {};
  final Map<String, Map<String, bool>> _typingStates = {};

  ChatService._internal();

  static Future<ChatService> getInstance() async {
    if (_instance == null) {
      _instance = ChatService._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Firebase 채팅 서비스 초기화
  Future<void> _initialize() async {
    try {
      if (!_initialized) {
        _firebaseChatService = await FirebaseChatService.getInstance();

        // Firebase 연결 상태 확인 (최대 3번 재시도)
        int retryCount = 0;
        bool isConnected = false;

        while (!isConnected && retryCount < 3) {
          try {
            // 간단한 연결 테스트
            await _firebaseChatService.getChatRooms();
            isConnected = true;
          } catch (e) {
            retryCount++;
            if (retryCount < 3) {
              debugPrint('Firebase 연결 재시도 ($retryCount/3): $e');
              await Future.delayed(Duration(milliseconds: 1000 * retryCount));
            } else {
              debugPrint('Firebase 연결 최종 실패: $e');
              rethrow;
            }
          }
        }

        _initialized = true;
        debugPrint('✅ ChatService Firebase 연동 완료');
      }
    } catch (e) {
      debugPrint('❌ ChatService 초기화 실패: $e');
      rethrow;
    }
  }

  /// 초기화 보장
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initialize();
    }
  }

  // === 채팅방 관련 메서드 ===

  /// 채팅방 목록 조회
  Future<List<ChatRoom>> getChatRooms() async {
    await _ensureInitialized();

    try {
      return await _firebaseChatService.getChatRooms();
    } catch (e) {
      debugPrint('채팅방 목록 조회 오류: $e');
      // 폴백으로 빈 목록 반환
      return [];
    }
  }

  /// 채팅방 목록 실시간 스트림
  Stream<List<ChatRoom>> getChatRoomsStream() {
    return _getChatRoomsStreamInternal();
  }

  Stream<List<ChatRoom>> _getChatRoomsStreamInternal() async* {
    await _ensureInitialized();

    try {
      yield* _firebaseChatService.getChatRoomsStream();
    } catch (e) {
      debugPrint('채팅방 스트림 오류: $e');
      yield [];
    }
  }

  /// 특정 채팅방 정보 조회
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    await _ensureInitialized();

    try {
      return await _firebaseChatService.getChatRoom(chatRoomId);
    } catch (e) {
      debugPrint('채팅방 정보 조회 오류: $e');
      return null;
    }
  }

  /// 채팅방 생성
  Future<ChatRoom> createChatRoom({
    required String title,
    required ChatRoomType type,
    String? counselorId,
    String? topic,
  }) async {
    await _ensureInitialized();

    try {
      return await _firebaseChatService.createChatRoom(
        title: title,
        type: type,
        counselorId: counselorId,
        topic: topic,
      );
    } catch (e) {
      debugPrint('채팅방 생성 오류: $e');
      throw Exception('채팅방 생성에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  /// AI 채팅방 생성
  Future<ChatRoom> createAIChatRoom({String? topic}) async {
    return await createChatRoom(
      title: topic != null ? 'AI 상담 - $topic' : 'AI 상담',
      type: ChatRoomType.ai,
      topic: topic,
    );
  }

  /// 상담사 채팅방 생성
  Future<ChatRoom> createCounselorChatRoom({
    required String counselorId,
    required String counselorName,
    String? topic,
  }) async {
    return await createChatRoom(
      title: '$counselorName님과의 상담',
      type: ChatRoomType.counselor,
      counselorId: counselorId,
      topic: topic,
    );
  }

  /// 채팅방 삭제
  Future<bool> deleteChatRoom(String chatRoomId) async {
    await _ensureInitialized();

    try {
      final success = await _firebaseChatService.deleteChatRoom(chatRoomId);

      if (success) {
        // 로컬 스트림 정리
        _cleanupLocalStreams(chatRoomId);
      }

      return success;
    } catch (e) {
      debugPrint('채팅방 삭제 오류: $e');
      return false;
    }
  }

  // === 메시지 관련 메서드 ===

  /// 메시지 목록 조회
  Future<List<Message>> getMessages(String chatRoomId) async {
    await _ensureInitialized();

    try {
      return await _firebaseChatService.getMessages(chatRoomId);
    } catch (e) {
      debugPrint('메시지 조회 오류: $e');
      return [];
    }
  }

  /// 메시지 목록 실시간 스트림
  Stream<List<Message>> getMessagesStream(String chatRoomId) {
    return _getMessagesStreamInternal(chatRoomId);
  }

  Stream<List<Message>> _getMessagesStreamInternal(String chatRoomId) async* {
    await _ensureInitialized();

    try {
      yield* _firebaseChatService.getMessagesStream(chatRoomId);
    } catch (e) {
      debugPrint('메시지 스트림 오류: $e');
      yield [];
    }
  }

  /// 메시지 전송
  Future<Message> sendMessage({
    required String chatRoomId,
    required String content,
    required String senderId, // 호환성을 위해 유지하지만 실제로는 Firebase Auth 사용
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();

    try {
      final message = await _firebaseChatService.sendMessage(
        chatRoomId: chatRoomId,
        content: content,
        type: type,
        metadata: metadata,
      );

      // 기존 인터페이스 호환성을 위한 개별 메시지 스트림 브로드캐스트
      if (_messageControllers.containsKey(chatRoomId)) {
        _messageControllers[chatRoomId]!.add(message);
      }

      return message;
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
      throw Exception('메시지 전송에 실패했습니다. 다시 시도해주세요.');
    }
  }

  /// 이미지 메시지 전송
  Future<Message> sendImageMessage({
    required String chatRoomId,
    required File imageFile,
    required String senderId, // 호환성을 위해 유지
  }) async {
    await _ensureInitialized();

    try {
      final message = await _firebaseChatService.sendImageMessage(
        chatRoomId: chatRoomId,
        imageFile: imageFile,
      );

      // 개별 메시지 스트림 브로드캐스트
      if (_messageControllers.containsKey(chatRoomId)) {
        _messageControllers[chatRoomId]!.add(message);
      }

      return message;
    } catch (e) {
      debugPrint('이미지 메시지 전송 오류: $e');
      throw Exception('이미지 전송에 실패했습니다. 다시 시도해주세요.');
    }
  }

  /// 파일 메시지 전송
  Future<Message> sendFileMessage({
    required String chatRoomId,
    required File file,
    required String senderId, // 호환성을 위해 유지
  }) async {
    await _ensureInitialized();

    try {
      final message = await _firebaseChatService.sendFileMessage(
        chatRoomId: chatRoomId,
        file: file,
      );

      // 개별 메시지 스트림 브로드캐스트
      if (_messageControllers.containsKey(chatRoomId)) {
        _messageControllers[chatRoomId]!.add(message);
      }

      return message;
    } catch (e) {
      debugPrint('파일 메시지 전송 오류: $e');
      throw Exception('파일 전송에 실패했습니다. 다시 시도해주세요.');
    }
  }

  /// 메시지 읽음 처리
  Future<bool> markMessagesAsRead(String chatRoomId) async {
    await _ensureInitialized();

    try {
      return await _firebaseChatService.markMessagesAsRead(chatRoomId);
    } catch (e) {
      debugPrint('읽음 처리 오류: $e');
      return false;
    }
  }

  // === 기존 인터페이스 호환성 유지 ===

  /// 새 메시지 스트림 (개별 메시지)
  Stream<Message> getNewMessageStream(String chatRoomId) {
    if (!_messageControllers.containsKey(chatRoomId)) {
      _messageControllers[chatRoomId] = StreamController<Message>.broadcast();
    }
    return _messageControllers[chatRoomId]!.stream;
  }

  /// 타이핑 상태 스트림
  Stream<Map<String, bool>> getTypingStream(String chatRoomId) {
    if (!_typingControllers.containsKey(chatRoomId)) {
      _typingControllers[chatRoomId] =
          StreamController<Map<String, bool>>.broadcast();
      _typingStates[chatRoomId] = {};
    }
    return _typingControllers[chatRoomId]!.stream;
  }

  /// 타이핑 상태 업데이트
  void updateTypingStatus(String chatRoomId, String userId, bool isTyping) {
    if (!_typingStates.containsKey(chatRoomId)) {
      _typingStates[chatRoomId] = {};
    }

    _typingStates[chatRoomId]![userId] = isTyping;

    if (_typingControllers.containsKey(chatRoomId)) {
      _typingControllers[chatRoomId]!.add(Map.from(_typingStates[chatRoomId]!));
    }

    // 타이핑 상태는 3초 후 자동 해제
    if (isTyping) {
      Timer(const Duration(seconds: 3), () {
        if (_typingStates[chatRoomId]?[userId] == true) {
          updateTypingStatus(chatRoomId, userId, false);
        }
      });
    }
  }

  // === 내부 헬퍼 메서드 ===

  /// 특정 채팅방의 로컬 스트림 정리
  void _cleanupLocalStreams(String chatRoomId) {
    _messageControllers[chatRoomId]?.close();
    _messageControllers.remove(chatRoomId);

    _messagesControllers[chatRoomId]?.close();
    _messagesControllers.remove(chatRoomId);

    _typingControllers[chatRoomId]?.close();
    _typingControllers.remove(chatRoomId);

    _typingStates.remove(chatRoomId);
  }

  /// 리소스 정리
  Future<void> dispose() async {
    try {
      // 로컬 스트림 컨트롤러들 정리
      for (final controller in _messageControllers.values) {
        await controller.close();
      }
      _messageControllers.clear();

      for (final controller in _messagesControllers.values) {
        await controller.close();
      }
      _messagesControllers.clear();

      for (final controller in _typingControllers.values) {
        await controller.close();
      }
      _typingControllers.clear();

      _typingStates.clear();

      // Firebase 채팅 서비스 정리
      if (_initialized) {
        await _firebaseChatService.dispose();
      }

      debugPrint('✅ ChatService 리소스 정리 완료');
    } catch (e) {
      debugPrint('❌ ChatService 정리 오류: $e');
    }
  }

  // === 개발 및 테스트용 메서드 ===

  /// 서비스 상태 확인
  bool get isInitialized => _initialized;

  /// Firebase 연결 상태 확인
  Future<bool> isConnected() async {
    try {
      await _ensureInitialized();
      // 간단한 읽기 작업으로 연결 확인
      await _firebaseChatService.getChatRooms();
      return true;
    } catch (e) {
      debugPrint('Firebase 연결 확인 실패: $e');
      return false;
    }
  }

  /// 채팅방 참여자 수 조회
  Future<int> getChatRoomParticipantCount(String chatRoomId) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      return chatRoom?.participantIds.length ?? 0;
    } catch (e) {
      debugPrint('참여자 수 조회 오류: $e');
      return 0;
    }
  }

  /// 읽지 않은 메시지 총 개수
  Future<int> getTotalUnreadCount() async {
    try {
      final chatRooms = await getChatRooms();
      return chatRooms.fold<int>(0, (total, room) => total + room.unreadCount);
    } catch (e) {
      debugPrint('읽지 않은 메시지 수 조회 오류: $e');
      return 0;
    }
  }
}
