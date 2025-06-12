import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/network/error_handler.dart';

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
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
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

    // 순차적 애니메이션 시작
    _greetingController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardController.forward();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // 필요한 초기 데이터 로딩
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      // 에러가 발생해도 앱 사용에 지장이 없도록 처리
      debugPrint('초기 데이터 로딩 오류: $e');
    }
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // === 액션 핸들러들 ===
  Future<void> _handleRefresh() async {
    try {
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _handleAiCounselingTap() {
    context.push(AppRoutes.aiCounseling);
  }

  void _handleCounselorSearchTap() {
    context.push(AppRoutes.counselorList);
  }

  void _handleChatListTap() {
    context.push(AppRoutes.chatList);
  }

  void _handleSelfCheckTap() {
    context.push(AppRoutes.selfCheckList);
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '좋은 아침이에요! 오늘도 힘내세요 ✨';
    } else if (hour < 18) {
      return '활기찬 오후 보내고 계신가요? 💪';
    } else {
      return '수고 많으셨어요. 편안한 저녁 되세요 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // === 헤더 영역 ===
            SliverToBoxAdapter(child: _buildHeader(user)),

            // === 메인 컨텐츠 ===
            SliverToBoxAdapter(
              child: Padding(
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
                      child: _buildQuickActions(),
                    ),

                    SizedBox(height: 24.h),

                    // === 오늘의 멘탈 체크 ===
                    FadeTransition(
                      opacity: _cardAnimation,
                      child: _buildTodayMentalCheck(),
                    ),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
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
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getGreetingMessage(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // === 알림 버튼 ===
              IconButton(
                onPressed: () => context.push(AppRoutes.notifications),
                icon: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.white,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(User? user) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘도 화이팅! 💪',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '건강한 마음으로 하루를 시작해보세요',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.wb_sunny, color: AppColors.primary, size: 32.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        title: 'AI 상담',
        subtitle: '',
        icon: Icons.psychology,
        color: AppColors.primary,
        onTap: _handleAiCounselingTap,
      ),
      QuickAction(
        title: '상담사 찾기',
        subtitle: '',
        icon: Icons.person_search,
        color: AppColors.secondary,
        onTap: _handleCounselorSearchTap,
      ),
      QuickAction(
        title: '채팅',
        subtitle: '',
        icon: Icons.chat_bubble,
        color: AppColors.accent,
        onTap: _handleChatListTap,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(14.w), // 패딩 더 줄임
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
          Text(
            '빠른 시작',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h), // 간격 더 줄임
          Row(
            children:
                actions
                    .map(
                      (action) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                actions.indexOf(action) == actions.length - 1
                                    ? 0
                                    : 8.w, // 간격 더 줄임
                          ),
                          child: _buildQuickActionCard(action),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    // 아이콘별 크기 조정
    double getIconSize(IconData icon) {
      switch (icon) {
        case Icons.psychology:
          return 18.sp; // 기본 크기
        case Icons.person_search:
          return 18.sp; // 기본 크기
        case Icons.chat_bubble:
          return 16.sp; // 채팅 아이콘은 살짝 작게
        default:
          return 18.sp;
      }
    }

    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        height: 82.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: action.color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: getIconSize(action.icon), // 개별 크기 적용
              ),
            ),

            SizedBox(height: 6.h),

            // 제목만 표시
            Text(
              action.title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 멘탈 체크',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _handleSelfCheckTap,
                child: Text(
                  '전체보기',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            // 전체 박스를 터치 가능하게 변경
            onTap: _handleSelfCheckTap, // 자가진단 페이지로 이동
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '간단한 자가진단 해보기',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '현재 나의 멘탈점수를 확인하세요',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === 데이터 모델 ===
class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
