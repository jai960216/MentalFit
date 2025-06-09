import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../shared/models/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _greetingController;
  late AnimationController _cardController;
  late Animation<double> _greetingAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
  }

  void _setupAnimations() {
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _greetingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _greetingController, curve: Curves.easeOut),
    );

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _greetingController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  Future<void> _loadInitialData() async {
    // 채팅방 목록 로드
    ref.read(chatRoomsProvider.notifier).loadChatRooms();
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final chatRoomsState = ref.watch(chatRoomsProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // === 헤더 영역 ===
                _buildHeader(user),

                // === 메인 컨텐츠 ===
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === 인사말 및 날씨 ===
                      FadeTransition(
                        opacity: _greetingAnimation,
                        child: _buildGreetingSection(user),
                      ),

                      SizedBox(height: 24.h),

                      // === 빠른 액션 버튼들 ===
                      FadeTransition(
                        opacity: _cardAnimation,
                        child: _buildQuickActions(unreadCount),
                      ),

                      SizedBox(height: 24.h),

                      // === 오늘의 멘탈 체크 ===
                      FadeTransition(
                        opacity: _cardAnimation,
                        child: _buildTodayMentalCheck(),
                      ),

                      SizedBox(height: 24.h),

                      // === 최근 활동 ===
                      FadeTransition(
                        opacity: _cardAnimation,
                        child: _buildRecentActivity(chatRoomsState),
                      ),

                      SizedBox(height: 24.h),

                      // === 추천 컨텐츠 ===
                      FadeTransition(
                        opacity: _cardAnimation,
                        child: _buildRecommendedContent(),
                      ),

                      SizedBox(height: 32.h),
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

  // === UI 구성 요소들 ===

  Widget _buildHeader(User? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          child: Row(
            children: [
              // === 프로필 이미지 ===
              GestureDetector(
                onTap: () => context.push(AppRoutes.profile),
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColors.white.withOpacity(0.2),
                  backgroundImage:
                      user?.profileImageUrl != null
                          ? NetworkImage(user!.profileImageUrl!)
                          : null,
                  child:
                      user?.profileImageUrl == null
                          ? Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 24.sp,
                          )
                          : null,
                ),
              ),

              SizedBox(width: 16.w),

              // === 사용자 정보 ===
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '사용자',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user?.userType.displayName ?? '',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // === 알림 버튼 ===
              IconButton(
                onPressed: () {
                  // 알림 페이지로 이동
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('알림 기능 준비중입니다')));
                },
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: AppColors.white,
                      size: 24.sp,
                    ),
                    // 알림 뱃지 (예시)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(User? user) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = '좋은 아침이에요! ☀️';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = '좋은 오후예요! 😊';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = '좋은 저녁이에요! 🌙';
      greetingIcon = Icons.brightness_3;
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(greetingIcon, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '오늘도 ${user?.sport ?? '운동'}을 통해 성장하는 하루 보내세요!',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(int unreadCount) {
    final actions = [
      QuickAction(
        title: 'AI 상담',
        subtitle: '24시간 언제든지',
        icon: Icons.smart_toy,
        color: AppColors.primary,
        onTap: () => context.push(AppRoutes.aiCounseling),
      ),
      QuickAction(
        title: '전문 상담사',
        subtitle: '예약 상담',
        icon: Icons.people,
        color: AppColors.secondary,
        onTap: () => context.push(AppRoutes.counselorList),
      ),
      QuickAction(
        title: '채팅',
        subtitle: unreadCount > 0 ? '$unreadCount개 미읽음' : '대화 목록',
        icon: Icons.chat_bubble_outline,
        color: AppColors.accent,
        badge: unreadCount,
        onTap: () => context.push(AppRoutes.chatList),
      ),
      QuickAction(
        title: '자가진단',
        subtitle: '심리 상태 체크',
        icon: Icons.psychology,
        color: AppColors.info,
        onTap: () => context.push(AppRoutes.selfCheckList),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 시작',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _buildQuickActionCard(actions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey400.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24.sp),
                ),
                if (action.badge != null && action.badge! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        action.badge.toString(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              action.title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              action.subtitle,
              style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMentalCheck() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppColors.error, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                '오늘의 멘탈 체크',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showMentalCheckDialog();
                },
                child: Text(
                  '체크하기',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // === 간단한 상태 표시 ===
          Row(
            children: [
              _buildMentalIndicator('기분', 7, AppColors.success),
              SizedBox(width: 16.w),
              _buildMentalIndicator('에너지', 5, AppColors.warning),
              SizedBox(width: 16.w),
              _buildMentalIndicator('집중력', 8, AppColors.success),
            ],
          ),

          SizedBox(height: 12.h),

          Text(
            '오늘 하루 컨디션이 좋아 보이네요! 💪',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalIndicator(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 4.h),
          LinearProgressIndicator(
            value: value / 10,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          SizedBox(height: 4.h),
          Text(
            '$value/10',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ChatRoomsState chatRoomsState) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.info, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                '최근 활동',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRoutes.recordsList),
                child: Text(
                  '전체보기',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (chatRoomsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (chatRoomsState.chatRooms.isEmpty)
            _buildEmptyState()
          else
            ...chatRoomsState.chatRooms
                .take(3)
                .map(
                  (chatRoom) => _buildActivityItem(
                    title: chatRoom.title,
                    subtitle: chatRoom.lastMessage?.content ?? '',
                    time: _formatTime(chatRoom.updatedAt),
                    icon: chatRoom.isAIChat ? Icons.smart_toy : Icons.person,
                    onTap:
                        () => context.push(
                          '${AppRoutes.chatRoom}/${chatRoom.id}',
                        ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 16.sp, color: AppColors.textSecondary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 40.sp,
            color: AppColors.grey400,
          ),
          SizedBox(height: 12.h),
          Text(
            '아직 상담 기록이 없습니다',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => context.push(AppRoutes.aiCounseling),
            child: Text(
              'AI 상담으로 시작해보세요',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedContent() {
    final recommendations = [
      RecommendedItem(
        title: '스트레스 관리법',
        subtitle: '경기 전 긴장감 해소하기',
        type: '기법',
        color: AppColors.error,
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('컨텐츠 준비중입니다')));
        },
      ),
      RecommendedItem(
        title: '집중력 향상',
        subtitle: '몰입도를 높이는 방법',
        type: '훈련',
        color: AppColors.info,
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('컨텐츠 준비중입니다')));
        },
      ),
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: AppColors.accent, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                '추천 컨텐츠',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          ...recommendations
              .map((item) => _buildRecommendedCard(item))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(RecommendedItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: item.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                item.type,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: item.color,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12.sp,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // === 헬퍼 메서드들 ===

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(chatRoomsProvider.notifier).loadChatRooms(),
      ref.read(authProvider.notifier).refreshUser(),
    ]);
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

  void _showMentalCheckDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('오늘의 멘탈 체크'),
            content: const Text('간단한 체크를 통해 오늘의 컨디션을 확인해보세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('나중에'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.selfCheckTest);
                },
                child: const Text('시작하기'),
              ),
            ],
          ),
    );
  }
}

// === 데이터 클래스들 ===

class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
}

class RecommendedItem {
  final String title;
  final String subtitle;
  final String type;
  final Color color;
  final VoidCallback onTap;

  const RecommendedItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.color,
    required this.onTap,
  });
}
