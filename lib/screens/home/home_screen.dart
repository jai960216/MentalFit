import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/utils/image_cache_manager.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/theme_aware_widgets.dart'; // 새로 만든 위젯들
import '../../shared/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/network/error_handler.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      debugPrint('초기 데이터 로딩 오류: $e');
    }
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

  void _handleChatTap() {
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
      return const ThemedScaffold(body: LoadingWidget());
    }

    return ThemedScaffold(
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
                    _buildGreetingSection(user),

                    SizedBox(height: 24.h),

                    // === 빠른 액션 버튼들 ===
                    _buildQuickActions(),

                    SizedBox(height: 24.h),

                    // === 오늘의 멘탈 체크 ===
                    _buildTodayMentalCheck(),

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
    return ThemedPrimaryContainer(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24.r),
        bottomRight: Radius.circular(24.r),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // === 프로필 이미지 ===
            GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: CircleAvatar(
                radius: 24.r,
                backgroundColor: Colors.white.withOpacity(0.2),
                child:
                    user?.profileImageUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: ImageCacheManager.getOptimizedImage(
                            imageUrl: user!.profileImageUrl!,
                            width: 48.w,
                            height: 48.w,
                            fit: BoxFit.cover,
                            placeholder: const ThemedIcon(
                              icon: Icons.person,
                              isOnPrimary: true,
                            ),
                          ),
                        )
                        : const ThemedIcon(
                          icon: Icons.person,
                          isOnPrimary: true,
                        ),
              ),
            ),

            SizedBox(width: 16.w),

            // === 사용자 정보 ===
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemedText(
                    text: user?.name ?? '사용자',
                    isOnPrimary: true,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ThemedText(
                    text: _getGreetingMessage(),
                    isOnPrimary: true,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),

            // === 알림 버튼 ===
            ThemedIcon(
              icon: Icons.notifications_outlined,
              isOnPrimary: true,
              size: 24.sp,
              onPressed: () => context.push(AppRoutes.notifications),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection(User? user) {
    return ThemedCard(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText(
                  text: '오늘도 화이팅!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                ThemedText(
                  text: _getGreetingMessage(),
                  isPrimary: false,
                  style: TextStyle(fontSize: 14.sp),
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
            child: Icon(Icons.wb_sunny, color: AppColors.primary, size: 24.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedText(
          text: '빠른 실행',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                title: 'AI 상담',
                subtitle: '24시간 상담',
                icon: Icons.psychology,
                color: AppColors.primary,
                onTap: _handleAiCounselingTap,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildQuickActionButton(
                title: '상담사 찾기',
                subtitle: '전문 상담',
                icon: Icons.person_search,
                color: AppColors.secondary,
                onTap: _handleCounselorSearchTap,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                title: '채팅',
                subtitle: '대화하기',
                icon: Icons.chat_bubble_outline,
                color: AppColors.info,
                onTap: _handleChatTap,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildQuickActionButton(
                title: '자가진단',
                subtitle: '마음 체크',
                icon: Icons.quiz_outlined,
                color: AppColors.success,
                onTap: _handleSelfCheckTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ThemedCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          ThemedText(
            text: title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.h),
          ThemedText(
            text: subtitle,
            isPrimary: false,
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMentalCheck() {
    return ThemedCard(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ThemedText(
                text: '오늘의 멘탈 체크',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
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
            onTap: _handleSelfCheckTap,
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
                      Icons.favorite_border,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ThemedText(
                          text: '오늘 기분은 어떠세요?',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        ThemedText(
                          text: '간단한 체크로 마음 상태를 확인해보세요',
                          isPrimary: false,
                          style: TextStyle(fontSize: 12.sp),
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
