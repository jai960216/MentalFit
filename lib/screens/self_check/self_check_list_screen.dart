import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/theme_aware_widgets.dart';
import '../../providers/self_check_provider.dart';
import '../../shared/models/self_check_models.dart';

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    Future.microtask(() => _loadSelfCheckTests());
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  Future<void> _loadSelfCheckTests() async {
    try {
      await ref.read(selfCheckProvider.notifier).loadAvailableTests();
    } catch (e) {
      debugPrint('자가진단 테스트 로딩 오류: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selfCheckState = ref.watch(selfCheckProvider);
    final availableTests = selfCheckState.availableTests;
    final isLoading = selfCheckState.isLoading;

    return ThemedScaffold(
      appBar: const CustomAppBar(title: '자가진단'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child:
            isLoading
                ? const LoadingWidget()
                : SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === 헤더 섹션 ===
                      _buildHeaderSection(),

                      SizedBox(height: 24.h),

                      // === 최근 결과 섹션 ===
                      _buildRecentResultsSection(),

                      SizedBox(height: 24.h),

                      // === 사용 가능한 테스트 섹션 ===
                      _buildAvailableTestsSection(availableTests),

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return ThemedCard(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemedText(
                      text: '마음 건강 체크',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    ThemedText(
                      text: '정기적인 자가진단으로 마음 상태를 확인해보세요',
                      isPrimary: false,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 진단 기록 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.selfCheckHistory),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.history, color: AppColors.primary, size: 18.sp),
              label: Text(
                '진단 기록 보기',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResultsSection() {
    final recentResults = ref.watch(selfCheckProvider).recentResults;

    if (recentResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedText(
          text: '최근 진단 결과',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),

        SizedBox(height: 12.h),

        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentResults.take(3).length,
            itemBuilder: (context, index) {
              final result = recentResults[index];
              return _buildRecentResultCard(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentResultCard(SelfCheckResult result) {
    return SizedBox(
      width: 150.w,
      child: ThemedCard(
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.all(16.w),
        onTap: () {
          context.push('${AppRoutes.selfCheckResult}/${result.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTestIcon(result.test.type),
                  color: _getScoreColor(result.totalScore),
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ThemedText(
                    text: result.test.type.code,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ThemedText(
              text: '${result.totalScore}/${result.maxScore}',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            ThemedText(
              text: _formatDate(result.completedAt),
              isPrimary: false,
              style: TextStyle(fontSize: 10.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTestsSection(List<SelfCheckTest> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedText(
          text: '사용 가능한 진단',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),

        SizedBox(height: 12.h),

        ...tests.map((test) => _buildTestCard(test)),
      ],
    );
  }

  Widget _buildTestCard(SelfCheckTest test) {
    return ThemedCard(
      margin: EdgeInsets.only(bottom: 12.h),
      onTap: () => _startTest(test),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            // 테스트 아이콘
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: _getTestColor(test.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _getTestIcon(test.type),
                color: _getTestColor(test.type),
                size: 24.sp,
              ),
            ),

            SizedBox(width: 16.w),

            // 테스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemedText(
                    text: test.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  ThemedText(
                    text: test.description,
                    isPrimary: false,
                    style: TextStyle(fontSize: 14.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8.h),

                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      SizedBox(width: 4.w),
                      ThemedText(
                        text: '약 ${test.estimatedMinutes}분',
                        isPrimary: false,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      SizedBox(width: 16.w),
                      Icon(
                        Icons.quiz_outlined,
                        size: 14.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      SizedBox(width: 4.w),
                      ThemedText(
                        text: '${test.questionCount}문항',
                        isPrimary: false,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 시작 버튼
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '시작',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTest(SelfCheckTest test) {
    context.push('${AppRoutes.selfCheckTest}/${test.id}');
  }

  // === 헬퍼 메서드들 ===

  IconData _getTestIcon(SelfCheckTestType type) {
    switch (type) {
      case SelfCheckTestType.tops2:
        return Icons.trending_up;
      case SelfCheckTestType.csai2:
        return Icons.psychology;
      case SelfCheckTestType.psis:
        return Icons.sports;
      case SelfCheckTestType.msci:
        return Icons.emoji_events;
      case SelfCheckTestType.smq:
        return Icons.energy_savings_leaf;
      default:
        return Icons.quiz;
    }
  }

  Color _getTestColor(SelfCheckTestType type) {
    switch (type) {
      case SelfCheckTestType.tops2:
        return AppColors.primary;
      case SelfCheckTestType.csai2:
        return AppColors.warning;
      case SelfCheckTestType.psis:
        return AppColors.info;
      case SelfCheckTestType.msci:
        return AppColors.success;
      case SelfCheckTestType.smq:
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  String _getTestName(SelfCheckTestType type) {
    switch (type) {
      case SelfCheckTestType.tops2:
        return '수행 전략';
      case SelfCheckTestType.csai2:
        return '경쟁 상태 불안';
      case SelfCheckTestType.psis:
        return '스포츠 심리 기술';
      case SelfCheckTestType.msci:
        return '경쟁 심리 기술';
      case SelfCheckTestType.smq:
        return '스포츠 동기';
      default:
        return '심리 체크';
    }
  }

  Color _getScoreColor(int score) {
    if (score < 30) return AppColors.success;
    if (score < 60) return AppColors.warning;
    return AppColors.error;
  }

  String _getScoreLevel(int score) {
    if (score < 30) return '양호';
    if (score < 60) return '주의';
    return '위험';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
