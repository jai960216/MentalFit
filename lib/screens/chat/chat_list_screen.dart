import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/chat_list_widgets.dart';
import '../../shared/widgets/chat_error_widgets.dart';
import '../../shared/models/chat_room_model.dart';
import '../../shared/models/user_model.dart';
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
  bool _isInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_isInitializing || _isInitialized) return;

    setState(() => _isInitializing = true);

    try {
      await ref.read(chatRoomsProvider.notifier).initializeIfNeeded();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = true);
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _refresh() async {
    try {
      await ref.read(chatRoomsProvider.notifier).refresh();
    } catch (e) {
      if (mounted) GlobalErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomsProvider);
    final user = ref.watch(userProvider);

    if (_isInitializing) {
      return ChatListWidgets.buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(state, user, 'all'),
          _buildTab(state, user, 'ai'),
          _buildTab(state, user, 'counselor'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('채팅'),
      backgroundColor: AppColors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed:
              () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('검색 기능은 준비 중입니다'))),
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
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 16),
                      SizedBox(width: 8),
                      Text('새로고침'),
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
          Tab(child: Text('전체', style: TextStyle(fontSize: 14.sp))),
          Tab(child: Text('AI 상담', style: TextStyle(fontSize: 14.sp))),
          Tab(child: Text('전문가', style: TextStyle(fontSize: 14.sp))),
        ],
      ),
    );
  }

  Widget _buildTab(ChatRoomsState state, User? user, String tabType) {
    // 1. 초기화 체크
    if (!state.isInitialized) {
      return ChatListWidgets.buildLoading('채팅방을 불러오는 중...');
    }

    // 2. 채팅방 필터링
    List<ChatRoom> rooms;
    if (tabType == 'all') {
      rooms = state.chatRooms;
    } else if (tabType == 'ai') {
      rooms =
          state.chatRooms
              .where((room) => room.type == ChatRoomType.ai)
              .toList();
    } else {
      // counselor
      rooms =
          state.chatRooms
              .where((room) => room.type == ChatRoomType.counselor)
              .toList();
    }

    // 3. 로딩 중 + 빈 데이터
    if (state.isLoading && rooms.isEmpty && state.error == null) {
      return ChatListWidgets.buildLoading('채팅방을 불러오는 중...');
    }

    // 4. 에러 + 빈 데이터
    if (state.error != null && rooms.isEmpty) {
      ChatRoomType errorType =
          tabType == 'ai'
              ? ChatRoomType.ai
              : tabType == 'counselor'
              ? ChatRoomType.counselor
              : ChatRoomType.ai; // 기본값

      return ChatErrorWidgets.buildErrorState(
        errorType,
        state.error!,
        _refresh,
        _createNewAIChat,
        () => context.push(AppRoutes.counselorList),
      );
    }

    // 5. 빈 상태
    if (rooms.isEmpty) {
      ChatRoomType emptyType =
          tabType == 'ai'
              ? ChatRoomType.ai
              : tabType == 'counselor'
              ? ChatRoomType.counselor
              : ChatRoomType.ai; // 기본값

      return ChatErrorWidgets.buildEmptyState(
        emptyType,
        _createNewAIChat,
        () => context.push(AppRoutes.counselorList),
      );
    }

    // 6. 정상 데이터
    return Column(
      children: [
        if (state.error != null)
          ChatErrorWidgets.buildErrorBanner(state.error!, _refresh, ref),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: rooms.length,
              itemBuilder:
                  (context, index) => ChatListWidgets.buildChatRoomCard(
                    rooms[index],
                    user,
                    _enterChatRoom,
                    _showChatRoomOptions,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  void _enterChatRoom(ChatRoom chatRoom) {
    ref.read(chatRoomsProvider.notifier).markAsRead(chatRoom.id);
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
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text(
                    '채팅방 삭제',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteChatRoom(chatRoom);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _deleteChatRoom(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('채팅방 삭제'),
            content: Text('${chatRoom.title} 채팅방을 삭제하시겠습니까?'),
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
                    if (mounted)
                      GlobalErrorHandler.showErrorSnackBar(context, e);
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
                  ),
                ),
                SizedBox(height: 20.h),
                ListTile(
                  leading: Icon(Icons.smart_toy, color: AppColors.primary),
                  title: const Text('AI 상담'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewAIChat();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.people, color: AppColors.secondary),
                  title: const Text('전문가 상담'),
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
      final chatRoom =
          await ref.read(chatRoomsProvider.notifier).createAIChatRoom();
      if (chatRoom != null && mounted) {
        context.push('${AppRoutes.chatRoom}/${chatRoom.id}');
      }
    } catch (e) {
      if (mounted) GlobalErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'new_ai_chat':
        _createNewAIChat();
        break;
      case 'find_counselor':
        context.push(AppRoutes.counselorList);
        break;
      case 'refresh':
        _refresh();
        break;
    }
  }
}
