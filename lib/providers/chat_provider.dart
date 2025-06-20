import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_mentalfit/shared/models/chat_room_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ChatRoom에서 Message를 이미 export하므로 별도 import 불필요
import '../shared/services/chat_service.dart';

// === 채팅방 목록 상태 ===
class ChatListState {
  final List<ChatRoom> aiChatRooms;
  final List<ChatRoom> counselorChatRooms;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const ChatListState({
    this.aiChatRooms = const [],
    this.counselorChatRooms = const [],
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  ChatListState copyWith({
    List<ChatRoom>? aiChatRooms,
    List<ChatRoom>? counselorChatRooms,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return ChatListState(
      aiChatRooms: aiChatRooms ?? this.aiChatRooms,
      counselorChatRooms: counselorChatRooms ?? this.counselorChatRooms,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

// === 채팅방 목록 Provider ===
class ChatListNotifier extends StateNotifier<ChatListState> {
  ChatService? _chatService;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  bool _isInitializing = false;

  ChatListNotifier() : super(const ChatListState()) {
    initializeIfNeeded();
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    _chatService?.dispose();
    super.dispose();
  }

  /// 서비스 초기화 및 실시간 스트림 구독
  Future<void> initializeIfNeeded() async {
    if (state.isInitialized || _isInitializing) return;

    _isInitializing = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      _chatService = await ChatService.getInstance();

      // Firebase 연결 상태 확인
      final isConnected = await _chatService!.isConnected();
      if (!isConnected) {
        throw Exception('Firebase에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.');
      }

      // 실시간 채팅방 목록 스트림 구독
      await _subscribeToChatRoomsStream();

      // 초기 데이터 로드
      await _loadInitialChatRooms();

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('ChatListNotifier 초기화 실패: $e');
      state = state.copyWith(
        isLoading: false,
        error: '채팅 서비스를 초기화할 수 없습니다. 인터넷 연결을 확인해주세요.',
        isInitialized: false,
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// 초기 채팅방 목록 로드
  Future<void> _loadInitialChatRooms() async {
    try {
      if (_chatService != null) {
        // 명시적으로 채팅방 목록 한 번 로드
        final chatRooms = await _chatService!.getChatRooms();
        state = state.copyWith(aiChatRooms: chatRooms);
      }
    } catch (e) {
      debugPrint('초기 채팅방 로드 실패: $e');
      // 초기 로드 실패 시에도 스트림은 유지
    }
  }

  /// 실시간 채팅방 목록 스트림 구독
  Future<void> _subscribeToChatRoomsStream() async {
    try {
      _chatRoomsSubscription?.cancel();

      if (_chatService != null) {
        // 스트림 구독 전 잠시 대기 (Firebase 연결 안정화)
        await Future.delayed(const Duration(milliseconds: 500));

        final stream = _chatService!.getChatRoomsStream();
        _chatRoomsSubscription = stream.listen(
          (chatRooms) {
            if (mounted) {
              final aiRooms =
                  chatRooms.where((cr) => cr.type == ChatRoomType.ai).toList();
              final counselorRooms =
                  chatRooms
                      .where((cr) => cr.type == ChatRoomType.counselor)
                      .toList();
              state = state.copyWith(
                aiChatRooms: aiRooms,
                counselorChatRooms: counselorRooms,
                isLoading: false,
                error: null,
              );
            }
          },
          onError: (error) {
            debugPrint('채팅방 스트림 오류: $error');
            if (mounted) {
              state = state.copyWith(
                error: '채팅방 목록을 불러오는 중 오류가 발생했습니다.',
                isLoading: false,
              );
            }
          },
        );
      }
    } catch (e) {
      debugPrint('채팅방 스트림 구독 실패: $e');
    }
  }

  /// 채팅방 목록 새로고침
  Future<void> refreshChatRooms() async {
    if (!state.isInitialized) {
      await initializeIfNeeded();
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      if (_chatService != null) {
        final chatRooms = await _chatService!.getChatRooms();
        final aiRooms =
            chatRooms.where((cr) => cr.type == ChatRoomType.ai).toList();
        final counselorRooms =
            chatRooms.where((cr) => cr.type == ChatRoomType.counselor).toList();
        state = state.copyWith(
          aiChatRooms: aiRooms,
          counselorChatRooms: counselorRooms,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      debugPrint('채팅방 새로고침 실패: $e');
      state = state.copyWith(isLoading: false, error: '채팅방 목록을 새로고침할 수 없습니다.');
    }
  }

  /// 새 채팅방 생성
  Future<String?> createChatRoom({
    required String title,
    required ChatRoomType type,
    String? counselorId,
    String? topic,
  }) async {
    if (!state.isInitialized) {
      await initializeIfNeeded();
    }

    try {
      if (_chatService != null) {
        final chatRoom = await _chatService!.createChatRoom(
          title: title,
          type: type,
          counselorId: counselorId,
          topic: topic,
        );

        // Firebase 실시간 스트림이 자동으로 업데이트 처리
        return chatRoom.id;
      }
      return null;
    } catch (e) {
      debugPrint('채팅방 생성 실패: $e');
      state = state.copyWith(error: '채팅방을 생성하는 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// AI 채팅방 생성
  Future<String?> createAIChatRoom({String? topic}) async {
    return await createChatRoom(
      title: topic != null ? 'AI 상담 - $topic' : 'AI 상담',
      type: ChatRoomType.ai,
      topic: topic,
    );
  }

  /// 상담사 채팅방 생성
  Future<String?> createCounselorChatRoom({
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
    try {
      if (_chatService != null) {
        final success = await _chatService!.deleteChatRoom(chatRoomId);

        if (success) {
          // Firebase 실시간 스트림이 자동으로 업데이트 처리
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('채팅방 삭제 실패: $e');
      state = state.copyWith(error: '채팅방을 삭제하는 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 에러 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      if (_chatService != null) {
        return await _chatService!.isConnected();
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// === 채팅방 상세 상태 ===
class ChatRoomState {
  final List<Message> messages;
  final bool isLoading;
  final bool isInitialized;
  final bool isSending;
  final String? error;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isInitialized = false,
    this.isSending = false,
    this.error,
  });

  ChatRoomState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isInitialized,
    bool? isSending,
    String? error,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

// === 채팅방 상세 Provider ===
class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final String chatRoomId;
  ChatService? _chatService;
  StreamSubscription<List<Message>>? _messagesSubscription;
  bool _isInitializing = false;

  ChatRoomNotifier(this.chatRoomId) : super(const ChatRoomState()) {
    initializeIfNeeded();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// 서비스 초기화 및 실시간 메시지 스트림 구독
  Future<void> initializeIfNeeded() async {
    if (state.isInitialized || _isInitializing) return;

    _isInitializing = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      _chatService = await ChatService.getInstance();

      // 실시간 메시지 스트림 구독
      await _subscribeToMessagesStream();

      // 메시지 읽음 처리
      await markAsRead();

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('ChatRoomNotifier 초기화 실패: $e');
      state = state.copyWith(
        isLoading: false,
        error: '채팅을 불러올 수 없습니다.',
        isInitialized: false,
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// 실시간 메시지 스트림 구독
  Future<void> _subscribeToMessagesStream() async {
    try {
      _messagesSubscription?.cancel();

      if (_chatService != null) {
        final stream = _chatService!.getMessagesStream(chatRoomId);
        _messagesSubscription = stream.listen(
          (messages) {
            state = state.copyWith(
              messages: messages,
              isLoading: false,
              error: null,
            );
          },
          onError: (error) {
            debugPrint('메시지 스트림 오류: $error');
            state = state.copyWith(
              error: '메시지를 불러오는 중 오류가 발생했습니다.',
              isLoading: false,
            );
          },
        );
      }
    } catch (e) {
      debugPrint('메시지 스트림 구독 실패: $e');
    }
  }

  /// 메시지 전송
  Future<bool> sendMessage(String content) async {
    if (!state.isInitialized) {
      await initializeIfNeeded();
    }

    if (state.isSending || content.trim().isEmpty) return false;

    state = state.copyWith(isSending: true, error: null);

    try {
      if (_chatService != null) {
        await _chatService!.sendMessage(
          chatRoomId: chatRoomId,
          content: content.trim(),
          senderId: 'current_user', // 실제로는 Firebase Auth에서 가져올 예정
          type: MessageType.text,
        );

        state = state.copyWith(isSending: false);
        return true;
      }

      state = state.copyWith(isSending: false);
      return false;
    } catch (e) {
      debugPrint('메시지 전송 실패: $e');
      state = state.copyWith(isSending: false, error: '메시지 전송에 실패했습니다.');
      return false;
    }
  }

  /// 이미지 메시지 전송
  Future<bool> sendImageMessage(File imageFile) async {
    if (!state.isInitialized) {
      await initializeIfNeeded();
    }

    if (state.isSending) return false;

    state = state.copyWith(isSending: true, error: null);

    try {
      if (_chatService != null) {
        await _chatService!.sendImageMessage(
          chatRoomId: chatRoomId,
          imageFile: imageFile,
          senderId: 'current_user',
        );

        state = state.copyWith(isSending: false);
        return true;
      }

      state = state.copyWith(isSending: false);
      return false;
    } catch (e) {
      debugPrint('이미지 전송 실패: $e');
      state = state.copyWith(isSending: false, error: '이미지 전송에 실패했습니다.');
      return false;
    }
  }

  /// 파일 메시지 전송
  Future<bool> sendFileMessage(File file) async {
    if (!state.isInitialized) {
      await initializeIfNeeded();
    }

    if (state.isSending) return false;

    state = state.copyWith(isSending: true, error: null);

    try {
      if (_chatService != null) {
        await _chatService!.sendFileMessage(
          chatRoomId: chatRoomId,
          file: file,
          senderId: 'current_user',
        );

        state = state.copyWith(isSending: false);
        return true;
      }

      state = state.copyWith(isSending: false);
      return false;
    } catch (e) {
      debugPrint('파일 전송 실패: $e');
      state = state.copyWith(isSending: false, error: '파일 전송에 실패했습니다.');
      return false;
    }
  }

  /// 메시지 읽음 처리
  Future<void> markAsRead() async {
    try {
      if (_chatService != null) {
        await _chatService!.markMessagesAsRead(chatRoomId);
      }
    } catch (e) {
      debugPrint('읽음 처리 실패: $e');
    }
  }

  /// 메시지 새로고침
  Future<void> refreshMessages() async {
    if (!state.isInitialized) {
      await initializeIfNeeded();
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      if (_chatService != null) {
        final messages = await _chatService!.getMessages(chatRoomId);
        state = state.copyWith(
          messages: messages,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      debugPrint('메시지 새로고침 실패: $e');
      state = state.copyWith(isLoading: false, error: '메시지를 새로고침할 수 없습니다.');
    }
  }

  /// 에러 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 타이핑 상태 업데이트
  void updateTypingStatus(bool isTyping) {
    try {
      if (_chatService != null) {
        _chatService!.updateTypingStatus(chatRoomId, 'current_user', isTyping);
      }
    } catch (e) {
      debugPrint('타이핑 상태 업데이트 실패: $e');
    }
  }

  /// 타이핑 상태 스트림
  Stream<Map<String, bool>> getTypingStream() {
    if (_chatService != null) {
      return _chatService!.getTypingStream(chatRoomId);
    }
    return Stream.value({});
  }
}

// === Provider 정의 ===

/// 채팅방 목록 Provider
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>(
  (ref) {
    return ChatListNotifier();
  },
);

/// 채팅방 상세 Provider (Family)
final chatRoomProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, String>((
      ref,
      chatRoomId,
    ) {
      return ChatRoomNotifier(chatRoomId);
    });

/// 현재 사용자 ID Provider (임시)
final currentUserIdProvider = Provider<String>((ref) {
  // 실제로는 Firebase Auth에서 가져올 예정
  return 'current_user';
});

/// 읽지 않은 메시지 총 개수 Provider
final totalUnreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final chatService = await ChatService.getInstance();
    return await chatService.getTotalUnreadCount();
  } catch (e) {
    return 0;
  }
});

/// 특정 채팅방 정보 Provider
final chatRoomInfoProvider = FutureProvider.family<ChatRoom?, String>((
  ref,
  chatRoomId,
) async {
  try {
    final chatService = await ChatService.getInstance();
    return await chatService.getChatRoom(chatRoomId);
  } catch (e) {
    return null;
  }
});

/// Firebase 연결 상태 Provider
final chatConnectionProvider = FutureProvider<bool>((ref) async {
  try {
    final chatService = await ChatService.getInstance();
    return await chatService.isConnected();
  } catch (e) {
    return false;
  }
});
