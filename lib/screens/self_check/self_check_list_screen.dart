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

class SelfCheckListScreen extends ConsumerStatefulWidget {
  const SelfCheckListScreen({super.key});

  @override
  ConsumerState<SelfCheckListScreen> createState() =>
      _SelfCheckListScreenState();
}

class _SelfCheckListScreenState extends ConsumerState<SelfCheckListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(selfCheckProvider.notifier).loadAvailableTests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startTest(SelfCheckTest test) {
    context.push(
      AppRoutes.selfCheckTest,
      extra: {'testId': test.id, 'testType': test.type},
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
      body:
          _isLoading
              ? const LoadingWidget()
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === 헤더 섹션 ===
                      _buildHeader(),

                      SizedBox(height: 32.h),

                      // === 추천 검사 섹션 ===
                      _buildRecommendedSection(selfCheckState.recommendedTests),

                      SizedBox(height: 32.h),

                      // === 전체 검사 목록 ===
                      _buildAllTestsSection(selfCheckState.availableTests),

                      SizedBox(height: 32.h),

                      // === 최근 검사 기록 ===
                      _buildRecentHistorySection(selfCheckState.recentResults),
                    ],
                  ),
                ),
              ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '심리 상태를 체크해보세요',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '정확한 자가진단을 통해 현재 상태를 파악하고\n맞춤형 상담을 받아보세요.',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection(List<SelfCheckTest> recommendedTests) {
    if (recommendedTests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, color: AppColors.warning, size: 20.w),
            SizedBox(width: 8.w),
            Text(
              '추천 검사',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...recommendedTests
            .map(
              (test) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildTestCard(test, isRecommended: true),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildAllTestsSection(List<SelfCheckTest> allTests) {
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
        ...allTests
            .map(
              (test) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildTestCard(test),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildTestCard(SelfCheckTest test, {bool isRecommended = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border:
            isRecommended
                ? Border.all(color: AppColors.warning, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startTest(test),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 상단 정보 ===
                Row(
                  children: [
                    // 아이콘
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: test.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        test.category.icon,
                        color: test.category.color,
                        size: 24.w,
                      ),
                    ),

                    SizedBox(width: 16.w),

                    // 제목과 카테고리
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                test.title,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (isRecommended) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '추천',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            test.category.name,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 소요시간
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${test.estimatedMinutes}분',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '소요',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // === 설명 ===
                Text(
                  test.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 16.h),

                // === 하단 정보 ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 질문 수
                    Row(
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 16.w,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${test.questionCount}문항',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // 시작 버튼
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '시작하기',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12.w,
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
        ),
      ),
    );
  }

  Widget _buildRecentHistorySection(List<SelfCheckResult> recentResults) {
    if (recentResults.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 검사 기록',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: 전체 기록 화면으로 이동
                context.push(AppRoutes.recordsList);
              },
              child: Text(
                '전체보기',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...recentResults
            .take(3)
            .map(
              (result) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildHistoryCard(result),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildHistoryCard(SelfCheckResult result) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: result.test.category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              result.test.category.icon,
              color: result.test.category.color,
              size: 20.w,
            ),
          ),

          SizedBox(width: 12.w),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.test.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${result.completedAt.month}/${result.completedAt.day} 완료',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 점수
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.totalScore}점',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: result.riskLevel.color,
                ),
              ),
              Text(
                result.riskLevel.name,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: result.riskLevel.color,
                ),
              ),
            ],
          ),

          SizedBox(width: 8.w),

          Icon(
            Icons.arrow_forward_ios,
            size: 16.w,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
