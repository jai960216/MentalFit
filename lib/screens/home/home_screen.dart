import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../providers/auth_provider.dart';
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
    // 홈 화면에서는 채팅방 로딩하지 않음 - 채팅 목록 화면에서만 로딩
    debugPrint('홈 화면 초기화 완료');
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
                        color: AppColors.white.withValues(alpha: 0.8),
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

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        title: 'AI 상담',
        subtitle: '24시간 언제든지',
        icon: Icons.smart_toy,
        color: AppColors.primary,
        onTap: () => _handleAiCounselingTap(),
      ),
      QuickAction(
        title: '상담사 찾기',
        subtitle: '전문가와 연결',
        icon: Icons.person_search,
        color: AppColors.secondary,
        onTap: () => context.push(AppRoutes.counselorList),
      ),
      QuickAction(
        title: '채팅',
        subtitle: '대화 목록',
        icon: Icons.chat_bubble_outline,
        color: AppColors.accent,
        onTap: () => _handleChatListTap(),
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
              color: AppColors.grey400.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(action.icon, color: action.color, size: 24.sp),
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

  // === 액션 핸들러들 ===

  Future<void> _handleAiCounselingTap() async {
    try {
      // AI 상담 페이지로 바로 이동
      context.push(AppRoutes.aiCounseling);
    } catch (e) {
      _showErrorSnackBar('AI 상담을 시작할 수 없습니다.');
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

  // === 헬퍼 메서드들 ===

  Future<void> _handleRefresh() async {
    try {
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      _showErrorSnackBar('새로고침에 실패했습니다.');
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
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
