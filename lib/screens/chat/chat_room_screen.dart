import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/network/error_handler.dart';
import '../../shared/services/chat_service.dart';
import '../../shared/models/chat_room_model.dart';
import '../../shared/models/message_model.dart';
import '../../shared/models/user_model.dart'; // User 모델 import 추가
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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  late ChatService _chatService;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  ChatRoom? _chatRoom;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
    _setupMessageListener();
  }

  void _setupAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
    );

    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText && !_sendButtonController.isCompleted) {
        _sendButtonController.forward();
      } else if (!hasText && _sendButtonController.isCompleted) {
        _sendButtonController.reverse();
      }

      // 타이핑 상태 업데이트
      _updateTypingStatus(hasText);
    });
  }

  Future<void> _initializeChat() async {
    _chatService = await ChatService.getInstance();
    await _loadChatRoomInfo();
    await _loadMessages();
    setState(() => _isLoading = false);
  }

  Future<void> _loadChatRoomInfo() async {
    try {
      final chatRooms = await _chatService.getChatRooms();
      _chatRoom = chatRooms.firstWhere(
        (room) => room.id == widget.chatRoomId,
        orElse:
            () => ChatRoom(
              id: widget.chatRoomId,
              title: 'AI 상담',
              type: ChatRoomType.ai,
              participantIds: ['current_user', 'ai'],
              unreadCount: 0,
              status: ChatRoomStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      );
    } catch (e) {
      debugPrint('채팅방 정보 로드 오류: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      await ref
          .read(chatMessagesProvider(widget.chatRoomId).notifier)
          .loadMessages();
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _setupMessageListener() {
    // 새 메시지 스트림 구독
    _chatService.getNewMessageStream(widget.chatRoomId).listen((message) {
      _scrollToBottom();
    });
  }

  void _updateTypingStatus(bool isTyping) {
    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      final user = ref.read(userProvider);
      if (user != null) {
        _chatService.updateTypingStatus(widget.chatRoomId, user.id, isTyping);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider(widget.chatRoomId));
    final user = ref.watch(userProvider);

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // === 메시지 목록 ===
          Expanded(child: _buildMessagesList(messagesState, user)),

          // === 타이핑 상태 표시 ===
          _buildTypingIndicator(),

          // === 메시지 입력 영역 ===
          _buildMessageInput(),
        ],
      ),
    );
  }

  // === UI 구성 요소들 ===

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          // === 채팅방 아바타 ===
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: _getChatRoomColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              _getChatRoomIcon(),
              color: _getChatRoomColor(),
              size: 18.sp,
            ),
          ),

          SizedBox(width: 12.w),

          // === 채팅방 정보 ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chatRoom?.title ?? '채팅',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_chatRoom?.isAIChat == true)
                  Text(
                    '24시간 상담 가능',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  )
                else if (_chatRoom?.counselorName != null)
                  Text(
                    '전문 상담사',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_chatRoom?.isAIChat != true)
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('화상 통화 기능 준비중입니다')));
            },
          ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'clear_history',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 16),
                      SizedBox(width: 8),
                      Text('대화 내용 지우기'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, size: 16),
                      SizedBox(width: 8),
                      Text('신고하기'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 16),
                      SizedBox(width: 8),
                      Text('설정'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.white, title: const Text('채팅')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessagesList(ChatMessagesState state, User? user) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              '메시지를 불러올 수 없습니다',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      reverse: false,
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isMyMessage = message.isMine(user?.id ?? '');
        final showDateDivider = _shouldShowDateDivider(state.messages, index);

        return Column(
          children: [
            if (showDateDivider) _buildDateDivider(message.timestamp),
            _buildMessageBubble(message, isMyMessage),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            _buildMessageAvatar(message),
            SizedBox(width: 8.w),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMyMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage && message.senderName != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isMyMessage ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.r),
                      topRight: Radius.circular(18.r),
                      bottomLeft: Radius.circular(isMyMessage ? 18.r : 4.r),
                      bottomRight: Radius.circular(isMyMessage ? 4.r : 18.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grey400.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              isMyMessage
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatMessageTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color:
                                  isMyMessage
                                      ? AppColors.white.withOpacity(0.7)
                                      : AppColors.textSecondary,
                            ),
                          ),

                          if (isMyMessage) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12.sp,
                              color:
                                  message.isRead
                                      ? AppColors.accent
                                      : AppColors.white.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isMyMessage) ...[
            SizedBox(width: 8.w),
            _buildMessageAvatar(message),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageAvatar(Message message) {
    if (message.isFromAI) {
      return Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(Icons.smart_toy, color: AppColors.primary, size: 16.sp),
      );
    } else {
      return CircleAvatar(
        radius: 14.r,
        backgroundColor: AppColors.secondary.withOpacity(0.1),
        child: Icon(Icons.person, color: AppColors.secondary, size: 16.sp),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Map<String, bool>>(
      stream: _chatService.getTypingStream(widget.chatRoomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final typingUsers =
            snapshot.data!.entries
                .where(
                  (entry) =>
                      entry.value && entry.key != ref.read(userProvider)?.id,
                )
                .map((entry) => entry.key)
                .toList();

        if (typingUsers.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: AppColors.primary,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              _buildTypingAnimation(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingAnimation() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypingDot(0),
          SizedBox(width: 3.w),
          _buildTypingDot(1),
          SizedBox(width: 3.w),
          _buildTypingDot(2),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.4, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // === 첨부 버튼 ===
              GestureDetector(
                onTap: _showAttachmentOptions,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.add,
                    color: AppColors.textSecondary,
                    size: 20.sp,
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // === 메시지 입력 필드 ===
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // === 전송 버튼 ===
              ScaleTransition(
                scale: _sendButtonAnimation,
                child: GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: _isSending ? AppColors.grey400 : AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child:
                        _isSending
                            ? SizedBox(
                              width: 16.w,
                              height: 16.w,
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
                              size: 18.sp,
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === 액션 핸들러들 ===

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _messageFocusNode.unfocus();

    try {
      await ref
          .read(chatMessagesProvider(widget.chatRoomId).notifier)
          .sendMessage(content: text, senderId: user.id);

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
        // 전송 실패 시 텍스트 복원
        _messageController.text = text;
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '첨부하기',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.photo,
                      label: '사진',
                      color: AppColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사진 첨부 기능 준비중입니다')),
                        );
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.videocam,
                      label: '동영상',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('동영상 첨부 기능 준비중입니다')),
                        );
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.insert_drive_file,
                      label: '파일',
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('파일 첨부 기능 준비중입니다')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_history':
        _showClearHistoryDialog();
        break;
      case 'report':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('신고 기능 준비중입니다')));
        break;
      case 'settings':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('채팅 설정 기능 준비중입니다')));
        break;
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('대화 내용 지우기'),
            content: const Text('모든 대화 내용이 삭제되며 복구할 수 없습니다.\n계속하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(chatMessagesProvider(widget.chatRoomId).notifier)
                      .clearMessages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('대화 내용이 삭제되었습니다')),
                  );
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

  // === 헬퍼 메서드들 ===

  bool _shouldShowDateDivider(List<Message> messages, int index) {
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );

    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );

    return currentDate != previousDate;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '오늘';
    } else if (messageDate == yesterday) {
      return '어제';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getChatRoomColor() {
    if (_chatRoom?.isAIChat == true) {
      return AppColors.primary;
    } else if (_chatRoom?.type == ChatRoomType.counselor) {
      return AppColors.secondary;
    } else {
      return AppColors.accent;
    }
  }

  IconData _getChatRoomIcon() {
    if (_chatRoom?.isAIChat == true) {
      return Icons.smart_toy;
    } else if (_chatRoom?.type == ChatRoomType.counselor) {
      return Icons.person;
    } else {
      return Icons.group;
    }
  }
}
