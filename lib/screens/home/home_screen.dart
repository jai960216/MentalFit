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
                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
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
                        color: AppColors.white.withValues(alpha: 0.9),
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
            color: AppColors.grey400.withValues(alpha: 0.1),
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
              color: AppColors.primary.withValues(alpha: 0.1),
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
        subtitle: '24시간 언제든지',
        icon: Icons.psychology,
        color: AppColors.primary,
        onTap: _handleAiCounselingTap,
      ),
      QuickAction(
        title: '상담사 찾기',
        subtitle: '전문가와 1:1',
        icon: Icons.person_search,
        color: AppColors.secondary,
        onTap: _handleCounselorSearchTap,
      ),
      QuickAction(
        title: '채팅',
        subtitle: '실시간 상담',
        icon: Icons.chat_bubble,
        color: AppColors.accent,
        onTap: _handleChatListTap,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withValues(alpha: 0.1),
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
          SizedBox(height: 16.h),
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
                                    : 8.w,
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
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: action.color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(action.icon, color: action.color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              action.title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              action.subtitle,
              style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
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
            color: AppColors.grey400.withValues(alpha: 0.1),
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
              // 🔥 핵심 수정: 올바른 라우트로 연결
              TextButton(
                onPressed: _handleMentalCheckTap,
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

  // === 액션 핸들러들 ===

  Future<void> _handleAiCounselingTap() async {
    try {
      // AI 상담 페이지로 바로 이동
      context.push(AppRoutes.aiCounseling);
    } catch (e) {
      _showErrorSnackBar('AI 상담을 시작할 수 없습니다.');
    }
  }

  Future<void> _handleCounselorSearchTap() async {
    try {
      // 상담사 검색 페이지로 이동
      context.push(AppRoutes.counselorList);
    } catch (e) {
      _showErrorSnackBar('상담사 목록을 불러올 수 없습니다.');
    }
  }

  Future<void> _handleChatListTap() async {
    try {
      // 채팅방 목록으로 이동
      context.push(AppRoutes.chatList);
    } catch (e) {
      _showErrorSnackBar('채팅 목록을 불러올 수 없습니다.');
    }
  }

  // 🔥 핵심 수정: 멘탈 체크 버튼 핸들러
  Future<void> _handleMentalCheckTap() async {
    try {
      // 자가진단 목록 페이지로 이동 (올바른 라우트 사용)
      context.push(AppRoutes.selfCheckList);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('자가진단을 시작할 수 없습니다.');
      }
    }
  }

  // === 헬퍼 메서드들 ===

  Future<void> _handleRefresh() async {
    try {
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      _showErrorSnackBar('새로고침에 실패했습니다.');
    }
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return '좋은 아침이에요! ☀️';
    } else if (hour < 18) {
      return '좋은 오후예요! 🌤️';
    } else {
      return '좋은 저녁이에요! 🌙';
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '확인',
            textColor: AppColors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}

// === 데이터 클래스들 ===

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
