import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  Future<void> _loadUserData() async {
    try {
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutDialog();
    if (!confirmed) return;

    setState(() => _isLoggingOut = true);

    try {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        // 로그아웃 성공 시 로그인 화면으로 이동
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<bool> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('로그아웃'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isLoading || user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '마이페이지', showBackButton: false),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // === 프로필 헤더 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildProfileHeader(user),
              ),

              SizedBox(height: 24.h),

              // === 계정 관리 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildAccountSection(),
              ),

              SizedBox(height: 20.h),

              // === 서비스 이용 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildServiceSection(),
              ),

              SizedBox(height: 20.h),

              // === 고객 지원 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildSupportSection(),
              ),

              SizedBox(height: 32.h),

              // === 로그아웃 버튼 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildLogoutButton(),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 이미지
          Stack(
            children: [
              CircleAvatar(
                radius: 50.r,
                backgroundColor: AppColors.grey200,
                backgroundImage:
                    user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                child:
                    user.profileImageUrl == null
                        ? Icon(
                          Icons.person,
                          size: 50.sp,
                          color: AppColors.textSecondary,
                        )
                        : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfile),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16.sp,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 사용자 이름
          Text(
            user.name ?? '이름 없음',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 4.h),

          // 사용자 유형
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              user.userType.displayName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // 이메일
          Text(
            user.email,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),

          if (user.sport?.isNotEmpty == true) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text(
                  user.sport!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: '계정 관리',
      items: [
        _ProfileMenuItem(
          icon: Icons.person_outline,
          title: '프로필 수정',
          subtitle: '개인정보 및 프로필 변경',
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        _ProfileMenuItem(
          icon: Icons.settings_outlined,
          title: '설정',
          subtitle: '알림, 개인정보 설정',
          onTap: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    return _buildSection(
      title: '서비스 이용',
      items: [
        _ProfileMenuItem(
          icon: Icons.calendar_today_outlined,
          title: '내 예약',
          subtitle: '예약 내역 확인 및 관리',
          onTap: () => context.push(AppRoutes.bookingList),
        ),
        _ProfileMenuItem(
          icon: Icons.assignment_outlined,
          title: '상담 기록',
          subtitle: '지난 상담 내역 보기',
          onTap: () => context.push(AppRoutes.recordsList),
        ),
        _ProfileMenuItem(
          icon: Icons.psychology_outlined,
          title: '자가진단',
          subtitle: '심리 상태 자가진단',
          onTap: () => context.push(AppRoutes.selfCheckList),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: '고객 지원',
      items: [
        _ProfileMenuItem(
          icon: Icons.help_outline,
          title: '도움말',
          subtitle: '자주 묻는 질문',
          onTap: () => context.push(AppRoutes.help), // ← 수정: TODO 제거, 실제 라우트 연결
        ),
        _ProfileMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: '개인정보처리방침',
          subtitle: '개인정보 보호 정책',
          onTap:
              () => context.push(AppRoutes.privacy), // ← 수정: TODO 제거, 실제 라우트 연결
        ),
        _ProfileMenuItem(
          icon: Icons.description_outlined,
          title: '이용약관',
          subtitle: '서비스 이용약관',
          onTap:
              () => context.push(AppRoutes.terms), // ← 수정: TODO 제거, 실제 라우트 연결
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<_ProfileMenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 8.w),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...items.map((item) => _buildMenuItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_ProfileMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  item.icon,
                  size: 20.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return CustomButton(
      text: '로그아웃',
      onPressed: _isLoggingOut ? null : _handleLogout,
      isLoading: _isLoggingOut,
      type: ButtonType.outline,
      icon: Icons.logout,
    );
  }
}

// === 프로필 메뉴 아이템 모델 ===
class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
