import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_mentalfit/shared/models/chat_room_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ChatRoom에서 Message를 이미 export하므로 별도 import 불필요
import '../shared/services/chat_service.dart';
import '../shared/services/ai_chat_local_service.dart';
import '../shared/models/ai_chat_models.dart';

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
  
  // AI 채팅 기록 실시간 업데이트를 위한 타이머
  Timer? _aiChatUpdateTimer;

  ChatListNotifier() : super(const ChatListState()) {
    initializeIfNeeded();
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    _aiChatUpdateTimer?.cancel();
    _chatService?.dispose();
    super.dispose();
  }

  /// 서비스 초기화 및 실시간 스트림 구독
  Future<void> initializeIfNeeded() async {
    if (state.isInitialized || _isInitializing) return;

    _isInitializing = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🔄 채팅 서비스 초기화 시작');
      _chatService = await ChatService.getInstance();
      debugPrint('✅ 채팅 서비스 인스턴스 생성 완료');

      // 실시간 채팅방 목록 스트림 구독
      await _subscribeToChatRoomsStream();
      debugPrint('✅ 채팅방 스트림 구독 완료');

      // 초기 데이터 로드
      await _loadInitialChatRooms();
      debugPrint('✅ 초기 채팅방 데이터 로드 완료');

      // AI 채팅 기록 실시간 업데이트 시작
      _startAIChatUpdateTimer();
      debugPrint('✅ AI 채팅 업데이트 타이머 시작');

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        error: null,
      );
      debugPrint('✅ 채팅 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ ChatListNotifier 초기화 실패: $e');
      
      // 부분적 초기화 시도 (AI 채팅만이라도)
      try {
        final localAiRooms = await _loadLocalAIChatRooms();
        state = state.copyWith(
          aiChatRooms: localAiRooms,
          isLoading: false,
          error: '상담사 채팅 연결에 실패했습니다. AI 채팅은 사용 가능합니다.',
          isInitialized: true, // 부분적으로라도 초기화 완료로 표시
        );
        debugPrint('✅ AI 채팅만 부분 초기화 완료');
      } catch (e2) {
        state = state.copyWith(
          isLoading: false,
          error: '채팅 서비스를 초기화할 수 없습니다. 앱을 재시작해주세요.',
          isInitialized: false,
        );
        debugPrint('❌ 부분 초기화도 실패: $e2');
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// 초기 채팅방 목록 로드
  Future<void> _loadInitialChatRooms() async {
    try {
      // AI 채팅 기록을 로컬에서 불러오기
      final localAiRooms = await _loadLocalAIChatRooms();
      
      if (_chatService != null) {
        // Firebase에서 상담사 채팅방 목록 로드
        final chatRooms = await _chatService!.getChatRooms();

        // 상담사 채팅방만 분류
        final counselorRooms = <ChatRoom>[];

        for (final room in chatRooms) {
          try {
            if (room.type.value == 'counselor') {
              counselorRooms.add(room);
            }
          } catch (e) {
            debugPrint('채팅방 분류 오류: $e');
          }
        }

        state = state.copyWith(
          aiChatRooms: localAiRooms,
          counselorChatRooms: counselorRooms,
        );
      } else {
        // 채팅 서비스가 없어도 로컬 AI 채팅은 표시
        state = state.copyWith(
          aiChatRooms: localAiRooms,
          counselorChatRooms: const [],
        );
      }
    } catch (e) {
      debugPrint('초기 채팅방 로드 실패: $e');
      // 초기 로드 실패 시에도 스트림은 유지
    }
  }

  /// 로컬 AI 채팅방을 ChatRoom 형태로 변환
  Future<List<ChatRoom>> _loadLocalAIChatRooms() async {
    try {
      debugPrint('[ChatProvider] 로컬 AI 채팅방 로딩 시작');
      
      // 전체 마이그레이션 실행 (사용자별 데이터 분리 포함)
      await AIChatLocalService.runMigrations();
      
      // 로컬 AI 채팅방 목록 가져오기
      final localRooms = await AIChatLocalService.getRooms();
      debugPrint('[ChatProvider] 로컬 AI 채팅방 개수: ${localRooms.length}');
      
      final chatRooms = <ChatRoom>[];
      
      for (final localRoom in localRooms) {
        if (!localRoom.id.startsWith('ai-')) continue;
        final messages = await AIChatLocalService.getMessages(localRoom.id);
        // 사용자가 한 번이라도 메시지를 보낸 방만 history에 포함
        final hasUserMessage = messages.any((m) => m.role == 'user');
        if (!hasUserMessage) continue;
        
        // 마지막 메시지 정보
        final lastMessage = messages.isNotEmpty ? messages.last : null;
        
        // ChatRoom 형태로 변환
        final chatRoom = ChatRoom(
          id: localRoom.id,
          title: _getAIChatRoomTitle(localRoom.topic),
          type: ChatRoomType.ai,
          participantIds: ['user'], // AI 채팅은 사용자만 참여
          lastMessage: lastMessage != null ? Message(
            id: 'local_${lastMessage.createdAt.millisecondsSinceEpoch}',
            chatRoomId: localRoom.id,
            senderId: lastMessage.role,
            senderName: lastMessage.role == 'user' ? '나' : 'AI',
            content: lastMessage.text,
            type: MessageType.text,
            timestamp: lastMessage.createdAt,
            isRead: true,
          ) : null,
          unreadCount: 0,
          topic: localRoom.topic,
          status: ChatRoomStatus.active,
          createdAt: localRoom.createdAt,
          updatedAt: localRoom.lastMessageAt ?? localRoom.createdAt,
        );
        
        chatRooms.add(chatRoom);
        debugPrint('[ChatProvider] AI 채팅방 추가: ${localRoom.id}');
      }
      
      // 최신 메시지 순으로 정렬
      chatRooms.sort((a, b) {
        final aTime = a.lastMessage?.timestamp ?? a.createdAt;
        final bTime = b.lastMessage?.timestamp ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      
      debugPrint('[ChatProvider] 변환된 AI 채팅방 개수: ${chatRooms.length}');
      return chatRooms;
    } catch (e) {
      debugPrint('[ChatProvider] 로컬 AI 채팅방 로딩 오류: $e');
      return [];
    }
  }

  /// AI 채팅방 제목 생성
  String _getAIChatRoomTitle(String topic) {
    const topicTitles = {
      'anxiety': '불안/스트레스',
      'confidence': '자신감/동기부여',
      'focus': '집중력/수행력',
      'teamwork': '팀워크/리더십',
      'injury': '부상/재활',
      'performance': '경기력 향상',
      'general': '일반 상담',
    };
    
    return 'AI 상담 - ${topicTitles[topic] ?? topic}';
  }

  /// AI 채팅 기록 실시간 업데이트 타이머 시작
  void _startAIChatUpdateTimer() {
    _aiChatUpdateTimer?.cancel();
    _aiChatUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && state.isInitialized) {
        _updateAIChatRooms();
      }
    });
  }

  /// AI 채팅방 목록 업데이트
  Future<void> _updateAIChatRooms() async {
    try {
      final localAiRooms = await _loadLocalAIChatRooms();
      
      // 현재 상태와 비교하여 변경사항이 있는지 확인
      if (!_areAIChatRoomsEqual(state.aiChatRooms, localAiRooms)) {
        debugPrint('[ChatProvider] AI 채팅방 목록 업데이트: ${localAiRooms.length}개');
        state = state.copyWith(aiChatRooms: localAiRooms);
      }
    } catch (e) {
      debugPrint('[ChatProvider] AI 채팅방 업데이트 오류: $e');
    }
  }

  /// AI 채팅방 목록이 동일한지 비교
  bool _areAIChatRoomsEqual(List<ChatRoom> current, List<ChatRoom> newRooms) {
    if (current.length != newRooms.length) return false;
    
    for (int i = 0; i < current.length; i++) {
      final currentRoom = current[i];
      final newRoom = newRooms[i];
      
      if (currentRoom.id != newRoom.id ||
          currentRoom.lastMessage?.content != newRoom.lastMessage?.content ||
          currentRoom.updatedAt != newRoom.updatedAt) {
        return false;
      }
    }
    
    return true;
  }

  /// AI 채팅방 수동 새로고침 (외부에서 호출 가능)
  Future<void> refreshAIChatRooms() async {
    debugPrint('[ChatProvider] AI 채팅방 수동 새로고침');
    await _updateAIChatRooms();
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
              // 더 안전한 방식으로 분류
              final aiRooms = <ChatRoom>[];
              final counselorRooms = <ChatRoom>[];

              for (final room in chatRooms) {
                try {
                  if (room.type.value == 'ai') {
                    // enum의 value로 비교
                    aiRooms.add(room);
                  } else if (room.type.value == 'counselor') {
                    counselorRooms.add(room);
                  }
                } catch (e) {
                  debugPrint('채팅방 분류 오류: $e');
                  // 기본적으로 AI 채팅방으로 분류
                  aiRooms.add(room);
                }
              }

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

      // AI 채팅 기록을 로컬에서 불러오기
      final localAiRooms = await _loadLocalAIChatRooms();
      
      if (_chatService != null) {
        // Firebase에서 상담사 채팅방 목록 로드
        final chatRooms = await _chatService!.getChatRooms();

        // 상담사 채팅방만 분류
        final counselorRooms = <ChatRoom>[];

        for (final room in chatRooms) {
          try {
            if (room.type.value == 'counselor') {
              counselorRooms.add(room);
            }
          } catch (e) {
            debugPrint('채팅방 분류 오류: $e');
          }
        }

        state = state.copyWith(
          aiChatRooms: localAiRooms,
          counselorChatRooms: counselorRooms,
          isLoading: false,
          error: null,
        );
      } else {
        // 채팅 서비스가 없어도 로컬 AI 채팅은 표시
        state = state.copyWith(
          aiChatRooms: localAiRooms,
          counselorChatRooms: const [],
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
      // AI 채팅방인지 확인
      final isAIChatRoom = chatRoomId.startsWith('ai-');
      
      if (isAIChatRoom) {
        // AI 채팅방 삭제
        debugPrint('[ChatProvider] AI 채팅방 삭제: $chatRoomId');
        await AIChatLocalService.deleteRoom(chatRoomId);
        
        // 즉시 AI 채팅방 목록 업데이트
        await _updateAIChatRooms();
        return true;
      } else {
        // 상담사 채팅방 삭제
        if (_chatService != null) {
          final success = await _chatService!.deleteChatRoom(chatRoomId);
          if (success) {
            // Firebase 실시간 스트림이 자동으로 업데이트 처리
            return true;
          }
        }
        return false;
      }
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

  /// 채팅방 숨기기/표시하기
  Future<void> toggleChatRoomVisibility(String chatRoomId) async {
    try {
      if (_chatService != null) {
        final success = await _chatService!.toggleChatRoomVisibility(chatRoomId);
        if (success) {
          // 채팅방 목록 새로고침
          await refreshChatRooms();
        }
      }
    } catch (e) {
      debugPrint('채팅방 표시 상태 변경 실패: $e');
      state = state.copyWith(error: '채팅방 상태 변경에 실패했습니다.');
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
          senderId: 'current_user', // Firebase Auth에서 자동으로 실제 ID 사용
          type: MessageType.text,
        );

        // 메시지 전송 후 즉시 상태 업데이트 (Firebase 스트림이 처리)
        state = state.copyWith(isSending: false, error: null);
        
        // 짧은 지연 후 메시지 목록 강제 새로고침 (스트림 업데이트 누락 방지)
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (mounted) {
            try {
              // 스트림이 업데이트를 놓친 경우를 대비한 강제 새로고침
              debugPrint('📱 메시지 전송 후 강제 새로고침 실행');
              await refreshMessages();
            } catch (e) {
              debugPrint('메시지 강제 새로고침 실패: $e');
            }
          }
        });
        
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
          senderId: 'current_user', // Firebase Auth에서 자동으로 실제 ID 사용
        );

        state = state.copyWith(isSending: false);
        
        // 이미지 전송 후에도 강제 새로고침
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (mounted) {
            try {
              debugPrint('📸 이미지 전송 후 강제 새로고침 실행');
              await refreshMessages();
            } catch (e) {
              debugPrint('이미지 전송 후 새로고침 실패: $e');
            }
          }
        });
        
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
          senderId: 'current_user', // Firebase Auth에서 자동으로 실제 ID 사용
        );

        state = state.copyWith(isSending: false);
        
        // 파일 전송 후에도 강제 새로고침
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (mounted) {
            try {
              debugPrint('📁 파일 전송 후 강제 새로고침 실행');
              await refreshMessages();
            } catch (e) {
              debugPrint('파일 전송 후 새로고침 실패: $e');
            }
          }
        });
        
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
