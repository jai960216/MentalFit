import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/token_manager.dart';

class ChatService {
  static ChatService? _instance;
  late ApiClient _apiClient;
  late TokenManager _tokenManager;

  // WebSocket 연결 (실제 구현 시 사용)
  // WebSocketChannel? _webSocketChannel;

  // 메시지 스트림 컨트롤러들
  final Map<String, StreamController<Message>> _messageControllers = {};
  final Map<String, StreamController<List<Message>>> _messagesControllers = {};

  // 타이핑 상태 관리
  final Map<String, StreamController<Map<String, bool>>> _typingControllers =
      {};
  final Map<String, Map<String, bool>> _typingStates = {};

  // 싱글톤 패턴
  ChatService._();

  static Future<ChatService> getInstance() async {
    if (_instance == null) {
      _instance = ChatService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _apiClient = await ApiClient.getInstance();
    _tokenManager = await TokenManager.getInstance();
  }

  // === 채팅방 관리 ===

  // 채팅방 목록 조회
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.chatRooms,
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((item) => ChatRoom.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Mock 데이터 반환 (개발용)
      return _getMockChatRooms();
    } catch (e) {
      debugPrint('채팅방 목록 조회 오류: $e');
      return _getMockChatRooms();
    }
  }

  // 새 채팅방 생성
  Future<ChatRoom> createChatRoom({
    required String title,
    required ChatRoomType type,
    String? counselorId,
    String? topic,
  }) async {
    try {
      final data = {
        'title': title,
        'type': type.value,
        'counselorId': counselorId,
        'topic': topic,
      };

      final response = await _apiClient.post<ChatRoom>(
        ApiEndpoints.createChatRoom,
        data: data,
        fromJson: ChatRoom.fromJson,
      );

      if (response.success && response.data != null) {
        return response.data!;
      }

      throw Exception('채팅방 생성 실패');
    } catch (e) {
      debugPrint('채팅방 생성 오류: $e');

      // Mock 채팅방 생성
      return _createMockChatRoom(title, type, topic);
    }
  }

  // AI 채팅방 생성
  Future<ChatRoom> createAIChatRoom({String? topic}) async {
    return await createChatRoom(
      title: topic != null ? 'AI 상담 - $topic' : 'AI 상담',
      type: ChatRoomType.ai,
      topic: topic,
    );
  }

  // 상담사 채팅방 생성
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

  // === 메시지 관리 ===

