import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/theme_aware_widgets.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  // === 상태 변수들 ===
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _marketingEnabled = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

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
    final notifier = ref.read(themeProvider.notifier);
    notifier.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '다크 모드가 켜졌습니다' : '라이트 모드가 켜졌습니다'),
        backgroundColor: AppColors.success,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ThemedScaffold(body: LoadingWidget());
    }

    return ThemedScaffold(
      appBar: const CustomAppBar(title: '설정'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // === 알림 설정 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildNotificationSection(),
              ),

              SizedBox(height: 20.h),

              // === 앱 설정 ===
              FadeTransition(
                opacity: _cardAnimation,
                child: _buildAppSection(),
              ),

              SizedBox(height: 20.h),

              // === 계정 관리 ===
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

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: '알림 설정',
      icon: Icons.notifications_outlined,
      children: [
        _buildSwitchTile(
          title: '푸시 알림',
          subtitle: '새 메시지 및 업데이트 알림',
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
    final themeMode = ref.watch(themeProvider);
    return _buildSection(
      title: '앱 설정',
      icon: Icons.settings_outlined,
      children: [
        _buildSwitchTile(
          title: '다크 모드',
          subtitle: '어두운 테마 사용',
          value: themeMode == ThemeMode.dark,
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
        _buildMenuTile(
          title: '프로필 수정',
          subtitle: '개인 정보 및 선호도 변경',
          icon: Icons.edit_outlined,
          onTap: () => context.push(AppRoutes.editProfile),
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
          subtitle: '서비스 이용약관 확인',
          icon: Icons.description_outlined,
          onTap: () => context.push(AppRoutes.terms),
        ),
        _buildMenuTile(
          title: '개인정보처리방침',
          subtitle: '개인정보 보호정책 확인',
          icon: Icons.privacy_tip_outlined,
          onTap: () => context.push(AppRoutes.privacy),
        ),
        _buildMenuTile(
          title: '앱 버전',
          subtitle: '1.0.0',
          icon: Icons.info,
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText(
                  text: title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                ThemedText(
                  text: subtitle,
                  isPrimary: false,
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
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
    VoidCallback? onTap,
    bool enabled = true,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive ? AppColors.error : null;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.primary,
              size: 20.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemedText(
                    text: title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ThemedText(
                    text: subtitle,
                    isPrimary: false,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (enabled && onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 16.sp,
              ),
          ],
        ),
      ),
    );
  }


}
