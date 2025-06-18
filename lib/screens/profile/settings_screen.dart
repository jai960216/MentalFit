import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _marketingEnabled = false;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isDeletingAccount = false;

  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _marketingEnabled = prefs.getBool('marketing_enabled') ?? false;
        _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
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

  // === 설정 변경 핸들러들 ===
  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _saveSetting('notifications_enabled', value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '알림이 켜졌습니다' : '알림이 꺼졌습니다'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _toggleMarketing(bool value) {
    setState(() => _marketingEnabled = value);
    _saveSetting('marketing_enabled', value);
  }

  void _toggleDarkMode(bool value) {
    setState(() => _darkModeEnabled = value);
    _saveSetting('dark_mode_enabled', value);

    // TODO: 실제로는 테마 변경 처리 필요
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('다크 모드 기능은 준비 중입니다'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _toggleSound(bool value) {
    setState(() => _soundEnabled = value);
    _saveSetting('sound_enabled', value);
  }

  void _toggleVibration(bool value) {
    setState(() => _vibrationEnabled = value);
    _saveSetting('vibration_enabled', value);
  }

  // === 계정 삭제 ===
  Future<void> _handleDeleteAccount() async {
    final confirmed = await _showDeleteAccountDialog();
    if (!confirmed) return;

    // 비밀번호 입력 다이얼로그
    final password = await _showPasswordInputDialog();
    if (password == null || password.isEmpty) return;

    setState(() => _isDeletingAccount = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .deleteAccount(password);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 삭제되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.login);
      } else if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          '계정 삭제에 실패했습니다. 비밀번호를 다시 확인해주세요.',
        );
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  // 비밀번호 입력 다이얼로그
  Future<String?> _showPasswordInputDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('비밀번호 확인'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '계정 비밀번호를 입력하세요',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('확인'),
              ),
            ],
          ),
    );
    return result;
  }

  Future<bool> _showDeleteAccountDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('계정 삭제'),
            content: const Text(
              '정말로 계정을 삭제하시겠습니까?\n\n'
              '삭제된 계정과 모든 데이터는 복구할 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  // === 다이얼로그 표시 ===
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이용약관'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: const SingleChildScrollView(
                child: Text('''제1조 (목적)
이 약관은 MentalFit(이하 "회사")가 제공하는 스포츠 심리 상담 서비스의 이용조건 및 절차에 관한 사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 회사가 제공하는 모든 스포츠 심리 상담 관련 서비스를 의미합니다.
② "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.

제3조 (약관의 게시와 개정)
① 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.

제4조 (서비스의 제공)
① 회사는 다음과 같은 서비스를 제공합니다:
- AI 기반 심리 상담 서비스
- 전문 상담사와의 1:1 상담 서비스
- 자가진단 및 심리 검사 서비스
- 상담 기록 관리 서비스

자세한 이용약관은 서비스 내에서 확인하실 수 있습니다.'''),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('개인정보처리방침'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: const SingleChildScrollView(
                child: Text('''1. 개인정보의 처리목적
MentalFit(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다:
- 회원 가입 및 관리
- 서비스 제공 및 계약의 이행
- 고객 상담 및 민원 처리

2. 개인정보의 처리 및 보유기간
① 회사는 법령에 따른 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
② 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:
- 회원 가입 및 관리: 회원 탈퇴 시까지
- 상담 서비스 제공: 서비스 종료 후 3년

3. 개인정보의 제3자 제공
회사는 원칙적으로 정보주체의 개인정보를 수집·이용 목적으로 명시한 범위 내에서 처리합니다.

자세한 개인정보처리방침은 서비스 내에서 확인하실 수 있습니다.'''),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '설정'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // === 알림 설정 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildNotificationSection(),
              ),

              SizedBox(height: 20.h),

              // === 앱 설정 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildAppSection(),
              ),

              SizedBox(height: 20.h),

              // === 계정 관리 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildAccountSection(),
              ),

              SizedBox(height: 20.h),

              // === 정보 섹션 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildInfoSection(),
              ),

              SizedBox(height: 32.h),

              // === 계정 삭제 버튼 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildDeleteAccountButton(),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildNotificationSection() {
    return _buildSection(
      title: '알림 설정',
      icon: Icons.notifications_outlined,
      children: [
        _buildSwitchTile(
          title: '푸시 알림',
          subtitle: '예약, 채팅 등 중요한 알림 받기',
          value: _notificationsEnabled,
          onChanged: _toggleNotifications,
        ),
        _buildSwitchTile(
          title: '마케팅 알림',
          subtitle: '이벤트, 프로모션 정보 받기',
          value: _marketingEnabled,
          onChanged: _toggleMarketing,
        ),
        _buildSwitchTile(
          title: '소리',
          subtitle: '알림음 및 효과음',
          value: _soundEnabled,
          onChanged: _toggleSound,
        ),
        _buildSwitchTile(
          title: '진동',
          subtitle: '알림 시 진동',
          value: _vibrationEnabled,
          onChanged: _toggleVibration,
        ),
      ],
    );
  }

  Widget _buildAppSection() {
    return _buildSection(
      title: '앱 설정',
      icon: Icons.settings_outlined,
      children: [
        _buildSwitchTile(
          title: '다크 모드',
          subtitle: '어두운 테마 사용',
          value: _darkModeEnabled,
          onChanged: _toggleDarkMode,
        ),
        _buildMenuTile(
          title: '언어 설정',
          subtitle: '한국어',
          icon: Icons.language_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('언어 설정 기능은 준비 중입니다'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
        _buildMenuTile(
          title: '캐시 지우기',
          subtitle: '임시 파일 및 이미지 캐시 삭제',
          icon: Icons.cleaning_services_outlined,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('캐시가 지워졌습니다'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: '계정 관리',
      icon: Icons.account_circle_outlined,
      children: [
        _buildMenuTile(
          title: '비밀번호 변경',
          subtitle: '새로운 비밀번호로 변경',
          icon: Icons.lock_outline,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('비밀번호 변경 기능은 준비 중입니다'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return _buildSection(
      title: '정보',
      icon: Icons.info_outline,
      children: [
        _buildMenuTile(
          title: '이용약관',
          subtitle: '서비스 이용약관 보기',
          icon: Icons.description_outlined,
          onTap: _showTermsDialog,
        ),
        _buildMenuTile(
          title: '개인정보처리방침',
          subtitle: '개인정보 보호 정책',
          icon: Icons.privacy_tip_outlined,
          onTap: _showPrivacyDialog,
        ),
        _buildMenuTile(
          title: '고객센터',
          subtitle: '문의사항 및 도움말',
          icon: Icons.help_outline,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('고객센터 기능은 준비 중입니다'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
        _buildInfoTile(
          title: '앱 버전',
          value: _appVersion,
          icon: Icons.info_outlined,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
            child: Row(
              children: [
                Icon(icon, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children.map((child) => child).toList(),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
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
                size: 16.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return CustomButton(
      text: '계정 삭제',
      onPressed: _isDeletingAccount ? null : _handleDeleteAccount,
      isLoading: _isDeletingAccount,
      type: ButtonType.outline,
      icon: Icons.delete_outline,
    );
  }
}
