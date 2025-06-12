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
import '../../providers/auth_provider.dart';
import '../../shared/models/onboarding_model.dart';

class OnboardingCompleteScreen extends ConsumerStatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  ConsumerState<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState
    extends ConsumerState<OnboardingCompleteScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isCompleting = false;
  OnboardingAnalysis? _analysis;
  List<OnboardingRecommendation> _recommendations = [];

  late OnboardingService _onboardingService;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAndAnalyze();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  Future<void> _initializeAndAnalyze() async {
    _onboardingService = await OnboardingService.getInstance();

    final onboardingData = ref.read(onboardingProvider);

    try {
      // Mock 분석 데이터 생성 (실제 서버가 없으므로)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _analysis = _createMockAnalysis(onboardingData);
          _recommendations = _createMockRecommendations(onboardingData);
          _isLoading = false;
        });

        // 애니메이션 시작
        _fadeController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  // Mock 분석 데이터 생성
  OnboardingAnalysis _createMockAnalysis(OnboardingData data) {
    return OnboardingAnalysis(
      overallScore: 5.3,
      stressLevel: data.stressLevel ?? 5,
      recommendation: '전반적으로 관리가 필요한 상태입니다. 정기적인 상담과 운동을 권장합니다.',
      strengths: ['긍정적인 마인드', '목표 의식'],
      improvements: ['스트레스 관리', '수면 패턴 개선'],
    );
  }

  // Mock 추천 데이터 생성
  List<OnboardingRecommendation> _createMockRecommendations(
    OnboardingData data,
  ) {
    return [
      OnboardingRecommendation(
        type: 'counseling',
        title: '불안 관리 상담',
        description: '심리 전문가와의 1:1 맞춤형 상담으로 불안을 효과적으로 관리하세요.',
        icon: '👥',
      ),
      OnboardingRecommendation(
        type: 'ai',
        title: 'AI 심리 체크',
        description: '24시간 언제든지 이용 가능한 AI 상담으로 심리 상태를 체크하세요.',
        icon: '🤖',
      ),
    ];
  }

  // === 온보딩 완료 처리 (실서비스용 버전) ===
  Future<void> _handleComplete() async {
    if (_isCompleting) return; // 중복 실행 방지

    setState(() => _isCompleting = true);

    try {
      final onboardingData = ref.read(onboardingProvider);

      // 1. 온보딩 완료 처리 (Mock 처리 - 실제 서버 연동 시 교체)
      await Future.delayed(const Duration(seconds: 1));

      // 2. 로컬 상태 업데이트
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      ref.read(authProvider.notifier).completeOnboarding();

      if (mounted) {
        // 3. 홈 화면으로 이동
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          '온보딩 완료 처리 중 오류가 발생했습니다.',
        );

        // 오류가 발생해도 홈 화면으로 이동
        context.go(AppRoutes.home);
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('분석 결과'),
        backgroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === 진행률 표시 (100%) ===
            _buildProgressIndicator(),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === 완료 헤더 ===
                        _buildCompletionHeader(),

                        SizedBox(height: 32.h),

                        // === 분석 결과 ===
                        if (_analysis != null) _buildAnalysisSection(),

                        SizedBox(height: 24.h),

                        // === 맞춤 추천 ===
                        if (_recommendations.isNotEmpty)
                          _buildRecommendationsSection(),

                        SizedBox(height: 32.h),

                        // === 시작하기 버튼 ===
                        CustomButton(
                          text: 'MentalFit 시작하기',
                          onPressed: _isCompleting ? null : _handleComplete,
                          isLoading: _isCompleting,
                          icon: Icons.rocket_launch,
                        ),

                        SizedBox(height: 24.h),

                        // === 안내 메시지 ===
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '설정은 언제든 변경 가능합니다',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '마이페이지에서 프로필 및 선호도를 수정할 수 있어요.',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 24.h),
            Text(
              '데이터를 분석하고 있습니다...',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '4/4 단계',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '100% 완료',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: 1.0, // 100% 완료
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.celebration, size: 40.sp, color: AppColors.white),
          ),
          SizedBox(height: 16.h),
          Text(
            '온보딩 완료!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '설문에 응답해주셔서 감사합니다.\n분석 결과를 바탕으로 맞춤형 서비스를 제공해드릴게요.',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    if (_analysis == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
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
          Text(
            '심리 상태 분석',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // 종합 점수
          Row(
            children: [
              Text(
                '종합 점수',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '주의',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_analysis!.overallScore}',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              Text(
                ' / 10',
                style: TextStyle(
                  fontSize: 20.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Text(
            _analysis!.recommendation,
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

  Widget _buildRecommendationsSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
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
          Text(
            '맞춤 추천',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          ..._recommendations.map((recommendation) {
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        recommendation.icon,
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          recommendation.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// === Mock 데이터 모델들 ===
class OnboardingAnalysis {
  final double overallScore;
  final int stressLevel;
  final String recommendation;
  final List<String> strengths;
  final List<String> improvements;

  OnboardingAnalysis({
    required this.overallScore,
    required this.stressLevel,
    required this.recommendation,
    required this.strengths,
    required this.improvements,
  });
}

class OnboardingRecommendation {
  final String type;
  final String title;
  final String description;
  final String icon;

  OnboardingRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });
}
