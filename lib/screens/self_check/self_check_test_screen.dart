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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedAnswerId;
  bool _isAnswered = false;
  bool _isSubmitting = false;

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
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadTest() async {
    await ref.read(selfCheckProvider.notifier).loadTest(widget.testId);
    _checkCurrentAnswer();
  }

  void _checkCurrentAnswer() {
    final currentQuestion = ref.read(currentQuestionProvider);
    if (currentQuestion != null) {
      final existingAnswer = ref
          .read(selfCheckProvider.notifier)
          .getAnswerForQuestion(currentQuestion.id);

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
  }

  void _selectAnswer(SelfCheckAnswer answer) {
    setState(() {
      _selectedAnswerId = answer.id;
      _isAnswered = true;
    });

    final currentQuestion = ref.read(currentQuestionProvider);
    if (currentQuestion != null) {
      ref
          .read(selfCheckProvider.notifier)
          .answerQuestion(currentQuestion.id, answer.id, answer.score);
    }
  }

  Future<void> _goToNextQuestion() async {
    if (!_isAnswered) return;

    // 애니메이션 리셋
    await _fadeController.reverse();
    await _slideController.reverse();

    ref.read(selfCheckProvider.notifier).goToNextQuestion();
    _checkCurrentAnswer();

    // 애니메이션 재시작
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _goToPreviousQuestion() async {
    // 애니메이션 리셋
    await _fadeController.reverse();
    await _slideController.reverse();

    ref.read(selfCheckProvider.notifier).goToPreviousQuestion();
    _checkCurrentAnswer();

    // 애니메이션 재시작
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _completeTest() async {
    if (!ref.read(canCompleteTestProvider)) {
      _showIncompleteDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ref.read(selfCheckProvider.notifier).completeTest();

      if (mounted) {
        context.pushReplacement(
          AppRoutes.selfCheckResult,
          extra: {'resultId': result.id},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검사 완료 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showIncompleteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('검사 미완료'),
            content: const Text('모든 질문에 답변해야 검사를 완료할 수 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('검사 중단'),
            content: const Text('검사를 중단하시겠습니까?\n현재까지의 답변은 저장되지 않습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('계속하기'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(selfCheckProvider.notifier).cancelTest();
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
    final canGoNext = ref.watch(canGoToNextProvider);
    final canGoPrevious = ref.watch(canGoToPreviousProvider);
    final canComplete = ref.watch(canCompleteTestProvider);

    if (selfCheckState.isLoading || currentQuestion == null) {
      return const Scaffold(body: LoadingWidget());
    }

    if (selfCheckState.error != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: '자가진단'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
              SizedBox(height: 16.h),
              Text(
                '오류가 발생했습니다',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                selfCheckState.error!,
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
                  onPressed: _loadTest,
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

    return WillPopScope(
      onWillPop: () async {
        _showExitDialog();
        return false;
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

                          // === 질문 텍스트 ===
                          _buildQuestionText(currentQuestion.text),

                          SizedBox(height: 32.h),

                          // === 답변 옵션들 ===
                          _buildAnswerOptions(currentQuestion.answers),

                          SizedBox(height: 32.h),

                          // === 설명 텍스트 (선택적) ===
                          _buildAnswerDescription(currentQuestion.answerType),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // === 하단 네비게이션 ===
              _buildBottomNavigation(
                canGoPrevious: canGoPrevious,
                canGoNext: canGoNext,
                canComplete: canComplete,
                isAnswered: _isAnswered,
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
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '질문 $current / $total',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% 완료',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8.h,
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
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildQuestionText(String questionText) {
    return Text(
      questionText,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  Widget _buildAnswerOptions(List<SelfCheckAnswer> answers) {
    return Column(
      children:
          answers.map((answer) {
            final isSelected = _selectedAnswerId == answer.id;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectAnswer(answer),
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.grey300,
                        width: isSelected ? 2 : 1,
                      ),
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
                        // === 선택 인디케이터 ===
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.grey400,
                              width: 2,
                            ),
                          ),
                          child:
                              isSelected
                                  ? Icon(
                                    Icons.check,
                                    size: 14.w,
                                    color: AppColors.white,
                                  )
                                  : null,
                        ),

                        SizedBox(width: 16.w),

                        // === 답변 텍스트 ===
                        Expanded(
                          child: Text(
                            answer.text,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // === 점수 표시 (선택적) ===
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '${answer.score}점',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAnswerDescription(AnswerType answerType) {
    String description;
    switch (answerType) {
      case AnswerType.likert5:
        description = '5점 척도: 1점(전혀 그렇지 않다) ~ 5점(매우 그렇다)';
        break;
      case AnswerType.likert7:
        description = '7점 척도: 1점(매우 그렇지 않다) ~ 7점(매우 그렇다)';
        break;
      case AnswerType.yesNo:
        description = '예/아니오 중 선택해주세요';
        break;
      case AnswerType.multiple:
        description = '해당하는 항목을 선택해주세요';
        break;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20.w, color: AppColors.info),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 14.sp, color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation({
    required bool canGoPrevious,
    required bool canGoNext,
    required bool canComplete,
    required bool isAnswered,
  }) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // === 이전 버튼 ===
          if (canGoPrevious)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToPreviousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('이전'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: AppColors.grey200,
                  side: BorderSide(color: AppColors.grey300),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),

          if (canGoPrevious && (canGoNext || canComplete))
            SizedBox(width: 16.w),

          // === 다음/완료 버튼 ===
          Expanded(
            flex: canGoPrevious ? 1 : 2,
            child:
                canComplete
                    ? ElevatedButton.icon(
                      onPressed: isAnswered ? _completeTest : null,
                      icon:
                          _isSubmitting
                              ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.check_circle),
                      label: const Text('검사 완료'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    )
                    : ElevatedButton.icon(
                      onPressed: isAnswered ? _goToNextQuestion : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('다음'),
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
    );
  }
}
