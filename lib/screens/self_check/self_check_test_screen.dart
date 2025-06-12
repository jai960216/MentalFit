import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/self_check_models.dart';
import '../../providers/self_check_provider.dart';

class SelfCheckTestScreen extends ConsumerStatefulWidget {
  final String testId;
  final SelfCheckTestType? testType;

  const SelfCheckTestScreen({super.key, required this.testId, this.testType});

  @override
  ConsumerState<SelfCheckTestScreen> createState() =>
      _SelfCheckTestScreenState();
}

class _SelfCheckTestScreenState extends ConsumerState<SelfCheckTestScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  String? _selectedAnswerId;
  bool _isAnswered = false;
  bool _isSubmitting = false;
  bool _hasShownErrorToast = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTest();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _progressController.forward();
  }

  Future<void> _loadTest() async {
    try {
      await ref.read(selfCheckProvider.notifier).loadTest(widget.testId);
      _checkCurrentAnswer();
      _hasShownErrorToast = false; // 에러 토스트 초기화
    } catch (e) {
      if (mounted && !_hasShownErrorToast) {
        _hasShownErrorToast = true;
        GlobalErrorHandler.showErrorSnackBar(
          context,
          e,
          onRetry: _loadTest,
          customMessage: '검사 데이터를 불러올 수 없습니다.',
        );
      }
    }
  }

  void _checkCurrentAnswer() {
    final currentQuestion = ref.read(currentQuestionProvider);
    if (currentQuestion == null) return;

    final answers = ref.read(selfCheckProvider).currentAnswers;
    final existingAnswer =
        answers
            .where((answer) => answer.questionId == currentQuestion.id)
            .firstOrNull;

    if (existingAnswer != null) {
      setState(() {
        _selectedAnswerId = existingAnswer.answerId;
        _isAnswered = true;
      });
    } else {
      setState(() {
        _selectedAnswerId = null;
        _isAnswered = false;
      });
    }
  }

  void _selectAnswer(String answerId, int score) {
    setState(() {
      _selectedAnswerId = answerId;
      _isAnswered = true;
    });

    final currentQuestion = ref.read(currentQuestionProvider);
    if (currentQuestion != null) {
      ref
          .read(selfCheckProvider.notifier)
          .answerQuestion(currentQuestion.id, answerId, score);
    }

    // 자동으로 다음 질문으로 이동 (약간의 지연)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _goToNextQuestion();
      }
    });
  }

  Future<void> _goToNextQuestion() async {
    try {
      final canGoNext = ref.read(canGoToNextProvider);
      final canComplete = ref.read(canCompleteTestProvider);

      if (canComplete) {
        await _completeTest();
      } else if (canGoNext) {
        // 슬라이드 애니메이션 리셋 후 다시 재생
        await _slideController.reverse();
        ref.read(selfCheckProvider.notifier).goToNextQuestion();
        _checkCurrentAnswer();
        await _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: '다음 질문으로 이동할 수 없습니다.',
        );
      }
    }
  }

  Future<void> _goToPreviousQuestion() async {
    try {
      final canGoPrevious = ref.read(canGoToPreviousProvider);
      if (canGoPrevious) {
        await _slideController.reverse();
        ref.read(selfCheckProvider.notifier).goToPreviousQuestion();
        _checkCurrentAnswer();
        await _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: '이전 질문으로 이동할 수 없습니다.',
        );
      }
    }
  }

  Future<void> _completeTest() async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);

      // 로딩 다이얼로그 표시
      _showCompletionDialog();

      final result = await ref.read(selfCheckProvider.notifier).completeTest();

      if (mounted) {
        // 로딩 다이얼로그 닫기
        Navigator.of(context).pop();

        // 결과 페이지로 이동
        context.pushReplacement(
          '${AppRoutes.selfCheckResult}/${result.id}',
          extra: {'result': result},
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        // 로딩 다이얼로그가 열려있다면 닫기
        Navigator.of(context).pop();

        GlobalErrorHandler.showErrorDialog(
          context,
          e,
          customMessage: '검사 완료 처리 중 오류가 발생했습니다.',
          onRetry: _completeTest,
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text(
                    '검사 결과를 분석하고 있습니다...',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: AppColors.warning,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                const Text('검사 중단'),
              ],
            ),
            content: const Text(
              '검사를 중단하시겠습니까?\n\n현재까지의 답변은 저장되지 않으며,\n처음부터 다시 시작해야 합니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('계속하기', style: TextStyle(color: AppColors.primary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(selfCheckProvider.notifier).resetCurrentTest();
                  context.pop();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('중단하기'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selfCheckState = ref.watch(selfCheckProvider);
    final currentQuestion = ref.watch(currentQuestionProvider);
    final currentQuestionNumber = ref.watch(currentQuestionNumberProvider);
    final totalQuestions = ref.watch(totalQuestionsProvider);
    final progress = ref.watch(testProgressProvider);
    final canGoPrevious = ref.watch(canGoToPreviousProvider);

    if (selfCheckState.isLoading || currentQuestion == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(title: '자가진단 로딩 중...'),
        body: const LoadingWidget(),
      );
    }

    if (selfCheckState.error != null) {
      return _buildErrorState(selfCheckState.error!);
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: selfCheckState.currentTest?.title ?? '자가진단',
          backgroundColor: AppColors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitDialog,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // === 진행률 표시 ===
              _buildProgressSection(
                progress,
                currentQuestionNumber,
                totalQuestions,
              ),

              // === 질문 영역 ===
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
                          // === 질문 카테고리 ===
                          if (currentQuestion.category != null)
                            _buildQuestionCategory(currentQuestion.category!),

                          SizedBox(height: 16.h),

                          // === 질문 내용 ===
                          _buildQuestionText(currentQuestion),

                          SizedBox(height: 32.h),

                          // === 답변 옵션들 ===
                          _buildAnswerOptions(currentQuestion),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // === 하단 네비게이션 ===
              _buildBottomNavigation(canGoPrevious),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '자가진단'),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
              SizedBox(height: 16.h),
              Text(
                '검사를 불러올 수 없습니다',
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
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.grey300),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('돌아가기'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(double progress, int current, int total) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '질문 $current / $total',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% 완료',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: progress * _progressAnimation.value,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6.h,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCategory(String category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildQuestionText(SelfCheckQuestion question) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
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
      child: Text(
        question.text,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(SelfCheckQuestion question) {
    return Column(
      children:
          question.answers.map((answer) {
            final isSelected = _selectedAnswerId == answer.id;
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildAnswerOption(answer, isSelected),
            );
          }).toList(),
    );
  }

  Widget _buildAnswerOption(SelfCheckAnswer answer, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(answer.id, answer.score),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Icon(Icons.check, size: 12.sp, color: AppColors.white)
                      : null,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                answer.text,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool canGoPrevious) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canGoPrevious) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousQuestion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.grey300),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 16.sp),
                    SizedBox(width: 8.w),
                    const Text('이전'),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
          ],
          Expanded(
            flex: canGoPrevious ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isAnswered ? _goToNextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isAnswered ? AppColors.primary : AppColors.grey300,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ref.watch(canCompleteTestProvider) ? '완료' : '다음',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    ref.watch(canCompleteTestProvider)
                        ? Icons.check
                        : Icons.arrow_forward,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
