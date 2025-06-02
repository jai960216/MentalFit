import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/chat_room_model.dart';
import '../shared/models/message_model.dart';

// 채팅방 목록 상태
class ChatRoomsState {
  final List<ChatRoom> chatRooms;
  final bool isLoading;
  final String? error;

  const ChatRoomsState({
    this.chatRooms = const [],
    this.isLoading = false,
    this.error,
  });

  ChatRoomsState copyWith({
    List<ChatRoom>? chatRooms,
    bool? isLoading,
    String? error,
  }) {
    return ChatRoomsState(
      chatRooms: chatRooms ?? this.chatRooms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 채팅방 목록 관리
class ChatRoomsNotifier extends StateNotifier<ChatRoomsState> {
  ChatRoomsNotifier() : super(const ChatRoomsState());

  // 채팅방 목록 불러오기
  Future<void> loadChatRooms() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 실제 API 호출로 교체
      await Future.delayed(const Duration(seconds: 1));

      // 임시 데이터
      final chatRooms = [
        ChatRoom(
          id: 'chat_1',
          title: 'AI 상담',
          type: ChatRoomType.ai,
          participantIds: ['user_123', 'ai'],
          lastMessage: Message(
            id: 'msg_1',
            chatRoomId: 'chat_1',
            senderId: 'ai',
            content: '안녕하세요! 어떤 도움이 필요하신가요?',
            type: MessageType.text,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: false,
          ),
          unreadCount: 1,
          topic: '전체',
          status: ChatRoomStatus.active,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ChatRoom(
          id: 'chat_2',
          title: '김상담님과의 상담',
          type: ChatRoomType.counselor,
          participantIds: ['user_123', 'counselor_1'],
          counselorId: 'counselor_1',
          counselorName: '김상담',
          lastMessage: Message(
            id: 'msg_2',
            chatRoomId: 'chat_2',
            senderId: 'counselor_1',
            senderName: '김상담',
            content: '다음 상담 일정을 확인해주세요.',
            type: MessageType.text,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: true,
          ),
          unreadCount: 0,
          topic: '스트레스',
          status: ChatRoomStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      state = state.copyWith(chatRooms: chatRooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 새 AI 채팅방 생성
  Future<ChatRoom> createAIChatRoom({required String topic}) async {
    try {
      // TODO: API 호출
      await Future.delayed(const Duration(milliseconds: 500));

      final newChatRoom = ChatRoom(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
        title: 'AI 상담 - $topic',
        type: ChatRoomType.ai,
        participantIds: ['user_123', 'ai'],
        topic: topic,
        unreadCount: 0,
        status: ChatRoomStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(chatRooms: [newChatRoom, ...state.chatRooms]);

      return newChatRoom;
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    }
  }

  // 채팅방 업데이트
  void updateChatRoom(ChatRoom updatedChatRoom) {
    final updatedList =
        state.chatRooms.map((chatRoom) {
          return chatRoom.id == updatedChatRoom.id ? updatedChatRoom : chatRoom;
        }).toList();

    state = state.copyWith(chatRooms: updatedList);
  }

  // 채팅방 삭제
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // TODO: API 호출
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedList =
          state.chatRooms
              .where((chatRoom) => chatRoom.id != chatRoomId)
              .toList();

      state = state.copyWith(chatRooms: updatedList);
    } catch (e) {
      throw Exception('채팅방 삭제 실패: $e');
    }
  }

  // 읽음 처리
  void markAsRead(String chatRoomId) {
    final updatedList =
        state.chatRooms.map((chatRoom) {
          if (chatRoom.id == chatRoomId) {
            return chatRoom.copyWith(unreadCount: 0);
          }
          return chatRoom;
        }).toList();

    state = state.copyWith(chatRooms: updatedList);
  }
}

// 개별 채팅방 메시지 상태
class ChatMessagesState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ChatMessagesState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

// 채팅 메시지 관리
class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final String chatRoomId;

  ChatMessagesNotifier(this.chatRoomId) : super(const ChatMessagesState());

  // 메시지 목록 불러오기
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 실제 API 호출로 교체
      await Future.delayed(const Duration(seconds: 1));

      // 임시 메시지 데이터
      final messages = <Message>[
        Message(
          id: 'msg_welcome',
          chatRoomId: chatRoomId,
          senderId: 'ai',
          content: '안녕하세요! MentalFit AI 상담사입니다. 어떤 고민이 있으신가요?',
          type: MessageType.aiResponse,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          isRead: true,
        ),
      ];

      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 메시지 전송
  Future<void> sendMessage({
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
  }) async {
    if (content.trim().isEmpty) return;

    state = state.copyWith(isSending: true);

    try {
      // 사용자 메시지 즉시 추가
      final userMessage = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatRoomId: chatRoomId,
        senderId: senderId,
        content: content.trim(),
        type: type,
        timestamp: DateTime.now(),
        isRead: true,
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage],
        isSending: false,
      );

      // AI 응답 시뮬레이션 (실제로는 API 호출)
      if (chatRoomId.contains('ai') || senderId != 'ai') {
        await _simulateAIResponse(content);
      }
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  // AI 응답 시뮬레이션
  Future<void> _simulateAIResponse(String userMessage) async {
    await Future.delayed(const Duration(seconds: 2));

    // 간단한 AI 응답 로직
    String aiResponse;
    if (userMessage.contains('스트레스')) {
      aiResponse = '스트레스를 받고 계시는군요. 어떤 상황에서 가장 스트레스를 많이 받으시나요?';
    } else if (userMessage.contains('불안')) {
      aiResponse = '불안감에 대해 말씀해주셔서 고맙습니다. 언제부터 이런 감정을 느끼셨나요?';
    } else if (userMessage.contains('경기')) {
      aiResponse = '경기와 관련된 고민이시군요. 구체적으로 어떤 부분이 걱정되시나요?';
    } else {
      aiResponse = '말씀해주신 내용을 잘 이해했습니다. 더 자세히 설명해주실 수 있나요?';
    }

    final aiMessage = Message(
      id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: chatRoomId,
      senderId: 'ai',
      content: aiResponse,
      type: MessageType.aiResponse,
      timestamp: DateTime.now(),
      isRead: true,
    );

    state = state.copyWith(messages: [...state.messages, aiMessage]);
  }

  // 메시지 삭제
  void deleteMessage(String messageId) {
    final updatedMessages =
        state.messages.where((message) => message.id != messageId).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  // 메시지 초기화
  void clearMessages() {
    state = const ChatMessagesState();
  }
}

// Provider 정의
final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, ChatRoomsState>((ref) {
      return ChatRoomsNotifier();
    });

// 개별 채팅방 메시지 Provider
final chatMessagesProvider = StateNotifierProvider.family<
  ChatMessagesNotifier,
  ChatMessagesState,
  String
>((ref, chatRoomId) {
  return ChatMessagesNotifier(chatRoomId);
});

// 편의용 Provider들
final totalUnreadCountProvider = Provider<int>((ref) {
  final chatRooms = ref.watch(chatRoomsProvider).chatRooms;
  return chatRooms.fold(0, (sum, chatRoom) => sum + chatRoom.unreadCount);
});

final activeChatRoomsProvider = Provider<List<ChatRoom>>((ref) {
  final chatRooms = ref.watch(chatRoomsProvider).chatRooms;
  return chatRooms.where((chatRoom) => chatRoom.isActive).toList();
});

final aiChatRoomsProvider = Provider<List<ChatRoom>>((ref) {
  final chatRooms = ref.watch(chatRoomsProvider).chatRooms;
  return chatRooms.where((chatRoom) => chatRoom.isAIChat).toList();
});
