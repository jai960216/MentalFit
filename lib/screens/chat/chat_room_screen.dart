import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/chat_room_model.dart';
import '../../shared/models/message_model.dart';
import '../../shared/services/chat_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatRoomId;

  const ChatRoomScreen({super.key, required this.chatRoomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with TickerProviderStateMixin {
  // === 컨트롤러들 ===
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  late AnimationController _typingAnimationController;

  // === 상태 변수들 ===
  ChatRoom? _chatRoom;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _error;

  // === 서비스들 ===
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
  }

  void _initializeControllers() {
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  Future<void> _initializeServices() async {
    try {
      _chatService = await ChatService.getInstance();
      await _loadChatRoomData();
      await _loadMessages();
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '채팅방을 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  Future<void> _loadChatRoomData() async {
    try {
      _chatRoom = await _chatService.getChatRoom(widget.chatRoomId);
      if (_chatRoom == null) {
        throw Exception('채팅방을 찾을 수 없습니다.');
      }
    } catch (e) {
      throw Exception('채팅방 정보를 불러올 수 없습니다.');
    }
  }

  Future<void> _loadMessages() async {
    try {
      await ref
          .read(chatMessagesProvider(widget.chatRoomId).notifier)
          .loadMessages();
    } catch (e) {
      // 메시지 로딩 실패는 치명적이지 않음
      debugPrint('메시지 로딩 실패: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    if (!_isInitialized || _chatRoom == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // === 메시지 목록 ===
            Expanded(child: _buildMessagesList()),

            // === 메시지 입력 영역 ===
            _buildMessageInputArea(),
          ],
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: const LoadingWidget(message: '채팅방을 불러오는 중...'),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('오류'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
              SizedBox(height: 16.h),
              Text(
                _error ?? '채팅방을 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('뒤로 가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _chatRoom!.title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (_chatRoom!.type == ChatRoomType.ai)
            Text(
              'AI 상담',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            )
          else if (_chatRoom!.type == ChatRoomType.counselor)
            Text(
              '전문 상담사',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showChatOptions,
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return Consumer(
      builder: (context, ref, child) {
        final messagesState = ref.watch(
          chatMessagesProvider(widget.chatRoomId),
        );
        final currentUser = ref.watch(currentUserProvider);

        if (messagesState.isLoading && messagesState.messages.isEmpty) {
          return const LoadingWidget(message: '메시지를 불러오는 중...');
        }

        if (messagesState.error != null && messagesState.messages.isEmpty) {
          return _buildMessagesErrorState(messagesState.error!);
        }

        if (messagesState.messages.isEmpty) {
          return _buildEmptyMessagesState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.w),
          itemCount: messagesState.messages.length,
          itemBuilder: (context, index) {
            final message = messagesState.messages[index];
            final isCurrentUser = message.senderId == currentUser?.id;

            return _buildMessageBubble(message, isCurrentUser);
          },
        );
      },
    );
  }

  Widget _buildMessagesErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              '메시지를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _chatRoom!.isAIChat ? Icons.smart_toy : Icons.person,
              size: 64.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16.h),
            Text(
              _chatRoom!.isAIChat ? 'AI 상담사와 대화를 시작해보세요' : '상담사와 대화를 시작해보세요',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '첫 메시지를 보내보세요!',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            _buildSenderAvatar(message),
            SizedBox(width: 8.w),
          ],

          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey400.withValues(
                      alpha: 0.1,
                    ), // 수정: withOpacity → withValues
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser && message.senderName != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        message.senderName!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color:
                          isCurrentUser
                              ? AppColors.white
                              : AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    _formatMessageTime(
                      message.timestamp,
                    ), // 수정: createdAt → timestamp
                    style: TextStyle(
                      fontSize: 11.sp,
                      color:
                          isCurrentUser
                              ? AppColors.white.withValues(
                                alpha: 0.8,
                              ) // 수정: withOpacity → withValues
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isCurrentUser) ...[
            SizedBox(width: 8.w),
            _buildSenderAvatar(message),
          ],
        ],
      ),
    );
  }

  Widget _buildSenderAvatar(Message message) {
    if (message.isFromAI) {
      return Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(
            alpha: 0.1,
          ), // 수정: withOpacity → withValues
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.smart_toy, size: 18.sp, color: AppColors.primary),
      );
    } else {
      return CircleAvatar(
        radius: 16.r,
        backgroundColor: AppColors.grey300,
        child: Icon(Icons.person, size: 18.sp, color: AppColors.white),
      );
    }
  }

  Widget _buildMessageInputArea() {
    return Consumer(
      builder: (context, ref, child) {
        final messagesState = ref.watch(
          chatMessagesProvider(widget.chatRoomId),
        );
        final currentUser = ref.watch(
          currentUserProvider,
        ); // 수정: currentUserProvider → userProvider

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.grey400.withValues(
                  alpha: 0.1,
                ), // 수정: withOpacity → withValues
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    maxLines: null,
                    enabled: !messagesState.isSending,
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: IconButton(
                  icon:
                      messagesState.isSending
                          ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                          : Icon(
                            Icons.send,
                            color: AppColors.white,
                            size: 20.sp,
                          ),
                  onPressed: messagesState.isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // === 액션 핸들러들 ===

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final currentUser = ref.read(
      currentUserProvider,
    ); // 수정: currentUserProvider → userProvider
    if (currentUser == null) {
      _showErrorSnackBar('로그인이 필요합니다.');
      return;
    }

    // 텍스트 필드 즉시 클리어
    _messageController.clear();

    try {
      await ref
          .read(chatMessagesProvider(widget.chatRoomId).notifier)
          .sendMessage(content: content, senderId: currentUser.id);

      // 메시지 전송 후 스크롤을 맨 아래로
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('메시지 전송에 실패했습니다.');
      // 실패 시 텍스트 복원
      _messageController.text = content;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('채팅방 정보'),
                  onTap: () {
                    Navigator.pop(context);
                    _showChatRoomInfo();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('대화 내용 지우기'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmClearMessages();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.exit_to_app,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    '채팅방 나가기',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLeaveChatRoom();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showChatRoomInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('채팅방 정보'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('제목: ${_chatRoom!.title}'),
                const SizedBox(height: 8),
                Text('유형: ${_getChatRoomTypeText(_chatRoom!.type)}'),
                const SizedBox(height: 8),
                Text('생성일: ${_formatDate(_chatRoom!.createdAt)}'),
                if (_chatRoom!.topic != null) ...[
                  const SizedBox(height: 8),
                  Text('주제: ${_chatRoom!.topic}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _confirmClearMessages() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('대화 내용 지우기'),
            content: const Text('모든 대화 내용이 삭제됩니다. 계속하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearMessages();
                },
                child: const Text(
                  '삭제',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmLeaveChatRoom() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('채팅방 나가기'),
            content: const Text('정말로 이 채팅방을 나가시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text(
                  '나가기',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  void _clearMessages() {
    ref.read(chatMessagesProvider(widget.chatRoomId).notifier).clearMessages();
    _showSuccessSnackBar('대화 내용이 삭제되었습니다.');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    }
  }

  // === 헬퍼 메서드들 ===

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String _getChatRoomTypeText(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.ai:
        return 'AI 상담';
      case ChatRoomType.counselor:
        return '전문 상담사';
      case ChatRoomType.group:
        return '그룹 상담';
    }
  }
}