  // 메시지 목록 조회
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.getMessagesUrl(chatRoomId),
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((item) => Message.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Mock 데이터 반환
      return _getMockMessages(chatRoomId);
    } catch (e) {
      debugPrint('메시지 조회 오류: $e');
      return _getMockMessages(chatRoomId);
    }
  }

  // 메시지 전송
  Future<Message> sendMessage({
    required String chatRoomId,
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = {
        'chatRoomId': chatRoomId,
        'content': content,
        'senderId': senderId,
        'type': type.value,
        'metadata': metadata,
      };

      final response = await _apiClient.post<Message>(
        ApiEndpoints.sendMessage,
        data: data,
        fromJson: Message.fromJson,
      );

      if (response.success && response.data != null) {
        final message = response.data!;

        // 실시간 스트림에 메시지 추가
        _broadcastMessage(chatRoomId, message);

        return message;
      }

      throw Exception('메시지 전송 실패');
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');

      // Mock 메시지 생성 및 브로드캐스트
      final message = _createMockMessage(chatRoomId, content, senderId, type);
      _broadcastMessage(chatRoomId, message);

      // AI 채팅방의 경우 자동 응답 시뮬레이션
      if (chatRoomId.contains('ai') && senderId != 'ai') {
        _simulateAIResponse(chatRoomId, content);
      }

      return message;
    }
  }

  // 메시지 읽음 처리
  Future<bool> markMessagesAsRead(String chatRoomId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.markAsRead,
        data: {'chatRoomId': chatRoomId},
      );

      return response.success;
    } catch (e) {
      debugPrint('읽음 처리 오류: $e');
      return false;
    }
  }

  // === 실시간 스트림 관리 ===

  // 새 메시지 스트림 (개별 메시지)
  Stream<Message> getNewMessageStream(String chatRoomId) {
    if (!_messageControllers.containsKey(chatRoomId)) {
      _messageControllers[chatRoomId] = StreamController<Message>.broadcast();
    }
    return _messageControllers[chatRoomId]!.stream;
  }

  // 메시지 목록 스트림 (전체 메시지 목록)
  Stream<List<Message>> getMessagesStream(String chatRoomId) {
    if (!_messagesControllers.containsKey(chatRoomId)) {
      _messagesControllers[chatRoomId] =
          StreamController<List<Message>>.broadcast();
      // 초기 메시지 로드
      getMessages(chatRoomId).then((messages) {
        _messagesControllers[chatRoomId]?.add(messages);
      });
    }
    return _messagesControllers[chatRoomId]!.stream;
  }

  // 타이핑 상태 스트림
  Stream<Map<String, bool>> getTypingStream(String chatRoomId) {
    if (!_typingControllers.containsKey(chatRoomId)) {
      _typingControllers[chatRoomId] =
          StreamController<Map<String, bool>>.broadcast();
      _typingStates[chatRoomId] = {};
    }
    return _typingControllers[chatRoomId]!.stream;
  }

  // 타이핑 상태 업데이트
  void updateTypingStatus(String chatRoomId, String userId, bool isTyping) {
    if (!_typingStates.containsKey(chatRoomId)) {
      _typingStates[chatRoomId] = {};
    }

    _typingStates[chatRoomId]![userId] = isTyping;

    if (_typingControllers.containsKey(chatRoomId)) {
      _typingControllers[chatRoomId]!.add(Map.from(_typingStates[chatRoomId]!));
    }

    // 타이핑 상태는 일정 시간 후 자동 해제
    if (isTyping) {
      Timer(const Duration(seconds: 3), () {
        if (_typingStates[chatRoomId]?[userId] == true) {
          updateTypingStatus(chatRoomId, userId, false);
        }
      });
    }
  }

  // === WebSocket 연결 (실제 구현 시 사용) ===

  /*
  Future<void> connectWebSocket(String chatRoomId) async {
    try {
      final wsUrl = ApiEndpoints.getWsChatRoomUrl(chatRoomId);
      final token = _tokenManager.getAccessToken();
      
      _webSocketChannel = WebSocketChannel.connect(
        Uri.parse('$wsUrl?token=$token'),
      );
      
      _webSocketChannel!.stream.listen(
        (data) => _handleWebSocketMessage(chatRoomId, data),
        onError: (error) => debugPrint('WebSocket 오류: $error'),
        onDone: () => debugPrint('WebSocket 연결 종료'),
      );
    } catch (e) {
      debugPrint('WebSocket 연결 오류: $e');
    }
  }

  void _handleWebSocketMessage(String chatRoomId, dynamic data) {
    try {
      final messageData = json.decode(data as String);
      final message = Message.fromJson(messageData);
      _broadcastMessage(chatRoomId, message);
    } catch (e) {
      debugPrint('WebSocket 메시지 처리 오류: $e');
    }
  }

  void disconnectWebSocket() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
  }
  */

  // === 헬퍼 메서드들 ===

  void _broadcastMessage(String chatRoomId, Message message) {
    // 개별 메시지 스트림에 전송
    if (_messageControllers.containsKey(chatRoomId)) {
      _messageControllers[chatRoomId]!.add(message);
    }

    // 메시지 목록 스트림 업데이트 (실제로는 서버에서 전체 목록을 다시 받아야 함)
    if (_messagesControllers.containsKey(chatRoomId)) {
      getMessages(chatRoomId).then((messages) {
        _messagesControllers[chatRoomId]?.add(messages);
      });
    }
  }

  // AI 응답 시뮬레이션
  Future<void> _simulateAIResponse(
    String chatRoomId,
    String userMessage,
  ) async {
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    String aiResponse = _generateAIResponse(userMessage);

    final aiMessage = _createMockMessage(
      chatRoomId,
      aiResponse,
      'ai',
      MessageType.aiResponse,
    );

    _broadcastMessage(chatRoomId, aiMessage);
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('안녕') || message.contains('hello')) {
      return '안녕하세요! MentalFit AI 상담사입니다. 어떤 고민이 있으신가요?';
    } else if (message.contains('스트레스')) {
      return '스트레스를 받고 계시는군요. 어떤 상황에서 가장 스트레스를 많이 받으시나요? 구체적으로 말씀해주시면 더 도움이 될 것 같습니다.';
    } else if (message.contains('불안')) {
      return '불안감에 대해 말씀해주셔서 고맙습니다. 경기 전이나 중요한 순간에 느끼는 불안감인가요? 언제부터 이런 감정을 느끼셨나요?';
    } else if (message.contains('경기')) {
      return '경기와 관련된 고민이시군요. 경기 전 준비나 경기 중 집중력, 아니면 결과에 대한 부담감 중 어떤 부분이 가장 걱정되시나요?';
    } else if (message.contains('감사') || message.contains('고마워')) {
      return '도움이 되었다니 다행입니다! 언제든지 궁금한 것이 있으시면 편하게 말씀해주세요. 함께 해결해나가요.';
    } else if (message.contains('집중')) {
      return '집중력 향상은 많은 운동선수들이 관심을 갖는 주제예요. 평소 집중이 어려운 특별한 상황이나 환경이 있나요?';
    } else {
      return '말씀해주신 내용을 잘 이해했습니다. 더 자세히 설명해주실 수 있나요? 구체적인 상황이나 감정에 대해 이야기해주시면 더 정확한 조언을 드릴 수 있을 것 같습니다.';
    }
  }

  // === Mock 데이터 생성 메서드들 ===

  List<ChatRoom> _getMockChatRooms() {
    final now = DateTime.now();
    return [
      ChatRoom(
        id: 'ai_chat_1',
        title: 'AI 상담',
        type: ChatRoomType.ai,
        participantIds: ['current_user', 'ai'],
        lastMessage: Message(
          id: 'msg_ai_1',
          chatRoomId: 'ai_chat_1',
          senderId: 'ai',
          content: '안녕하세요! 어떤 도움이 필요하신가요?',
          type: MessageType.aiResponse,
          timestamp: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        unreadCount: 1,
        topic: '전체',
        status: ChatRoomStatus.active,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
      ChatRoom(
        id: 'counselor_chat_1',
        title: '김상담님과의 상담',
        type: ChatRoomType.counselor,
        participantIds: ['current_user', 'counselor_1'],
        counselorId: 'counselor_1',
        counselorName: '김상담',
        lastMessage: Message(
          id: 'msg_counselor_1',
          chatRoomId: 'counselor_chat_1',
          senderId: 'counselor_1',
          senderName: '김상담',
          content: '다음 상담 일정을 확인해주세요.',
          type: MessageType.text,
          timestamp: now.subtract(const Duration(hours: 1)),
          isRead: true,
        ),
        unreadCount: 0,
        topic: '스트레스 관리',
        status: ChatRoomStatus.active,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  List<Message> _getMockMessages(String chatRoomId) {
    final now = DateTime.now();

    if (chatRoomId.contains('ai')) {
      return [
        Message(
          id: 'msg_welcome',
          chatRoomId: chatRoomId,
          senderId: 'ai',
          content: '안녕하세요! MentalFit AI 상담사입니다. 어떤 고민이 있으신가요?',
          type: MessageType.aiResponse,
          timestamp: now.subtract(const Duration(minutes: 10)),
          isRead: true,
        ),
      ];
    } else {
      return [
        Message(
          id: 'msg_counselor_welcome',
          chatRoomId: chatRoomId,
          senderId: 'counselor_1',
          senderName: '김상담',
          content: '안녕하세요. 상담사 김상담입니다. 편하게 이야기해주세요.',
          type: MessageType.text,
          timestamp: now.subtract(const Duration(hours: 2)),
          isRead: true,
        ),
      ];
    }
  }

  ChatRoom _createMockChatRoom(String title, ChatRoomType type, String? topic) {
    final now = DateTime.now();
    final chatRoomId = 'chat_${now.millisecondsSinceEpoch}';

    return ChatRoom(
      id: chatRoomId,
      title: title,
      type: type,
      participantIds: [
        'current_user',
        type == ChatRoomType.ai ? 'ai' : 'counselor_1',
      ],
      counselorId: type == ChatRoomType.counselor ? 'counselor_1' : null,
      counselorName: type == ChatRoomType.counselor ? '상담사' : null,
      topic: topic,
      unreadCount: 0,
      status: ChatRoomStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  Message _createMockMessage(
    String chatRoomId,
    String content,
    String senderId,
    MessageType type,
  ) {
    return Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderId == 'ai' ? 'AI 상담사' : null,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: true,
    );
  }

  // === 리소스 정리 ===
  void dispose() {
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    for (final controller in _messagesControllers.values) {
      controller.close();
    }
    for (final controller in _typingControllers.values) {
      controller.close();
    }

    _messageControllers.clear();
    _messagesControllers.clear();
    _typingControllers.clear();
    _typingStates.clear();

    // disconnectWebSocket();
  }
}
