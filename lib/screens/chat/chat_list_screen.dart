import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/services/chat_service.dart';
import '../../shared/models/chat_room_model.dart';
import '../../shared/models/message_model.dart';
import '../../shared/models/user_model.dart'; // User 모델 import 추가
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ChatService _chatService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _loadChatRooms();
  }

  Future<void> _initializeServices() async {
    _chatService = await ChatService.getInstance();
  }

  Future<void> _loadChatRooms() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(chatRoomsProvider.notifier).loadChatRooms();
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomsState = ref.watch(chatRoomsProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'new_ai_chat',
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy, size: 16),
                        SizedBox(width: 8),
                        Text('새 AI 상담'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'find_counselor',
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 16),
                        SizedBox(width: 8),
                        Text('상담사 찾기'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble, size: 16),
                  const SizedBox(width: 4),
                  Text('전체', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.smart_toy, size: 16),
                  const SizedBox(width: 4),
                  Text('AI 상담', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text('전문가', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildAllChatsTab(chatRoomsState, user),
                  _buildAIChatsTab(chatRoomsState, user),
                  _buildCounselorChatsTab(chatRoomsState, user),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  // === 탭 컨텐츠들 ===

  Widget _buildAllChatsTab(ChatRoomsState state, User? user) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, () => _loadChatRooms());
    }

    if (state.chatRooms.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: state.chatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = state.chatRooms[index];
          return _buildChatRoomCard(chatRoom, user);
        },
      ),
    );
  }

  Widget _buildAIChatsTab(ChatRoomsState state, User? user) {
    final aiChatRooms = ref.watch(aiChatRoomsProvider);

    if (aiChatRooms.isEmpty) {
      return _buildEmptyAIState();
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: aiChatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = aiChatRooms[index];
          return _buildChatRoomCard(chatRoom, user);
        },
      ),
    );
  }

  Widget _buildCounselorChatsTab(ChatRoomsState state, User? user) {
    final counselorChatRooms =
        state.chatRooms
            .where((room) => room.type == ChatRoomType.counselor)
            .toList();

    if (counselorChatRooms.isEmpty) {
      return _buildEmptyCounselorState();
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: counselorChatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = counselorChatRooms[index];
          return _buildChatRoomCard(chatRoom, user);
        },
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildChatRoomCard(ChatRoom chatRoom, User? user) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _enterChatRoom(chatRoom),
          onLongPress: () => _showChatRoomOptions(chatRoom),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey400.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // === 프로필 이미지/아이콘 ===
                _buildChatRoomAvatar(chatRoom),

                SizedBox(width: 12.w),

                // === 채팅방 정보 ===
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatRoom.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chatRoom.unreadCount > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                chatRoom.unreadCount > 99
                                    ? '99+'
                                    : chatRoom.unreadCount.toString(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // === 마지막 메시지 ===
                      if (chatRoom.lastMessage != null)
                        Text(
                          _formatLastMessage(chatRoom.lastMessage!, user?.id),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      SizedBox(height: 8.h),

                      // === 하단 정보 ===
                      Row(
                        children: [
                          if (chatRoom.topic != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getChatRoomTypeColor(
                                  chatRoom.type,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                chatRoom.topic!,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: _getChatRoomTypeColor(chatRoom.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],

                          Expanded(
                            child: Text(
                              _formatTime(chatRoom.updatedAt),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                          // === 상태 아이콘 ===
                          if (chatRoom.status == ChatRoomStatus.active)
                            Icon(
                              Icons.circle,
                              size: 8.sp,
                              color: AppColors.success,
                            )
                          else
                            Icon(
                              Icons.archive,
                              size: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomAvatar(ChatRoom chatRoom) {
    if (chatRoom.isAIChat) {
      return Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Icon(Icons.smart_toy, color: AppColors.primary, size: 24.sp),
      );
    } else if (chatRoom.type == ChatRoomType.counselor) {
      return CircleAvatar(
        radius: 24.r,
        backgroundColor: AppColors.secondary.withOpacity(0.1),
        backgroundImage:
            chatRoom.counselorImageUrl != null
                ? NetworkImage(chatRoom.counselorImageUrl!)
                : null,
        child:
            chatRoom.counselorImageUrl == null
                ? Icon(Icons.person, color: AppColors.secondary, size: 24.sp)
                : null,
      );
    } else {
      return Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Icon(Icons.group, color: AppColors.accent, size: 24.sp),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 24.h),
            Text(
              '아직 대화가 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'AI 상담이나 전문 상담사와\n대화를 시작해보세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: 'AI 상담 시작하기',
              onPressed: () => context.push(AppRoutes.aiCounseling),
              icon: Icons.smart_toy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAIState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy,
              size: 64.sp,
              color: AppColors.primary.withOpacity(0.5),
            ),
            SizedBox(height: 24.h),
            Text(
              'AI 상담을 시작해보세요',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '24시간 언제든지 이용 가능한\nAI 상담사와 대화해보세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: '새 AI 상담 시작',
              onPressed: _createNewAIChat,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCounselorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64.sp,
              color: AppColors.secondary.withOpacity(0.5),
            ),
            SizedBox(height: 24.h),
            Text(
              '전문 상담사를 찾아보세요',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '다양한 분야의 전문 상담사와\n1:1 맞춤 상담을 받아보세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: '상담사 찾기',
              onPressed: () => context.push(AppRoutes.counselorList),
              icon: Icons.search,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              '채팅 목록을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: '다시 시도',
              onPressed: onRetry,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  // === 액션 핸들러들 ===

  void _enterChatRoom(ChatRoom chatRoom) {
    // 읽음 처리
    ref.read(chatRoomsProvider.notifier).markAsRead(chatRoom.id);

    // 채팅방으로 이동
    context.push('${AppRoutes.chatRoom}/${chatRoom.id}');
  }

  void _showChatRoomOptions(ChatRoom chatRoom) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_off),
                  title: const Text('알림 끄기'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('알림 설정이 변경되었습니다')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('보관하기'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('채팅방이 보관되었습니다')),
                    );
                  },
                ),
                if (chatRoom.isAIChat)
                  ListTile(
                    leading: const Icon(Icons.delete, color: AppColors.error),
                    title: const Text(
                      '삭제하기',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteChatRoom(chatRoom);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _confirmDeleteChatRoom(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('채팅방 삭제'),
            content: Text(
              '${chatRoom.title}을(를) 삭제하시겠습니까?\n삭제된 채팅방은 복구할 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(chatRoomsProvider.notifier)
                        .deleteChatRoom(chatRoom.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('채팅방이 삭제되었습니다')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      GlobalErrorHandler.showErrorSnackBar(context, e);
                    }
                  }
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

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '새로운 대화 시작',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.smart_toy, color: AppColors.primary),
                  ),
                  title: const Text('AI 상담'),
                  subtitle: const Text('24시간 언제든지 이용 가능'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewAIChat();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.people, color: AppColors.secondary),
                  ),
                  title: const Text('전문 상담사'),
                  subtitle: const Text('예약을 통한 전문 상담'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.counselorList);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _createNewAIChat() async {
    try {
      final chatRoom = await ref
          .read(chatRoomsProvider.notifier)
          .createAIChatRoom(topic: '전체');
      if (mounted) {
        context.push('${AppRoutes.chatRoom}/${chatRoom.id}');
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_ai_chat':
        _createNewAIChat();
        break;
      case 'find_counselor':
        context.push(AppRoutes.counselorList);
        break;
      case 'settings':
        context.push(AppRoutes.settings);
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('채팅 검색'),
            content: const TextField(
              decoration: InputDecoration(
                hintText: '채팅방 이름이나 메시지 내용 검색',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('검색 기능 준비중입니다')));
                },
                child: const Text('검색'),
              ),
            ],
          ),
    );
  }

  // === 헬퍼 메서드들 ===

  String _formatLastMessage(Message message, String? currentUserId) {
    String prefix = '';

    if (message.senderId == currentUserId) {
      prefix = '나: ';
    } else if (message.senderName != null) {
      prefix = '${message.senderName}: ';
    } else if (message.isFromAI) {
      prefix = 'AI: ';
    }

    return '$prefix${message.content}';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '어제';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return '${dateTime.month}/${dateTime.day}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Color _getChatRoomTypeColor(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.ai:
        return AppColors.primary;
      case ChatRoomType.counselor:
        return AppColors.secondary;
      case ChatRoomType.group:
        return AppColors.accent;
    }
  }
}
