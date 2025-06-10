import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/self_check_models.dart';
import '../../providers/self_check_provider.dart';

class SelfCheckResultScreen extends ConsumerStatefulWidget {
  final String resultId;

  const SelfCheckResultScreen({super.key, required this.resultId});

  @override
  ConsumerState<SelfCheckResultScreen> createState() =>
      _SelfCheckResultScreenState();
}

class _SelfCheckResultScreenState extends ConsumerState<SelfCheckResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  SelfCheckResult? _result;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadResult();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _loadResult() async {
    try {
      final result = await ref
          .read(selfCheckProvider.notifier)
          .getResultDetail(widget.resultId);

      setState(() {
        _result = result;
        _isLoading = false;
      });

      // 애니메이션 시작
      _fadeController.forward();
      _scaleController.forward();

      // 진행률 애니메이션은 약간 지연 후 시작
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _progressController.forward();
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _shareResult() {
    if (_result == null) return;

    // TODO: 결과 공유 기능 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('결과 공유 기능이 곧 추가될 예정입니다.')));
  }

  void _bookCounseling() {
    context.push(AppRoutes.counselorList);
  }

  void _goToHome() {
    context.go(AppRoutes.home);
  }

  void _retakeTest() {
    if (_result == null) return;

    context.push(
      AppRoutes.selfCheckTest,
      extra: {'testId': _result!.test.id, 'testType': _result!.test.type},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_error != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: '검사 결과'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
              SizedBox(height: 16.h),
              Text(
                '결과를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('홈으로 돌아가기'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: '검사 결과'),
        body: Center(child: Text('결과를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: '검사 결과',
        backgroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareResult),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === 결과 헤더 ===
              _buildResultHeader(),

              SizedBox(height: 32.h),

              // === 점수 카드 ===
              _buildScoreCard(),

              SizedBox(height: 24.h),

              // === 위험도 분석 ===
              _buildRiskAnalysis(),

              SizedBox(height: 24.h),

              // === 카테고리별 점수 (있는 경우) ===
              if (_result!.categoryScores.isNotEmpty) _buildCategoryScores(),

              if (_result!.categoryScores.isNotEmpty) SizedBox(height: 24.h),

              // === 결과 해석 ===
              _buildInterpretation(),

              SizedBox(height: 24.h),

              // === 추천사항 ===
              _buildRecommendations(),

              SizedBox(height: 32.h),

              // === 액션 버튼들 ===
              _buildActionButtons(),

              SizedBox(height: 24.h),

              // === 검사 정보 ===
              _buildTestInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _result!.riskLevel.color.withOpacity(0.1),
              _result!.riskLevel.color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _result!.riskLevel.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _result!.test.category.icon,
              size: 48.w,
              color: _result!.riskLevel.color,
            ),
            SizedBox(height: 16.h),
            Text(
              _result!.test.title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              '검사 완료: ${_result!.completedAt.month}/${_result!.completedAt.day} ${_result!.completedAt.hour}:${_result!.completedAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '총 점수',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_result!.totalScore}',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: _result!.riskLevel.color,
                ),
              ),
              Text(
                ' / ${_result!.maxScore}',
                style: TextStyle(
                  fontSize: 24.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    value:
                        _progressAnimation.value * (_result!.percentage / 100),
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _result!.riskLevel.color,
                    ),
                    minHeight: 8.h,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${(_progressAnimation.value * _result!.percentage).toInt()}%',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _result!.riskLevel.color,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAnalysis() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _result!.riskLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _result!.riskLevel.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _result!.riskLevel.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getRiskLevelIcon(_result!.riskLevel),
              color: AppColors.white,
              size: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _result!.riskLevel.name,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: _result!.riskLevel.color,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _result!.riskLevel.description,
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
    );
  }

  Widget _buildCategoryScores() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '영역별 점수',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ..._result!.categoryScores.entries.map((entry) {
            final maxCategoryScore =
                (_result!.maxScore / _result!.categoryScores.length).round();
            final percentage = (entry.value / maxCategoryScore) * 100;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${entry.value}점',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6.h,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInterpretation() {
    if (_result!.interpretation == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
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
              Icon(Icons.analytics_outlined, color: AppColors.info, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '결과 해석',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            _result!.interpretation!,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_result!.recommendations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
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
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.warning,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                '맞춤 추천사항',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ..._result!.recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final recommendation = entry.value;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        // 높은 위험도인 경우 상담 예약 버튼 강조
        if (_result!.riskLevel == RiskLevel.high)
          Container(
            margin: EdgeInsets.only(bottom: 16.h),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _bookCounseling,
              icon: const Icon(Icons.psychology),
              label: const Text('전문 상담사와 상담하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retakeTest,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 검사하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.grey300),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _bookCounseling,
                icon: const Icon(Icons.calendar_today),
                label: const Text('상담 예약하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _goToHome,
            icon: const Icon(Icons.home),
            label: const Text('홈으로 돌아가기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.grey100,
              side: BorderSide(color: AppColors.grey300),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '검사 정보',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          _buildInfoRow('검사 유형', _result!.test.type.fullName),
          _buildInfoRow('총 문항 수', '${_result!.test.questionCount}문항'),
          _buildInfoRow('응답 완료', '${_result!.answers.length}문항'),
          _buildInfoRow(
            '검사 일시',
            '${_result!.completedAt.year}.${_result!.completedAt.month.toString().padLeft(2, '0')}.${_result!.completedAt.day.toString().padLeft(2, '0')} '
                '${_result!.completedAt.hour.toString().padLeft(2, '0')}:${_result!.completedAt.minute.toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRiskLevelIcon(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.moderate:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
    }
  }
}
