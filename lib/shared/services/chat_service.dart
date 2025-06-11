import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  static ChatService? _instance;

  // 실시간 스트림 컨트롤러들
  final Map<String, StreamController<Message>> _messageControllers = {};
  final Map<String, StreamController<List<Message>>> _messagesControllers = {};
  final Map<String, StreamController<Map<String, bool>>> _typingControllers =
      {};
  final Map<String, Map<String, bool>> _typingStates = {};

  // Mock 데이터 저장소
  final Map<String, List<Message>> _messageCache = {};
  final List<ChatRoom> _chatRoomCache = [];

  ChatService._internal();

  static Future<ChatService> getInstance() async {
    _instance ??= ChatService._internal();
    await _instance!._initializeMockData();
    return _instance!;
  }

  /// Mock 데이터 초기화
  Future<void> _initializeMockData() async {
    if (_chatRoomCache.isEmpty) {
      _chatRoomCache.addAll(_getInitialChatRooms());
    }
  }

  /// 채팅방 목록 조회
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      // 네트워크 지연 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock 데이터 반환 (실제 API 실패 시에도 데이터 제공)
      return List.from(_chatRoomCache);
    } catch (e) {
      debugPrint('채팅방 목록 조회 오류: $e');
      // 오류 발생 시에도 빈 목록이 아닌 기본 데이터 반환
      return _getInitialChatRooms();
    }
  }

  /// 특정 채팅방 정보 조회
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final chatRoom = _chatRoomCache.firstWhere(
        (room) => room.id == chatRoomId,
        orElse: () => _createDefaultChatRoom(chatRoomId),
      );

      return chatRoom;
    } catch (e) {
      debugPrint('채팅방 정보 조회 오류: $e');
      return _createDefaultChatRoom(chatRoomId);
    }
  }

  /// 채팅방 생성
  Future<ChatRoom> createChatRoom({
    required String title,
    required ChatRoomType type,
    String? counselorId,
    String? topic,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final newChatRoom = ChatRoom(
        id:
            'chat_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        title: title,
        type: type,
        participantIds: ['current_user', counselorId ?? 'ai'],
        topic: topic,
        unreadCount: 0,
        status: ChatRoomStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 캐시에 추가
      _chatRoomCache.insert(0, newChatRoom);

      // 초기 메시지 생성 (AI의 인사말)
      if (type == ChatRoomType.ai) {
        _generateInitialAIMessage(newChatRoom.id);
      }

      return newChatRoom;
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

  /// 메시지 목록 조회
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));

      // 캐시에서 메시지 확인
      if (_messageCache.containsKey(chatRoomId)) {
        return List.from(_messageCache[chatRoomId]!);
      }

      // 새 채팅방인 경우 빈 목록 반환
      _messageCache[chatRoomId] = [];
      return [];
    } catch (e) {
      debugPrint('메시지 조회 오류: $e');
      // 오류 시에도 빈 목록 반환 (무한 로딩 방지)
      _messageCache[chatRoomId] = [];
      return [];
    }
  }

  /// 메시지 전송
  Future<Message> sendMessage({
    required String chatRoomId,
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 사용자 메시지 생성
      final message = _createMessage(
        chatRoomId: chatRoomId,
        content: content,
        senderId: senderId,
        type: type,
        metadata: metadata,
      );

      // 캐시에 메시지 추가
      _addMessageToCache(chatRoomId, message);

      // 실시간 스트림에 메시지 브로드캐스트
      _broadcastMessage(chatRoomId, message);

      // 채팅방 정보 업데이트
      _updateChatRoomLastMessage(chatRoomId, message);

      // AI 채팅방인 경우 자동 응답 생성
      if (chatRoomId.contains('ai') || _isAIChatRoom(chatRoomId)) {
        _scheduleAIResponse(chatRoomId, content);
      }

      return message;
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
      throw Exception('메시지 전송에 실패했습니다. 다시 시도해주세요.');
    }
  }

  /// 메시지 읽음 처리
  Future<bool> markMessagesAsRead(String chatRoomId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      // 채팅방의 읽지 않은 메시지 수 업데이트
      final chatRoomIndex = _chatRoomCache.indexWhere(
        (room) => room.id == chatRoomId,
      );
      if (chatRoomIndex != -1) {
        _chatRoomCache[chatRoomIndex] = _chatRoomCache[chatRoomIndex].copyWith(
          unreadCount: 0,
        );
      }

      return true;
    } catch (e) {
      debugPrint('읽음 처리 오류: $e');
      return false;
    }
  }

  /// 새 메시지 스트림
  Stream<Message> getNewMessageStream(String chatRoomId) {
    if (!_messageControllers.containsKey(chatRoomId)) {
      _messageControllers[chatRoomId] = StreamController<Message>.broadcast();
    }
    return _messageControllers[chatRoomId]!.stream;
  }

  /// 메시지 목록 스트림
  Stream<List<Message>> getMessagesStream(String chatRoomId) {
    if (!_messagesControllers.containsKey(chatRoomId)) {
      _messagesControllers[chatRoomId] =
          StreamController<List<Message>>.broadcast();
      // 초기 메시지 로드
      getMessages(chatRoomId).then((messages) {
        if (_messagesControllers.containsKey(chatRoomId)) {
          _messagesControllers[chatRoomId]!.add(messages);
        }
      });
    }
    return _messagesControllers[chatRoomId]!.stream;
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

  /// 리소스 정리
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
  }

  // === Private Helper Methods ===

  /// 메시지 생성
  Message _createMessage({
    required String chatRoomId,
    required String content,
    required String senderId,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id:
          'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
      chatRoomId: chatRoomId,
      content: content,
      senderId: senderId,
      senderName: senderId == 'ai' ? 'AI 상담사' : '나',
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      metadata: metadata,
    );
  }

  /// 캐시에 메시지 추가
  void _addMessageToCache(String chatRoomId, Message message) {
    if (!_messageCache.containsKey(chatRoomId)) {
      _messageCache[chatRoomId] = [];
    }
    _messageCache[chatRoomId]!.add(message);
  }

  /// 메시지 브로드캐스트
  void _broadcastMessage(String chatRoomId, Message message) {
    // 개별 메시지 스트림에 전송
    if (_messageControllers.containsKey(chatRoomId)) {
      _messageControllers[chatRoomId]!.add(message);
    }

    // 메시지 목록 스트림 업데이트
    if (_messagesControllers.containsKey(chatRoomId)) {
      final messages = _messageCache[chatRoomId] ?? [];
      _messagesControllers[chatRoomId]!.add(List.from(messages));
    }
  }

  /// 채팅방 마지막 메시지 업데이트
  void _updateChatRoomLastMessage(String chatRoomId, Message message) {
    final index = _chatRoomCache.indexWhere((room) => room.id == chatRoomId);
    if (index != -1) {
      _chatRoomCache[index] = _chatRoomCache[index].copyWith(
        lastMessage: message,
        updatedAt: DateTime.now(),
        unreadCount: message.senderId != 'current_user' ? 1 : 0,
      );
    }
  }

  /// AI 채팅방 여부 확인
  bool _isAIChatRoom(String chatRoomId) {
    try {
      final chatRoom = _chatRoomCache.firstWhere(
        (room) => room.id == chatRoomId,
      );
      return chatRoom.type == ChatRoomType.ai;
    } catch (e) {
      return chatRoomId.contains('ai');
    }
  }

  /// AI 응답 스케줄링
  void _scheduleAIResponse(String chatRoomId, String userMessage) {
    Timer(const Duration(seconds: 1, milliseconds: 500), () {
      _generateAIResponse(chatRoomId, userMessage);
    });
  }

  /// AI 응답 생성
  void _generateAIResponse(String chatRoomId, String userMessage) {
    final aiResponse = _getAIResponseText(userMessage);

    final aiMessage = _createMessage(
      chatRoomId: chatRoomId,
      content: aiResponse,
      senderId: 'ai',
      type: MessageType.aiResponse,
    );

    _addMessageToCache(chatRoomId, aiMessage);
    _broadcastMessage(chatRoomId, aiMessage);
    _updateChatRoomLastMessage(chatRoomId, aiMessage);
  }

  /// AI 응답 텍스트 생성
  String _getAIResponseText(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('안녕') ||
        message.contains('hello') ||
        message.contains('hi')) {
      return '안녕하세요! MentalFit AI 상담사입니다. 😊\n\n오늘은 어떤 고민이나 이야기를 나누고 싶으신가요?';
    } else if (message.contains('스트레스')) {
      return '스트레스를 받고 계시는군요. 😔\n\n어떤 상황에서 가장 스트레스를 많이 받으시나요? 구체적으로 말씀해주시면 더 도움이 될 것 같습니다.';
    } else if (message.contains('불안')) {
      return '불안감에 대해 말씀해주셔서 고맙습니다. 🤗\n\n경기 전이나 중요한 순간에 느끼는 불안감인가요? 언제부터 이런 감정을 느끼셨나요?';
    } else if (message.contains('경기') || message.contains('시합')) {
      return '경기와 관련된 고민이시군요. 🏃‍♀️\n\n경기 전 준비나 경기 중 집중력, 결과에 대한 부담감 등 어떤 부분이 가장 어려우신가요?';
    } else if (message.contains('집중') || message.contains('몰입')) {
      return '집중력에 대한 고민이시네요. 🎯\n\n운동할 때 집중이 잘 안 되는 특별한 상황이나 원인이 있으신가요?';
    } else if (message.contains('자신감') || message.contains('자존감')) {
      return '자신감에 대해 이야기해주셔서 감사합니다. 💪\n\n어떤 순간에 자신감이 떨어지시나요? 과거의 성공 경험을 떠올려보시는 것도 도움이 될 수 있어요.';
    } else if (message.contains('감사') || message.contains('고마워')) {
      return '별 말씀을요! 😊\n\n언제든지 편하게 이야기해주세요. 제가 도울 수 있는 일이 있으면 언제든 말씀해주세요.';
    } else if (message.contains('도움') || message.contains('조언')) {
      return '기꺼이 도와드릴게요! 🤝\n\n구체적으로 어떤 부분에서 도움이 필요하신지 자세히 말씀해주시면, 더 정확한 조언을 드릴 수 있을 것 같습니다.';
    } else {
      final responses = [
        '말씀해주신 내용을 잘 들었습니다. 🤔\n\n이런 상황에서 어떤 감정을 느끼셨나요?',
        '그런 경험을 하셨군요. 😌\n\n조금 더 자세히 설명해주시면 더 구체적인 도움을 드릴 수 있을 것 같습니다.',
        '이해합니다. 💭\n\n이런 상황에서 평소에는 어떻게 대처하시는 편인가요?',
        '공감합니다. 🫂\n\n비슷한 경험을 하신 적이 또 있으셨나요?',
        '잘 말씀해주셨습니다. ✨\n\n이 문제를 해결하기 위해 시도해보신 방법이 있으신가요?',
      ];
      return responses[Random().nextInt(responses.length)];
    }
  }

  /// 초기 AI 메시지 생성
  void _generateInitialAIMessage(String chatRoomId) {
    Timer(const Duration(milliseconds: 500), () {
      final welcomeMessage = _createMessage(
        chatRoomId: chatRoomId,
        content:
            '안녕하세요! MentalFit AI 상담사입니다. 😊\n\n저는 스포츠 심리 분야의 전문 지식을 바탕으로 운동선수들의 멘탈 관리를 도와드리고 있습니다.\n\n오늘은 어떤 이야기를 나누고 싶으신가요?',
        senderId: 'ai',
        type: MessageType.aiResponse,
      );

      _addMessageToCache(chatRoomId, welcomeMessage);
      _broadcastMessage(chatRoomId, welcomeMessage);
      _updateChatRoomLastMessage(chatRoomId, welcomeMessage);
    });
  }

  /// 기본 채팅방 생성
  ChatRoom _createDefaultChatRoom(String chatRoomId) {
    final isAI = chatRoomId.contains('ai');
    return ChatRoom(
      id: chatRoomId,
      title: isAI ? 'AI 상담' : '상담',
      type: isAI ? ChatRoomType.ai : ChatRoomType.counselor,
      participantIds: ['current_user', isAI ? 'ai' : 'counselor'],
      unreadCount: 0,
      status: ChatRoomStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 초기 채팅방 목록
  List<ChatRoom> _getInitialChatRooms() {
    return [
      ChatRoom(
        id: 'ai_chat_main',
        title: 'AI 상담',
        type: ChatRoomType.ai,
        participantIds: ['current_user', 'ai'],
        lastMessage: Message(
          id: 'welcome_msg',
          chatRoomId: 'ai_chat_main',
          content: '안녕하세요! 언제든지 편하게 이야기해주세요.',
          senderId: 'ai',
          senderName: 'AI 상담사',
          type: MessageType.aiResponse,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true,
        ),
        unreadCount: 0,
        topic: '일반 상담',
        status: ChatRoomStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
