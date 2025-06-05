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
      // 온보딩 데이터 분석
      final analysis = await _onboardingService.analyzeOnboardingData(
        onboardingData,
      );
      final recommendations = await _onboardingService
          .getPersonalizedRecommendations(onboardingData);

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _recommendations = recommendations;
          _isLoading = false;
        });

        // 애니메이션 시작
        _fadeController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  // === 온보딩 완료 처리 ===
  Future<void> _handleComplete() async {
    setState(() => _isCompleting = true);

    try {
      final onboardingData = ref.read(onboardingProvider);

      // 1. 온보딩 완료 처리
      final result = await _onboardingService.completeOnboarding(
        onboardingData,
      );

      if (result.success) {
        // 2. AuthProvider 업데이트
        if (result.user != null) {
          ref.read(authProvider.notifier).updateUser(result.user!);
        } else {
          ref.read(authProvider.notifier).completeOnboarding();
        }

        // 3. OnboardingProvider 완료 표시
        ref.read(onboardingProvider.notifier).completeOnboarding();

        if (mounted) {
          // 4. 홈 화면으로 이동
          context.go(AppRoutes.home);
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(
            context,
            result.error ?? '온보딩 완료 중 오류가 발생했습니다.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '심리 상태 분석',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        Container(
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
              // === 전체 점수 ===
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '종합 점수',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${_analysis!.overallScore.toStringAsFixed(1)} / 10',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(_analysis!.overallScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiskLevelColor(
                        _analysis!.riskLevel,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      _getRiskLevelText(_analysis!.riskLevel),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _getRiskLevelColor(_analysis!.riskLevel),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // === 분석 요약 ===
              Text(
                _analysis!.summary,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '맞춤 추천',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        ..._recommendations
            .map((recommendation) => _buildRecommendationCard(recommendation))
            .toList(),
      ],
    );
  }

  Widget _buildRecommendationCard(OnboardingRecommendation recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getPriorityColor(recommendation.priority).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _getPriorityColor(
                recommendation.priority,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getRecommendationIcon(recommendation.type),
              color: _getPriorityColor(recommendation.priority),
              size: 20.sp,
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
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === 헬퍼 메서드들 ===

  Color _getScoreColor(double score) {
    if (score >= 7) return AppColors.success;
    if (score >= 5) return AppColors.warning;
    return AppColors.error;
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getRiskLevelText(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return '양호';
      case 'medium':
        return '주의';
      case 'high':
        return '관리 필요';
      default:
        return '분석 중';
    }
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return AppColors.error;
      case RecommendationPriority.medium:
        return AppColors.warning;
      case RecommendationPriority.low:
        return AppColors.info;
    }
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.technique:
        return Icons.psychology;
      case RecommendationType.counseling:
        return Icons.people;
      case RecommendationType.program:
        return Icons.school;
      case RecommendationType.ai:
        return Icons.smart_toy;
      case RecommendationType.resource:
        return Icons.library_books;
    }
  }
}
