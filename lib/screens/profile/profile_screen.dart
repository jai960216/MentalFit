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
import '../../shared/widgets/theme_aware_widgets.dart';
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

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutDialog();
    if (!confirmed) return;

    setState(() => _isLoggingOut = true);

    try {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('로그아웃'),
                content: const Text('정말 로그아웃하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  // === 회원탈퇴 처리 ===
  Future<void> _handleDeleteAccount() async {
    // 1단계: 삭제 경고 다이얼로그
    final shouldContinue = await _showDeleteWarningDialog();
    if (!shouldContinue) return;

    // 2단계: 비밀번호 입력 다이얼로그
    final password = await _showPasswordDialog();
    if (password == null || password.isEmpty) return;

    // 3단계: 최종 확인 다이얼로그
    final finalConfirm = await _showFinalConfirmDialog();
    if (!finalConfirm) return;

    // 4단계: 계정 삭제 실행
    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.deleteAccount(password);
      
      if (success && mounted) {
        // 삭제 성공 - 로그인 화면으로 이동
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 성공적으로 삭제되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        // 삭제 실패 - provider의 에러 메시지 확인
        final authState = ref.read(authProvider);
        final errorMessage = authState.error ?? '계정 삭제에 실패했습니다. 비밀번호를 확인해주세요.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5), // 긴 메시지를 위해 시간 연장
          ),
        );
        
        // 특정 에러의 경우 추가 안내
        if (errorMessage.contains('다시 로그인')) {
          // 다시 로그인이 필요한 경우 로그인 페이지로 이동
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go(AppRoutes.login);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계정 삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteWarningDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: AppColors.error, size: 24.sp),
                SizedBox(width: 8.w),
                const Text('회원탈퇴'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('회원탈퇴 시 다음 데이터가 영구 삭제됩니다:'),
                SizedBox(height: 12.h),
                _buildDeleteItem('• 프로필 정보'),
                _buildDeleteItem('• 상담 기록'),
                _buildDeleteItem('• 자가진단 결과'),
                _buildDeleteItem('• 예약 내역'),
                SizedBox(height: 12.h),
                Text(
                  '삭제된 데이터는 복구할 수 없습니다.',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('계속'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('비밀번호 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('회원탈퇴를 위해 현재 비밀번호를 입력해주세요.'),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showFinalConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_forever, color: AppColors.error, size: 24.sp),
                SizedBox(width: 8.w),
                const Text('최종 확인'),
              ],
            ),
            content: const Text(
              '정말로 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.error,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (authState.isLoading || user == null) {
      return const ThemedScaffold(body: LoadingWidget());
    }

    return ThemedScaffold(
      appBar: const CustomAppBar(title: '프로필'),
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

              SizedBox(height: 20.h),

              // === 계정 관리 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildAccountSection(),
              ),

              SizedBox(height: 20.h),

              // === 서비스 섹션 ===
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

              SizedBox(height: 20.h),

              // === 회원탈퇴 버튼 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: CustomButton(
                  text: '회원탈퇴',
                  icon: Icons.delete_outline,
                  type: ButtonType.outline,
                  onPressed: _handleDeleteAccount,
                ),
              ),

              // === 상담사 등록/승인 버튼 ===
              SizedBox(height: 16.h),
              if (user.userType == UserType.master)
                CustomButton(
                  text: '상담사 승인',
                  icon: Icons.verified_user,
                  type: ButtonType.outline,
                  onPressed: () => context.push(AppRoutes.counselorApproval),
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
    return ThemedCard(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // 프로필 이미지
          Stack(
            children: [
              CircleAvatar(
                radius: 50.r,
                backgroundColor:
                    context.isDarkMode ? AppColors.darkCard : AppColors.grey200,
                backgroundImage:
                    user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                child:
                    user.profileImageUrl == null
                        ? ThemedIcon(icon: Icons.person, size: 50.sp)
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
                      border: Border.all(color: context.surfaceColor, width: 2),
                    ),
                    child: Icon(Icons.edit, size: 16.sp, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 사용자 이름
          ThemedText(
            text: user.name ?? '이름 없음',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
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
          ThemedText(
            text: user.email,
            isPrimary: false,
            style: TextStyle(fontSize: 14.sp),
          ),

          if (user.sport?.isNotEmpty == true) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ThemedIcon(icon: Icons.sports, size: 16.sp),
                SizedBox(width: 4.w),
                ThemedText(
                  text: user.sport!,
                  isPrimary: false,
                  style: TextStyle(fontSize: 14.sp),
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
      icon: Icons.account_circle_outlined,
      items: [
        _ProfileMenuItem(
          icon: Icons.edit_outlined,
          title: '프로필 수정',
          subtitle: '개인 정보 및 프로필 이미지 변경',
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        _ProfileMenuItem(
          icon: Icons.settings_outlined,
          title: '설정',
          subtitle: '알림, 다크모드 등 앱 설정',
          onTap: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    return _buildSection(
      title: '서비스',
      icon: Icons.medical_services_outlined,
      items: [
        _ProfileMenuItem(
          icon: Icons.history,
          title: '자가진단 기록',
          subtitle: '이전 진단 결과 및 통계 확인',
          onTap: () => context.push(AppRoutes.selfCheckHistory),
        ),
        _ProfileMenuItem(
          icon: Icons.chat_outlined,
          title: '상담 기록',
          subtitle: '상담 내역',
          onTap: () => context.push(AppRoutes.bookingList),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: '고객 지원',
      icon: Icons.support_agent_outlined,
      items: [
        _ProfileMenuItem(
          icon: Icons.help_outline,
          title: '도움말',
          subtitle: '자주 묻는 질문 및 사용법',
          onTap: () => context.push(AppRoutes.help),
        ),
        _ProfileMenuItem(
          icon: Icons.feedback_outlined,
          title: '피드백 보내기',
          subtitle: '의견 및 개선사항 제안',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('피드백 기능은 준비 중입니다'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
        _ProfileMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: '개인정보처리방침',
          subtitle: '개인정보 보호 정책',
          onTap: () => context.push(AppRoutes.privacy),
        ),
        _ProfileMenuItem(
          icon: Icons.description_outlined,
          title: '이용약관',
          subtitle: '서비스 이용 약관',
          onTap: () => context.push(AppRoutes.terms),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_ProfileMenuItem> items,
  }) {
    return ThemedCard(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 12.w),
              ThemedText(
                text: title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...items.map((item) => _buildMenuItem(item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_ProfileMenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color:
                    context.isDarkMode
                        ? AppColors.darkCard.withOpacity(0.5)
                        : AppColors.grey100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                item.icon,
                size: 20.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemedText(
                    text: item.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    ThemedText(
                      text: item.subtitle!,
                      isPrimary: false,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ],
              ),
            ),
            ThemedIcon(icon: Icons.arrow_forward_ios, size: 16.sp),
          ],
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
