import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
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
  bool _isInitializing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeScreen();
  }

  /// 화면 초기화 (개선된 버전)
  Future<void> _initializeScreen() async {
    if (_isInitializing || _isInitialized) return;

    _isInitializing = true;

    try {
      // ChatRoomsNotifier 초기화 먼저 수행
      await ref.read(chatRoomsProvider.notifier).initializeIfNeeded();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isInitialized = true; // 실패해도 화면은 표시
        });
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  /// 채팅방 목록 새로고침
  Future<void> _refreshChatRooms() async {
    try {
      await ref.read(chatRoomsProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
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

    // 초기화 중일 때 로딩 화면 표시
    if (_isInitializing) {
      return _buildInitializingScreen();
    }

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
      body: TabBarView(
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

  // === 초기화 화면 ===
  Widget _buildInitializingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('채팅'), backgroundColor: AppColors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              '채팅 서비스를 초기화하는 중...',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // === 탭 컨텐츠들 (강화된 에러 처리) ===

  Widget _buildAllChatsTab(ChatRoomsState state, User? user) {
    // 1. 초기화되지 않은 경우
    if (!state.isInitialized) {
      return _buildLoadingState('채팅방 목록을 불러오는 중...');
    }

    // 2. 초기 로딩 중 (데이터가 없는 상태)
    if (state.isLoading && state.chatRooms.isEmpty) {
      return _buildLoadingState('채팅방 목록을 불러오는 중...');
    }

    // 3. 에러가 있으면서 데이터도 없는 경우 (치명적 에러)
    if (state.error != null && state.chatRooms.isEmpty) {
      return _buildCriticalErrorState(
        state.error!,
        () => _handleRetryWithFallback(),
      );
    }

    // 4. 데이터가 없는 경우 (정상적인 빈 상태)
    if (state.chatRooms.isEmpty) {
      return _buildEmptyState();
    }

    // 5. 데이터가 있는 경우 (에러가 있어도 데이터 우선 표시)
    return Column(
      children: [
        // 에러가 있는 경우 상단에 경고 배너 표시
        if (state.error != null) _buildErrorBanner(state.error!),

        // 메인 리스트
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshChatRooms,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: state.chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = state.chatRooms[index];
                return _buildChatRoomCard(chatRoom, user);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIChatsTab(ChatRoomsState state, User? user) {
    // 초기화되지 않은 경우
    if (!state.isInitialized) {
      return _buildLoadingState('AI 채팅방을 불러오는 중...');
    }

    final aiChatRooms =
        state.chatRooms
            .where((chatRoom) => chatRoom.type == ChatRoomType.ai)
            .toList();

    // 초기 로딩 중인 경우
    if (state.isLoading && aiChatRooms.isEmpty) {
      return _buildLoadingState('AI 채팅방을 불러오는 중...');
    }

    // 에러가 있으면서 AI 채팅방이 없는 경우
    if (state.error != null && aiChatRooms.isEmpty) {
      return _buildAIErrorState(state.error!);
    }

    // AI 채팅방이 없는 경우
    if (aiChatRooms.isEmpty) {
      return _buildEmptyAIState();
    }

    // AI 채팅방이 있는 경우
    return Column(
      children: [
        if (state.error != null) _buildErrorBanner(state.error!),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshChatRooms,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: aiChatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = aiChatRooms[index];
                return _buildChatRoomCard(chatRoom, user);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounselorChatsTab(ChatRoomsState state, User? user) {
    // 초기화되지 않은 경우
    if (!state.isInitialized) {
      return _buildLoadingState('상담사 채팅방을 불러오는 중...');
    }

    final counselorChatRooms =
        state.chatRooms
            .where((room) => room.type == ChatRoomType.counselor)
            .toList();

    // 초기 로딩 중인 경우
    if (state.isLoading && counselorChatRooms.isEmpty) {
      return _buildLoadingState('상담사 채팅방을 불러오는 중...');
    }

    // 에러가 있으면서 상담사 채팅방이 없는 경우
    if (state.error != null && counselorChatRooms.isEmpty) {
      return _buildCounselorErrorState(state.error!);
    }

    // 상담사 채팅방이 없는 경우
    if (counselorChatRooms.isEmpty) {
      return _buildEmptyCounselorState();
    }

    // 상담사 채팅방이 있는 경우
    return Column(
      children: [
        if (state.error != null) _buildErrorBanner(state.error!),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshChatRooms,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: counselorChatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = counselorChatRooms[index];
                return _buildChatRoomCard(chatRoom, user);
              },
            ),
          ),
        ),
      ],
    );
  }

  // === UI 상태별 위젯들 ===

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // === 에러 상태별 위젯들 (강화된 버전) ===

  /// 치명적 에러 상태 (데이터가 전혀 없는 경우)
  Widget _buildCriticalErrorState(String error, VoidCallback onRetry) {
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
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _getErrorMessage(error),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // 다양한 해결 방법 제공
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: '다시 시도',
                    onPressed: onRetry,
                    icon: Icons.refresh,
                    type: ButtonType.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomButton(
                    text: '새 채팅',
                    onPressed: _createNewAIChat,
                    icon: Icons.add,
                    type: ButtonType.secondary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),
            TextButton(
              onPressed: _clearErrorAndShowDefault,
              child: Text(
                '기본 채팅방 사용',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI 채팅 전용 에러 상태
  Widget _buildAIErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_outlined, size: 64.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              'AI 채팅방을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              '네트워크 문제로 기존 AI 채팅방을 불러올 수 없습니다.\n새로운 AI 채팅을 시작하시겠습니까?',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: '새 AI 채팅 시작',
              onPressed: _createNewAIChat,
              icon: Icons.smart_toy,
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _refreshChatRooms,
              child: Text(
                '다시 시도',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상담사 채팅 전용 에러 상태
  Widget _buildCounselorErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              '상담사 채팅방을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              '상담사와의 채팅 기록을 불러올 수 없습니다.\n새로운 상담사를 찾아보시겠습니까?',
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
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _refreshChatRooms,
              child: Text(
                '다시 시도',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 에러 배너 (데이터가 있지만 에러도 있는 경우)
  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 20.sp, color: AppColors.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '일부 채팅방을 불러오지 못했습니다',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatRoomsProvider.notifier).clearError();
              _refreshChatRooms();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              minimumSize: Size.zero,
            ),
            child: Text(
              '재시도',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(chatRoomsProvider.notifier).clearError(),
            icon: Icon(Icons.close, size: 16.sp, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
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
              '아직 진행 중인 채팅이 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'AI 상담이나 전문가와의 상담을 시작해보세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: 'AI 상담 시작',
              onPressed: () => _createNewAIChat(),
              icon: Icons.smart_toy,
            ),
            SizedBox(height: 12.h),
            CustomButton(
              text: '상담사 찾기',
              onPressed: () => context.push(AppRoutes.counselorList),
              icon: Icons.search,
              type: ButtonType.secondary,
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
              Icons.smart_toy_outlined,
              size: 64.sp,
              color: AppColors.grey400,
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
              '24시간 언제든지 AI와 대화할 수 있습니다',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: 'AI 상담 시작',
              onPressed: () => _createNewAIChat(),
              icon: Icons.smart_toy,
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
            Icon(Icons.people_outline, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 24.h),
            Text(
              '상담사와의 채팅이 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '전문 상담사를 찾아 1:1 상담을 시작해보세요',
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

  // === 채팅방 카드 ===
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
                  color: AppColors.grey400.withValues(alpha: 0.1),
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
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (chatRoom.lastMessage != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          chatRoom.lastMessage!.content,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatTime(chatRoom.lastMessage!.timestamp),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
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
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color:
            chatRoom.type == ChatRoomType.ai
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Icon(
        chatRoom.type == ChatRoomType.ai ? Icons.smart_toy : Icons.person,
        size: 24.sp,
        color:
            chatRoom.type == ChatRoomType.ai
                ? AppColors.primary
                : AppColors.secondary,
      ),
    );
  }

  // === 에러 처리 헬퍼 메서드들 ===

  /// 재시도 + 기본값 제공
  Future<void> _handleRetryWithFallback() async {
    try {
      // 먼저 에러 상태 클리어
      ref.read(chatRoomsProvider.notifier).clearError();

      // 재시도
      await _refreshChatRooms();

      // 여전히 데이터가 없으면 기본 채팅방 생성
      final state = ref.read(chatRoomsProvider);
      if (state.chatRooms.isEmpty && state.error == null) {
        await _createNewAIChat();
      }
    } catch (e) {
      // 재시도도 실패하면 기본 채팅방이라도 제공
      if (!mounted) return;
      await _createNewAIChat();
    }
  }

  /// 에러 클리어 후 기본 상태로 전환
  void _clearErrorAndShowDefault() {
    ref.read(chatRoomsProvider.notifier).clearError();
    _createNewAIChat();
  }

  /// 에러 메시지 가공
  String _getErrorMessage(String error) {
    // 특정 에러 패턴에 따라 사용자 친화적 메시지로 변환
    if (error.contains('네트워크') || error.contains('network')) {
      return '인터넷 연결을 확인해주세요';
    } else if (error.contains('서버') || error.contains('server')) {
      return '서버에 일시적인 문제가 있습니다\n잠시 후 다시 시도해주세요';
    } else if (error.contains('권한') || error.contains('authorization')) {
      return '로그인이 필요합니다\n다시 로그인해주세요';
    } else if (error.contains('초기화')) {
      return '채팅 서비스 초기화 중 문제가 발생했습니다';
    } else {
      return '일시적인 오류가 발생했습니다\n잠시 후 다시 시도해주세요';
    }
  }

  /// 에러 복구 시도
  Future<void> _attemptErrorRecovery() async {
    try {
      // 1단계: 에러 상태 클리어
      ref.read(chatRoomsProvider.notifier).clearError();

      // 2단계: 서비스 재초기화 시도
      await ref.read(chatRoomsProvider.notifier).initializeIfNeeded();

      // 3단계: 데이터 다시 로드
      await _refreshChatRooms();
    } catch (e) {
      // 복구 실패 시 기본 채팅방 제공
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('자동 복구에 실패했습니다. 기본 채팅방을 제공합니다.'),
            action: SnackBarAction(label: '확인', onPressed: () {}),
          ),
        );
        await _createNewAIChat();
      }
    }
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
                  leading: const Icon(Icons.volume_off),
                  title: const Text('알림 끄기'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 알림 설정 기능 구현
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text(
                    '채팅방 삭제',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(chatRoom);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmDialog(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('채팅방 삭제'),
            content: Text(
              '${chatRoom.title} 채팅방을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
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
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('채팅방이 삭제되었습니다')),
                    );
                  } catch (e) {
                    if (!mounted) return;
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
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),
                ListTile(
                  leading: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                  title: const Text('AI 상담'),
                  subtitle: const Text('24시간 언제든지 대화 가능'),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewAIChat();
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.people,
                      color: AppColors.secondary,
                      size: 20.sp,
                    ),
                  ),
                  title: const Text('전문가 상담'),
                  subtitle: const Text('전문 상담사와 1:1 대화'),
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
      if (chatRoom != null) {
        if (!mounted) return;
        context.push('${AppRoutes.chatRoom}/${chatRoom.id}');
      }
    } catch (e) {
      if (!mounted) return;
      GlobalErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _showSearchDialog() {
    // TODO: 검색 기능 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('검색 기능은 준비 중입니다')));
  }

  void _handleMenuAction(String value) {
    switch (value) {
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

  // === 헬퍼 메서드 ===

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
