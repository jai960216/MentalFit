import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/services/onboarding_service.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingMentalCheckScreen extends ConsumerStatefulWidget {
  const OnboardingMentalCheckScreen({super.key});

  @override
  ConsumerState<OnboardingMentalCheckScreen> createState() =>
      _OnboardingMentalCheckScreenState();
}

class _OnboardingMentalCheckScreenState
    extends ConsumerState<OnboardingMentalCheckScreen> {
  int? _stressLevel;
  int? _anxietyLevel;
  int? _confidenceLevel;
  int? _motivationLevel;
  bool _isLoading = false;

  late OnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadExistingData();
  }

  Future<void> _initializeServices() async {
    _onboardingService = await OnboardingService.getInstance();
  }

  void _loadExistingData() {
    final currentData = ref.read(onboardingProvider);
    _stressLevel = currentData.stressLevel;
    _anxietyLevel = currentData.anxietyLevel;
    _confidenceLevel = currentData.confidenceLevel;
    _motivationLevel = currentData.motivationLevel;
  }

  // === 유효성 검사 ===
  bool _isValidated() {
    return _stressLevel != null &&
        _anxietyLevel != null &&
        _confidenceLevel != null &&
        _motivationLevel != null;
  }

  // === 다음 단계로 이동 ===
  Future<void> _handleNext() async {
    if (!_isValidated()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 항목을 평가해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 로컬 상태 업데이트
      ref
          .read(onboardingProvider.notifier)
          .updateMentalState(
            stressLevel: _stressLevel!,
            anxietyLevel: _anxietyLevel!,
            confidenceLevel: _confidenceLevel!,
            motivationLevel: _motivationLevel!,
          );

      // 2. 서버에 저장
      await _onboardingService.saveMentalState(
        stressLevel: _stressLevel!,
        anxietyLevel: _anxietyLevel!,
        confidenceLevel: _confidenceLevel!,
        motivationLevel: _motivationLevel!,
      );

      if (mounted) {
        context.go(AppRoutes.onboardingPreferences);
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(onboardingProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('심리 상태 체크'),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _isLoading
                  ? null
                  : () => context.go(AppRoutes.onboardingBasicInfo),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === 진행률 표시 ===
            _buildProgressIndicator(progress),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === 헤더 ===
                    _buildHeader(),

                    SizedBox(height: 32.h),

                    // === 스트레스 레벨 ===
                    _buildMentalStateCard(
                      title: '스트레스 수준',
                      description: '평소 느끼는 스트레스 정도를 선택해주세요',
                      icon: Icons.psychology,
                      iconColor: AppColors.error,
                      value: _stressLevel,
                      onChanged:
                          (value) => setState(() => _stressLevel = value),
                      lowLabel: '거의 없음',
                      highLabel: '매우 높음',
                    ),

                    SizedBox(height: 24.h),

                    // === 불안 레벨 ===
                    _buildMentalStateCard(
                      title: '불안감 수준',
                      description: '경기나 훈련 전 느끼는 불안감 정도',
                      icon: Icons.sentiment_very_dissatisfied,
                      iconColor: AppColors.warning,
                      value: _anxietyLevel,
                      onChanged:
                          (value) => setState(() => _anxietyLevel = value),
                      lowLabel: '차분함',
                      highLabel: '매우 불안',
                    ),

                    SizedBox(height: 24.h),

                    // === 자신감 레벨 ===
                    _buildMentalStateCard(
                      title: '자신감 수준',
                      description: '자신의 실력과 능력에 대한 믿음 정도',
                      icon: Icons.emoji_events,
                      iconColor: AppColors.success,
                      value: _confidenceLevel,
                      onChanged:
                          (value) => setState(() => _confidenceLevel = value),
                      lowLabel: '부족함',
                      highLabel: '매우 높음',
                    ),

                    SizedBox(height: 24.h),

                    // === 동기 레벨 ===
                    _buildMentalStateCard(
                      title: '동기 수준',
                      description: '운동과 경기에 대한 의욕과 열정 정도',
                      icon: Icons.local_fire_department,
                      iconColor: AppColors.primary,
                      value: _motivationLevel,
                      onChanged:
                          (value) => setState(() => _motivationLevel = value),
                      lowLabel: '낮음',
                      highLabel: '매우 높음',
                    ),

                    SizedBox(height: 40.h),

                    // === 다음 버튼 ===
                    CustomButton(
                      text: '다음',
                      onPressed: _isLoading ? null : _handleNext,
                      isLoading: _isLoading,
                      icon: Icons.arrow_forward,
                    ),

                    SizedBox(height: 16.h),

                    // === 도움말 ===
                    _buildHelpText(),
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

  Widget _buildProgressIndicator(double progress) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2/4 단계',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% 완료',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: 0.5, // 2/4 단계
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '현재 심리 상태를 알려주세요',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '정확한 평가를 위해 솔직하게 답변해주세요.\n정답은 없으며, 개인차를 고려한 맞춤 서비스를 제공하기 위함입니다.',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMentalStateCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required int? value,
    required ValueChanged<int> onChanged,
    required String lowLabel,
    required String highLabel,
  }) {
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
          // === 제목과 아이콘 ===
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // === 슬라이더 ===
          Row(
            children: [
              Text(
                lowLabel,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: (value ?? 5).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: iconColor,
                  inactiveColor: AppColors.grey300,
                  onChanged:
                      _isLoading ? null : (val) => onChanged(val.round()),
                ),
              ),
              Text(
                highLabel,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // === 선택된 값 표시 ===
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                value != null ? '$value / 10' : '선택해주세요',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '평가 기준 참고',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '• 1-3: 낮음\n• 4-6: 보통\n• 7-10: 높음\n\n최근 2주간의 평균적인 상태를 기준으로 평가해주세요.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
