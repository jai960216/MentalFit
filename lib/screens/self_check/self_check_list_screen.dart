import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/models/self_check_models.dart';
import '../../providers/self_check_provider.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';

class SelfCheckListScreen extends ConsumerStatefulWidget {
  const SelfCheckListScreen({super.key});

  @override
  ConsumerState<SelfCheckListScreen> createState() =>
      _SelfCheckListScreenState();
}

class _SelfCheckListScreenState extends ConsumerState<SelfCheckListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // 페이지 로드 시 데이터 자동 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await ref.read(selfCheckProvider.notifier).loadAvailableTests();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('검사 초기화 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터를 불러오는 중 오류가 발생했습니다: $e'),
            action: SnackBarAction(label: '다시 시도', onPressed: _loadData),
          ),
        );
      }
    }
  }

  Future<void> _startTest(SelfCheckTest test) async {
    try {
      // 1. 로딩 상태 표시
      _showLoadingDialog();

      // 2. 검사 시작 전 프로바이더에 현재 검사 설정
      ref.read(selfCheckProvider.notifier).startTest(test);

      // 3. 잠시 대기 (상태 업데이트 확실히 하기 위해)
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // 4. 로딩 다이얼로그 닫기
        Navigator.of(context).pop();

        // 5. 테스트 화면으로 이동
        context.push(
          '${AppRoutes.selfCheckTest}/${test.id}',
          extra: {'test': test},
        );
      }
    } catch (e) {
      if (mounted) {
        // 로딩 다이얼로그가 열려있다면 닫기
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('자가진단을 시작할 수 없습니다: $e'),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => _startTest(test),
            ),
          ),
        );
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('검사를 준비하고 있습니다...'),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selfCheckState = ref.watch(selfCheckProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: '자가진단',
        backgroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child:
            selfCheckState.isLoading && selfCheckState.availableTests.isEmpty
                ? const LoadingWidget()
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(selfCheckState),
                ),
      ),
    );
  }

  Widget _buildContent(SelfCheckState state) {
    if (state.error != null && state.availableTests.isEmpty) {
      return _buildErrorState(state.error!);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 헤더 섹션 ===
          _buildHeaderSection(),

          SizedBox(height: 24.h),

          // === 추천 검사 섹션 ===
          if (state.recommendedTests.isNotEmpty) ...[
            _buildRecommendedSection(state.recommendedTests),
            SizedBox(height: 32.h),
          ],

          // === 전체 검사 목록 ===
          _buildAllTestsSection(state.availableTests),

          SizedBox(height: 24.h),

          // === 최근 검사 기록 ===
          if (state.recentResults.isNotEmpty) ...[
            _buildRecentHistorySection(state.recentResults),
            SizedBox(height: 40.h),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text('다시 시도'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 24.sp, color: AppColors.white),
              SizedBox(width: 8.w),
              Text(
                '자가진단',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '심리 상태를 자가진단하고 관리하세요',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(List<SelfCheckTest> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추천 검사',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: _buildRecommendedTestCard(test),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedTestCard(SelfCheckTest test) {
    return GestureDetector(
      onTap: () => _startTest(test),
      child: Container(
        width: 280.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: test.category.color.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Center(
                child: Icon(
                  test.category.icon,
                  size: 40.sp,
                  color: test.category.color,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    test.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _buildTestInfo(
                        Icons.schedule,
                        '약 ${test.estimatedMinutes}분',
                      ),
                      SizedBox(width: 16.w),
                      _buildTestInfo(Icons.quiz, '${test.questions.length}문항'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTestsSection(List<SelfCheckTest> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '전체 검사',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildTestCard(test),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTestCard(SelfCheckTest test) {
    return GestureDetector(
      onTap: () => _startTest(test),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: test.category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    test.category.icon,
                    size: 24.sp,
                    color: test.category.color,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        test.description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                _buildTestInfo(Icons.schedule, '약 ${test.estimatedMinutes}분'),
                SizedBox(width: 16.w),
                _buildTestInfo(Icons.quiz, '${test.questions.length}문항'),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: test.category.color,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '시작하기',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward,
                        size: 12.sp,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textSecondary),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRecentHistorySection(List<SelfCheckResult> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 검사 기록',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildResultCard(result),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultCard(SelfCheckResult result) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: result.riskLevel.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  result.test.category.icon,
                  size: 24.sp,
                  color: result.riskLevel.color,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.test.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${result.completedAt.year}년 ${result.completedAt.month}월 ${result.completedAt.day}일',
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
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildResultInfo(
                Icons.assessment,
                '${result.percentage.toStringAsFixed(1)}%',
                result.riskLevel.color,
              ),
              SizedBox(width: 16.w),
              _buildResultInfo(
                Icons.warning,
                result.riskLevel.name,
                result.riskLevel.color,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  context.push(
                    '${AppRoutes.selfCheckResult}/${result.id}',
                    extra: {'result': result},
                  );
                },
                child: Text(
                  '상세보기',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
