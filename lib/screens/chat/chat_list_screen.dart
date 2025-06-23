import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/theme_aware_widgets.dart';
import '../../shared/widgets/loading_widget.dart';
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
  bool _isInitializing = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 위젯 생성 완료 후 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatService();
    });
  }

  Future<void> _initializeChatService() async {
    try {
      setState(() => _isInitializing = true);

      // 채팅 서비스 초기화
      await ref.read(chatListProvider.notifier).initializeIfNeeded();

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });
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
      await ref.read(chatListProvider.notifier).refreshChatRooms();
    } catch (e) {
      if (mounted) GlobalErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ThemedContainer(
            padding: EdgeInsets.all(20.w),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                SizedBox(height: 20.h),

                ThemedText(
                  text: '새 채팅 시작하기',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 20.h),

                // AI 상담 시작
                _buildChatOption(
                  icon: Icons.psychology,
                  title: 'AI 상담',
                  subtitle: '24시간 언제든 상담 가능',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.aiCounseling);
                  },
                ),

                SizedBox(height: 12.h),

                // 상담사 찾기
                _buildChatOption(
                  icon: Icons.person_search,
                  title: '상담사 찾기',
                  subtitle: '전문 상담사와 1:1 상담',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.counselorList);
                  },
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
    );
  }

  Widget _buildChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ThemedCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText(
                  text: title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                ThemedText(
                  text: subtitle,
                  isPrimary: false,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
          ),
          ThemedIcon(icon: Icons.arrow_forward_ios, size: 16.sp),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatListProvider);
    final user =
        ref
            .watch(authProvider)
            .user; // ✅ 수정: currentUserProvider → authProvider.user

    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    return ThemedScaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(state, user, 'ai'),
          _buildTab(state, user, 'counselor'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return ThemedScaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: context.surfaceColor,
      ),
      body: const LoadingWidget(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('채팅'),
      backgroundColor: context.surfaceColor,
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
        tabs: const [Tab(text: 'AI 상담'), Tab(text: '상담사')],
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

  Widget _buildTab(ChatListState state, User? user, String type) {
    final rooms = type == 'ai' ? state.aiChatRooms : state.counselorChatRooms;

    // 디버깅용 로그 추가
    debugPrint('$type 탭 - 채팅방 개수: ${rooms.length}');

    if (state.isLoading && rooms.isEmpty) {
      return const LoadingWidget();
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (rooms.isEmpty) {
      return _buildEmptyState(type);
    }

    // 최신 메시지 순으로 정렬
    rooms.sort((a, b) {
      final aTime = a.lastMessage?.timestamp ?? a.createdAt;
      final bTime = b.lastMessage?.timestamp ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(12.w),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildChatRoomCard(room, user);
        },
      ),
    );
  }

  Widget _buildChatRoomCard(dynamic chatRoom, User? user) {
    return ThemedCard(
      margin: EdgeInsets.only(bottom: 12.h),
      onTap: () => context.push('${AppRoutes.chatRoom}/${chatRoom.id}'),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // 채팅방 아이콘
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color:
                    chatRoom.type.toString().contains('ai')
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                chatRoom.type.toString().contains('ai')
                    ? Icons.psychology
                    : Icons.person,
                color:
                    chatRoom.type.toString().contains('ai')
                        ? AppColors.primary
                        : AppColors.secondary,
                size: 24.sp,
              ),
            ),

            SizedBox(width: 12.w),

            // 채팅방 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ThemedText(
                          text: chatRoom.title ?? '채팅방',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ThemedText(
                        text: _formatTime(chatRoom.updatedAt),
                        isPrimary: false,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  Row(
                    children: [
                      Expanded(
                        child: ThemedText(
                          text: chatRoom.lastMessage?.content ?? '대화를 시작해보세요',
                          isPrimary: false,
                          style: TextStyle(fontSize: 14.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chatRoom.unreadCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            chatRoom.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }

  Widget _buildEmptyState(String tabType) {
    final isAI = tabType == 'ai';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: (isAI ? AppColors.primary : AppColors.secondary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAI ? Icons.psychology : Icons.person_search,
                size: 40.sp,
                color: isAI ? AppColors.primary : AppColors.secondary,
              ),
            ),

            SizedBox(height: 24.h),

            ThemedText(
              text: isAI ? 'AI 상담 기록이 없습니다' : '상담사 채팅이 없습니다',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            ThemedText(
              text: isAI ? '24시간 언제든 AI 상담을 시작해보세요' : '전문 상담사와 1:1 상담을 시작해보세요',
              isPrimary: false,
              style: TextStyle(fontSize: 14.sp, height: 1.5),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32.h),

            ElevatedButton.icon(
              onPressed: () {
                if (isAI) {
                  context.push(AppRoutes.aiCounseling);
                } else {
                  context.push(AppRoutes.counselorList);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAI ? AppColors.primary : AppColors.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(
                isAI ? Icons.psychology : Icons.person_search,
                size: 20.sp,
              ),
              label: Text(
                isAI ? 'AI 상담 시작' : '상담사 찾기',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40.sp,
                color: AppColors.error,
              ),
            ),

            SizedBox(height: 24.h),

            ThemedText(
              text: '채팅 목록을 불러올 수 없습니다',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            ThemedText(
              text: error,
              isPrimary: false,
              style: TextStyle(fontSize: 14.sp, height: 1.5),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32.h),

            ElevatedButton.icon(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.refresh, size: 20.sp),
              label: Text(
                '다시 시도',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
