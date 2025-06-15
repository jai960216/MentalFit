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
      // Provider 초기화 시도 (최대 3번)
      int attempts = 0;
      bool success = false;

      while (!success && attempts < 3) {
        try {
          attempts++;
          await ref.read(chatListProvider.notifier).initializeIfNeeded();
          success = true;
        } catch (e) {
          debugPrint('초기화 시도 $attempts 실패: $e');
          if (attempts < 3) {
            await Future.delayed(Duration(seconds: attempts)); // 점진적 지연
          }
        }
      }

      if (mounted) {
        setState(() => _isInitialized = success);

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('채팅 서비스 초기화에 실패했습니다. 새로고침을 시도해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = true); // 실패해도 UI는 표시
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _refresh() async {
    try {
      await ref.read(chatListProvider.notifier).refreshChatRooms();
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
    final state = ref.watch(chatListProvider);
    final user = ref.watch(currentUserProvider);

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
                const PopupMenuItem(value: 'refresh', child: Text('새로고침')),
                const PopupMenuItem(value: 'settings', child: Text('설정')),
              ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [Tab(text: '전체'), Tab(text: 'AI 상담'), Tab(text: '상담사')],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _refresh();
        break;
      case 'settings':
        context.push(AppRoutes.settings);
        break;
    }
  }

  Widget _buildTab(ChatListState state, User? user, String tabType) {
    // 탭에 따른 채팅방 필터링
    List<ChatRoom> rooms;
    switch (tabType) {
      case 'ai':
        rooms =
            state.chatRooms
                .where((room) => room.type == ChatRoomType.ai)
                .toList();
        break;
      case 'counselor':
        rooms =
            state.chatRooms
                .where((room) => room.type == ChatRoomType.counselor)
                .toList();
        break;
      default:
        rooms = state.chatRooms;
    }

    // 1. 초기화되지 않은 상태
    if (!state.isInitialized) {
      return ChatListWidgets.buildLoading('채팅 서비스를 초기화하는 중...');
    }

    // 2. 로딩 상태
    if (state.isLoading && rooms.isEmpty) {
      return ChatListWidgets.buildLoading('채팅방을 불러오는 중...');
    }

    // 3. 에러 + 빈 데이터
    if (state.error != null && rooms.isEmpty) {
      ChatRoomType errorType =
          tabType == 'ai'
              ? ChatRoomType.ai
              : tabType == 'counselor'
              ? ChatRoomType.counselor
              : ChatRoomType.ai;

      return ChatErrorWidgets.buildErrorState(
        errorType,
        state.error!,
        _refresh,
        _createNewAIChat,
        () => context.push(AppRoutes.counselorList),
      );
    }

    // 4. 빈 상태
    if (rooms.isEmpty) {
      ChatRoomType emptyType =
          tabType == 'ai'
              ? ChatRoomType.ai
              : tabType == 'counselor'
              ? ChatRoomType.counselor
              : ChatRoomType.ai;

      return ChatErrorWidgets.buildEmptyState(
        emptyType,
        _createNewAIChat,
        () => context.push(AppRoutes.counselorList),
      );
    }

    // 5. 정상 데이터
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
    // 읽음 처리는 채팅방 진입 시 자동으로 처리됨
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
                  final success = await ref
                      .read(chatListProvider.notifier)
                      .deleteChatRoom(chatRoom.id);

                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('채팅방이 삭제되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('채팅방 삭제에 실패했습니다.')),
                      );
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
                ListTile(
                  leading: const Icon(
                    Icons.smart_toy,
                    color: AppColors.primary,
                  ),
                  title: const Text('AI 상담 시작'),
                  subtitle: const Text('AI와 즉시 대화를 시작합니다'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewAIChat();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: AppColors.secondary),
                  title: const Text('상담사 찾기'),
                  subtitle: const Text('전문 상담사와 상담을 예약합니다'),
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

  void _createNewAIChat() async {
    try {
      final chatRoomId =
          await ref.read(chatListProvider.notifier).createAIChatRoom();

      if (mounted && chatRoomId != null) {
        context.push('${AppRoutes.chatRoom}/$chatRoomId');
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }
}
