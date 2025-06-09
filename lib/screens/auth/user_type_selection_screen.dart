import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/models/user_model.dart';

class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen>
    with TickerProviderStateMixin {
  UserType? _selectedUserType;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<UserTypeOption> _userTypes = [
    UserTypeOption(
      type: UserType.athlete,
      title: '선수',
      subtitle: '프로/아마추어 스포츠 선수',
      description: '경기력 향상과 멘탈 관리가 필요한\n모든 종목의 선수들을 위한 전문 상담',
      icon: Icons.sports_soccer,
      color: AppColors.primary,
      benefits: ['경기 전 심리 컨디셔닝', '스포츠 심리학 기반 상담', '목표 설정 및 동기부여', '부상 후 멘탈 회복'],
    ),
    UserTypeOption(
      type: UserType.general,
      title: '일반인',
      subtitle: '운동을 즐기는 일반인',
      description: '건강한 운동 습관과 스트레스 관리를\n원하는 일반인을 위한 맞춤 상담',
      icon: Icons.fitness_center,
      color: AppColors.secondary,
      benefits: [
        '운동 동기부여 및 습관 형성',
        '일상 스트레스 관리',
        '건강한 라이프스타일 코칭',
        '운동 관련 목표 달성',
      ],
    ),
    UserTypeOption(
      type: UserType.guardian,
      title: '보호자',
      subtitle: '선수 자녀를 둔 부모님',
      description: '자녀의 스포츠 활동을 지원하고\n올바른 멘탈 케어를 원하는 보호자',
      icon: Icons.family_restroom,
      color: AppColors.accent,
      benefits: ['자녀 심리 상태 이해', '효과적인 소통 방법', '스포츠 부모 역할 가이드', '가족 관계 개선'],
    ),
    UserTypeOption(
      type: UserType.coach,
      title: '지도자',
      subtitle: '스포츠 지도자 및 트레이너',
      description: '선수들의 멘탈 코칭과 팀 관리에\n전문성을 더하고 싶은 지도자',
      icon: Icons.sports,
      color: AppColors.info,
      benefits: ['팀 멘탈 관리 전략', '선수 개별 코칭 스킬', '리더십 및 소통 능력', '번아웃 예방 및 관리'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('사용자 유형 선택'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // === 헤더 섹션 ===
                _buildHeader(),

                // === 사용자 유형 선택 ===
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        ..._userTypes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final userType = entry.value;
                          return _buildUserTypeCard(userType, index);
                        }),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),

                // === 계속하기 버튼 ===
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '어떤 분이신가요?',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '사용자 유형에 맞는 맞춤형 서비스를 제공합니다',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard(UserTypeOption userType, int index) {
    final isSelected = _selectedUserType == userType.type;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserType = userType.type;
          });
        },
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? userType.color : AppColors.grey200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: userType.color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === 타입 헤더 ===
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: userType.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      userType.icon,
                      size: 28.sp,
                      color: userType.color,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userType.title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          userType.subtitle,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: userType.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16.sp,
                        color: AppColors.white,
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16.h),

              // === 설명 ===
              Text(
                userType.description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 16.h),

              // === 혜택 목록 ===
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: userType.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '주요 혜택',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: userType.color,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...userType.benefits.map(
                      (benefit) => Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14.sp,
                              color: userType.color,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                benefit,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildContinueButton() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          CustomButton(
            text: '계속하기',
            onPressed: _selectedUserType != null ? _handleContinue : null,
            icon: Icons.arrow_forward,
          ),
          SizedBox(height: 12.h),
          Text(
            '나중에 설정에서 변경할 수 있습니다',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // === 액션 핸들러 ===

  void _handleContinue() {
    if (_selectedUserType == null) return;

    // 사용자 유형이 선택되었으므로 온보딩으로 이동
    // 나중에 회원가입 시 이 정보를 사용할 예정
    context.push(AppRoutes.onboardingBasicInfo);
  }
}

// === 사용자 유형 옵션 모델 ===
class UserTypeOption {
  final UserType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> benefits;

  const UserTypeOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.benefits,
  });
}
