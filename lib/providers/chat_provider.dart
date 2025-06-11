import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/chat_room_model.dart';
import '../shared/models/message_model.dart';
import '../shared/services/chat_service.dart';

// === 채팅 서비스 프로바이더 ===
final chatServiceProvider = FutureProvider<ChatService>((ref) {
  return ChatService.getInstance();
});

// === 채팅방 상태 ===
class ChatRoomsState {
  final List<ChatRoom> chatRooms;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const ChatRoomsState({
    this.chatRooms = const [],
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  ChatRoomsState copyWith({
    List<ChatRoom>? chatRooms,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return ChatRoomsState(
      chatRooms: chatRooms ?? this.chatRooms,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

// === 채팅방 상태 관리 ===
class ChatRoomsNotifier extends StateNotifier<ChatRoomsState> {
  ChatService? _chatService;
  bool _isInitializing = false;

  ChatRoomsNotifier() : super(const ChatRoomsState());

  /// 서비스 초기화 (개선된 버전)
  Future<void> initializeIfNeeded() async {
    // 이미 초기화 중이거나 완료된 경우 스킵
    if (_isInitializing || state.isInitialized) {
      return;
    }

    _isInitializing = true;

    // 로딩 상태 설정
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ChatService 초기화
      _chatService = await ChatService.getInstance();

      // 초기화 완료 표시
      state = state.copyWith(isInitialized: true);

      // 초기 데이터 로드 (loadChatRooms 호출하지 않고 직접 처리)
      await _loadInitialData();
    } catch (e) {
      // 초기화 실패 시에도 기본 상태 제공
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: '채팅 서비스를 초기화하는 중 오류가 발생했습니다.',
        chatRooms: [_createDefaultAIChatRoom()], // 기본 AI 채팅방 제공
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// 초기 데이터 로드 (내부 메서드)
  Future<void> _loadInitialData() async {
    try {
      if (_chatService == null) {
        throw Exception('ChatService가 초기화되지 않았습니다.');
      }

      final chatRooms = await _chatService!.getChatRooms();

      state = state.copyWith(
        chatRooms: chatRooms,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      // 데이터 로드 실패 시 기본 데이터 제공
      state = state.copyWith(
        isLoading: false,
        error: null, // 에러를 null로 설정하여 UI에서 정상 동작하도록
        chatRooms: [_createDefaultAIChatRoom()],
      );
    }
  }

  /// 서비스 가져오기 (안전한 버전)
  Future<ChatService> _getService() async {
    if (_chatService == null) {
      await initializeIfNeeded();
    }

    if (_chatService == null) {
      throw Exception('ChatService 초기화에 실패했습니다.');
    }

    return _chatService!;
  }

  /// 채팅방 목록 로드 (개선된 버전)
  Future<void> loadChatRooms() async {
    // 초기화되지 않은 경우 먼저 초기화
    if (!state.isInitialized) {
      await initializeIfNeeded();
      return;
    }

    // 이미 로딩 중인 경우 중복 방지
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = await _getService();
      final chatRooms = await service.getChatRooms();

      state = state.copyWith(
        chatRooms: chatRooms,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '채팅방 목록을 불러오는 중 오류가 발생했습니다.',
        // 에러 발생 시에도 기존 데이터 유지하거나 기본 데이터 제공
        chatRooms:
            state.chatRooms.isEmpty ? [_createDefaultAIChatRoom()] : null,
      );
    }
  }

  /// 새 채팅방 생성
  Future<String?> createChatRoom({
    required String title,
    required ChatRoomType type,
    String? counselorId,
    String? topic,
  }) async {
    try {
      final service = await _getService();
      final chatRoom = await service.createChatRoom(
        title: title,
        type: type,
        counselorId: counselorId,
        topic: topic,
      );

      // 새 채팅방을 목록에 추가
      await loadChatRooms();

      return chatRoom.id;
    } catch (e) {
      state = state.copyWith(error: '채팅방을 생성하는 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// 채팅방 삭제 (로컬 상태에서만 제거)
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // ChatService에 deleteChatRoom 메서드가 없으므로 로컬 상태에서만 제거
      final updatedList =
          state.chatRooms
              .where((chatRoom) => chatRoom.id != chatRoomId)
              .toList();

      state = state.copyWith(chatRooms: updatedList);
    } catch (e) {
      state = state.copyWith(error: '채팅방을 삭제하는 중 오류가 발생했습니다.');
    }
  }

  /// 읽음 처리
  Future<void> markAsRead(String chatRoomId) async {
    try {
      final service = await _getService();
      await service.markMessagesAsRead(chatRoomId);

      final updatedList =
          state.chatRooms.map((chatRoom) {
            if (chatRoom.id == chatRoomId) {
              return chatRoom.copyWith(unreadCount: 0);
            }
            return chatRoom;
          }).toList();

      state = state.copyWith(chatRooms: updatedList);
    } catch (e) {
      // 읽음 처리 실패 시에도 UI 상에서는 읽음 처리
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

  /// 에러 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 강제 새로고침
  Future<void> refresh() async {
    await loadChatRooms();
  }

  /// 기본 AI 채팅방 생성
  ChatRoom _createDefaultAIChatRoom() {
    return ChatRoom(
      id: 'ai_chat_default_${DateTime.now().millisecondsSinceEpoch}',
      title: 'AI 상담',
      type: ChatRoomType.ai,
      participantIds: ['current_user', 'ai'],
      unreadCount: 0,
      status: ChatRoomStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 새 AI 채팅방 생성 (편의 메서드)
  Future<ChatRoom?> createAIChatRoom({String? topic}) async {
    try {
      final service = await _getService();
      final chatRoom = await service.createAIChatRoom(topic: topic);

      // 상태 업데이트
      state = state.copyWith(chatRooms: [chatRoom, ...state.chatRooms]);

      return chatRoom;
    } catch (e) {
      state = state.copyWith(error: 'AI 채팅방을 생성하는 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// 새 상담사 채팅방 생성 (편의 메서드)
  Future<ChatRoom?> createCounselorChatRoom({
    required String counselorId,
    required String counselorName,
    String? topic,
  }) async {
    try {
      final service = await _getService();
      final chatRoom = await service.createCounselorChatRoom(
        counselorId: counselorId,
        counselorName: counselorName,
        topic: topic,
      );

      // 상태 업데이트
      state = state.copyWith(chatRooms: [chatRoom, ...state.chatRooms]);

      return chatRoom;
    } catch (e) {
      state = state.copyWith(error: '상담사 채팅방을 생성하는 중 오류가 발생했습니다.');
      return null;
    }
  }
}

// === 채팅방 목록 프로바이더 ===
final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, ChatRoomsState>((ref) {
      return ChatRoomsNotifier();
    });

// === 메시지 상태 ===
class ChatMessagesState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final bool isInitialized;
  final String? error;

  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isInitialized = false,
    this.error,
  });

  ChatMessagesState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isInitialized,
    String? error,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

// === 메시지 상태 관리 ===
class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final String chatRoomId;
  ChatService? _chatService;
  bool _isInitializing = false;

  ChatMessagesNotifier(this.chatRoomId) : super(const ChatMessagesState());

  /// 서비스 초기화
  Future<void> initializeIfNeeded() async {
    if (_isInitializing || state.isInitialized) return;

    _isInitializing = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      _chatService = await ChatService.getInstance();
      state = state.copyWith(isInitialized: true);
      await _loadInitialMessages();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: '메시지를 불러오는 중 오류가 발생했습니다.',
        messages: [],
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// 초기 메시지 로드
  Future<void> _loadInitialMessages() async {
    try {
      if (_chatService == null) {
        throw Exception('ChatService가 초기화되지 않았습니다.');
      }

      final messages = await _chatService!.getMessages(chatRoomId);

      state = state.copyWith(messages: messages, isLoading: false, error: null);

      // 실시간 메시지 스트림 구독 시작
      _subscribeToMessageStream();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: null, // 에러를 null로 하여 빈 메시지 목록으로 정상 동작
        messages: [],
      );
    }
  }

  Future<ChatService> _getService() async {
    if (_chatService == null) {
      await initializeIfNeeded();
    }

    if (_chatService == null) {
      throw Exception('ChatService 초기화에 실패했습니다.');
    }

    return _chatService!;
  }

  /// 메시지 목록 로드
  Future<void> loadMessages() async {
    if (!state.isInitialized) {
      await initializeIfNeeded();
      return;
    }

    if (state.isLoading) return; // 중복 로딩 방지

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = await _getService();
      final messages = await service.getMessages(chatRoomId);

      state = state.copyWith(messages: messages, isLoading: false, error: null);

      _subscribeToMessageStream();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '메시지를 불러올 수 없습니다.',
        messages: state.messages, // 기존 메시지 유지
      );
    }
  }

  /// 메시지 전송
  Future<void> sendMessage({
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (state.isSending) return; // 중복 전송 방지

    state = state.copyWith(isSending: true, error: null);

    try {
      final service = await _getService();
      final message = await service.sendMessage(
        chatRoomId: chatRoomId,
        content: content,
        senderId: senderId,
        type: type,
        metadata: metadata,
      );

      // 새 메시지를 목록에 추가
      final updatedMessages = [...state.messages, message];
      state = state.copyWith(messages: updatedMessages, isSending: false);
    } catch (e) {
      state = state.copyWith(isSending: false, error: '메시지 전송에 실패했습니다.');
    }
  }

  /// 실시간 메시지 스트림 구독
  void _subscribeToMessageStream() {
    try {
      _chatService
          ?.getNewMessageStream(chatRoomId)
          .listen(
            (newMessage) {
              if (!mounted) return;

              final updatedMessages = [...state.messages, newMessage];
              state = state.copyWith(messages: updatedMessages);
            },
            onError: (error) {
              // 스트림 에러는 조용히 처리
            },
          );
    } catch (e) {
      // 스트림 구독 실패는 조용히 처리
    }
  }

  /// 메시지 목록 초기화
  void clearMessages() {
    state = state.copyWith(messages: [], error: null);
  }

  /// 에러 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === 개별 채팅방 메시지 프로바이더 ===
final chatMessagesProvider = StateNotifierProvider.family<
  ChatMessagesNotifier,
  ChatMessagesState,
  String
>((ref, chatRoomId) {
  return ChatMessagesNotifier(chatRoomId);
});

// === 편의용 프로바이더들 ===

/// 읽지 않은 메시지 총 개수
final unreadMessagesCountProvider = Provider<int>((ref) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  return chatRoomsState.chatRooms.fold<int>(
    0,
    (sum, chatRoom) => sum + chatRoom.unreadCount,
  );
});

/// 채팅방 로딩 상태
final chatRoomsLoadingProvider = Provider<bool>((ref) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  return chatRoomsState.isLoading;
});

/// 채팅방 초기화 상태
final chatRoomsInitializedProvider = Provider<bool>((ref) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  return chatRoomsState.isInitialized;
});

/// 채팅방 에러 상태
final chatRoomsErrorProvider = Provider<String?>((ref) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  return chatRoomsState.error;
});

/// 특정 채팅방의 메시지 로딩 상태
final chatMessagesLoadingProvider = Provider.family<bool, String>((
  ref,
  chatRoomId,
) {
  final messagesState = ref.watch(chatMessagesProvider(chatRoomId));
  return messagesState.isLoading;
});

/// 특정 채팅방의 메시지 전송 상태
final chatMessagesSendingProvider = Provider.family<bool, String>((
  ref,
  chatRoomId,
) {
  final messagesState = ref.watch(chatMessagesProvider(chatRoomId));
  return messagesState.isSending;
});

/// 특정 채팅방의 메시지 에러 상태
final chatMessagesErrorProvider = Provider.family<String?, String>((
  ref,
  chatRoomId,
) {
  final messagesState = ref.watch(chatMessagesProvider(chatRoomId));
  return messagesState.error;
});

/// AI 채팅방 필터
final aiChatRoomsProvider = Provider<List<ChatRoom>>((ref) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  return chatRoomsState.chatRooms
      .where((chatRoom) => chatRoom.type == ChatRoomType.ai)
      .toList();
});

/// 상담사 채팅방 필터
final counselorChatRoomsProvider = Provider<List<ChatRoom>>((ref) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  return chatRoomsState.chatRooms
      .where((chatRoom) => chatRoom.type == ChatRoomType.counselor)
      .toList();
});

/// 최근 활성 채팅방 (홈 화면용)
final recentActiveChatRoomsProvider = Provider<List<ChatRoom>>((ref) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  return chatRoomsState.chatRooms
      .where((chatRoom) => chatRoom.lastMessage != null)
      .take(3)
      .toList();
});

/// 특정 채팅방 정보 (단일 조회)
final chatRoomProvider = Provider.family<ChatRoom?, String>((ref, chatRoomId) {
  final chatRoomsState = ref.watch(chatRoomsProvider);
  try {
    return chatRoomsState.chatRooms.firstWhere(
      (chatRoom) => chatRoom.id == chatRoomId,
    );
  } catch (e) {
    return null;
  }
});
