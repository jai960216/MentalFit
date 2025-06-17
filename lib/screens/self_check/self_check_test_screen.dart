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
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  String? _selectedAnswerId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    Future.microtask(_initializeTest);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  /// 🔥 핵심 개선: 검사 초기화 로직 강화
  Future<void> _initializeTest() async {
    try {
      print('검사 초기화 시작: ${widget.testId}');
      await ref.read(selfCheckProvider.notifier).startTestById(widget.testId);

      // 상태 확인
      final state = ref.read(selfCheckProvider);
      if (state.error != null) {
        print('검사 로드 오류: ${state.error}');
        if (mounted) {
          _showErrorAndReturn('검사 데이터를 불러올 수 없습니다: ${state.error}');
          return;
        }
      }

      if (state.currentTest == null) {
        print('검사 데이터가 null입니다');
        if (mounted) {
          _showErrorAndReturn('검사 데이터를 찾을 수 없습니다');
          return;
        }
      }

      print('검사 초기화 성공: ${state.currentTest?.title}');
      _isInitialized = true;

      if (mounted) {
        _fadeController.forward();
        _progressController.forward();
      }
    } catch (e) {
      print('검사 초기화 예외: $e');
      if (mounted) {
        _showErrorAndReturn('검사를 시작할 수 없습니다: $e');
      }
    }
  }

  /// 🔥 새로 추가: 기본 검사 로드
  Future<void> _loadDefaultTest() async {
    try {
      // 사용 가능한 검사 목록을 먼저 로드
      await ref.read(selfCheckProvider.notifier).loadAvailableTests();

      final state = ref.read(selfCheckProvider);
      if (state.availableTests.isNotEmpty) {
        // 첫 번째 사용 가능한 검사로 시작
        final firstTest = state.availableTests.first;
        await ref.read(selfCheckProvider.notifier).startTest(firstTest);
        print('기본 검사 로드 성공: ${firstTest.title}');
      } else {
        throw Exception('사용 가능한 검사가 없습니다');
      }
    } catch (e) {
      print('기본 검사 로드 실패: $e');
      rethrow;
    }
  }

  void _showErrorAndReturn(String message) {
    GlobalErrorHandler.showErrorSnackBar(
      context,
      message,
      onRetry: () {
        _isInitialized = false;
        _initializeTest();
      },
    );

    // 3초 후 자동으로 이전 화면으로 이동
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _selectAnswer(SelfCheckAnswer answer) async {
    setState(() {
      _selectedAnswerId = answer.id;
    });

    // 답변 선택
    ref.read(selfCheckProvider.notifier).selectAnswer(answer);

    // 잠시 대기 후 다음 질문으로 이동
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _goToNextQuestion();
    }
  }

  Future<void> _goToNextQuestion() async {
    final hasNext = ref.read(selfCheckProvider.notifier).nextQuestion();

    if (hasNext) {
      // 애니메이션 리셋 후 재시작
      setState(() {
        _selectedAnswerId = null;
      });
      _fadeController.reset();
      _fadeController.forward();
    } else {
      // 마지막 질문 완료 - 결과 제출
      _submitTest();
    }
  }

  Future<void> _goToPreviousQuestion() async {
    final hasPrevious = ref.read(selfCheckProvider.notifier).previousQuestion();

    if (hasPrevious) {
      setState(() {
        _selectedAnswerId = null;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  Future<void> _submitTest() async {
    try {
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
                      Text('검사 결과를 분석하고 있습니다...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      final result = await ref.read(selfCheckProvider.notifier).submitTest();

      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        // 결과 화면으로 이동
        context.pushReplacement(
          '${AppRoutes.selfCheckResult}/${result.id}',
          extra: {'result': result},
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        GlobalErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: '검사 제출에 실패했습니다',
          onRetry: _submitTest,
        );
      }
    }
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

    // 초기화되지 않았거나 로딩 중인 경우
    if (!_isInitialized ||
        selfCheckState.isLoading ||
        currentQuestion == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(title: '자가진단 로딩 중...'),
        body: const LoadingWidget(),
      );
    }

    // 오류 상태
    if (selfCheckState.error != null) {
      return _buildErrorState(selfCheckState.error!);
    }

    // 현재 테스트가 없는 경우
    if (selfCheckState.currentTest == null) {
      return _buildErrorState('검사 데이터를 찾을 수 없습니다');
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentQuestion.category != null)
                          _buildQuestionCategory(currentQuestion.category!),
                        SizedBox(height: 16.h),
                        _buildQuestionText(currentQuestion),
                        SizedBox(height: 32.h),
                        _buildAnswerOptions(currentQuestion),
                        SizedBox(height: 40.h),
                      ],
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _isInitialized = false;
                      _initializeTest();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('다시 시도'),
                  ),
                  SizedBox(width: 16.w),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('돌아가기'),
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
      color: AppColors.white,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '질문 $current / $total',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: progress * _progressAnimation.value,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4.h,
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
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildQuestionText(SelfCheckQuestion question) {
    return Text(
      question.text,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  Widget _buildAnswerOptions(SelfCheckQuestion question) {
    return Column(
      children:
          question.answers.map((answer) {
            final isSelected = _selectedAnswerId == answer.id;
            final isCurrentAnswer =
                ref
                    .read(selfCheckProvider.notifier)
                    .getCurrentAnswer()
                    ?.answerId ==
                answer.id;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: InkWell(
                onTap: () => _selectAnswer(answer),
                borderRadius: BorderRadius.circular(12.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color:
                        isSelected || isCurrentAnswer
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.white,
                    border: Border.all(
                      color:
                          isSelected || isCurrentAnswer
                              ? AppColors.primary
                              : AppColors.border,
                      width: isSelected || isCurrentAnswer ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected || isCurrentAnswer
                                  ? AppColors.primary
                                  : AppColors.white,
                          border: Border.all(
                            color:
                                isSelected || isCurrentAnswer
                                    ? AppColors.primary
                                    : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child:
                            isSelected || isCurrentAnswer
                                ? Icon(
                                  Icons.check,
                                  size: 16.sp,
                                  color: AppColors.white,
                                )
                                : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          answer.text,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight:
                                isSelected || isCurrentAnswer
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                            color:
                                isSelected || isCurrentAnswer
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (question.answerType == AnswerType.likert5 ||
                          question.answerType == AnswerType.likert7)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected || isCurrentAnswer
                                    ? AppColors.primary
                                    : AppColors.surface,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${answer.score}점',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected || isCurrentAnswer
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBottomNavigation(bool canGoPrevious) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(16.w),
      child: SafeArea(
        child: Row(
          children: [
            if (canGoPrevious) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToPreviousQuestion,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('이전'),
                ),
              ),
              SizedBox(width: 16.w),
            ],
            Expanded(
              flex: canGoPrevious ? 1 : 2,
              child: Consumer(
                builder: (context, ref, child) {
                  final notifier = ref.watch(selfCheckProvider.notifier);
                  final hasAnswer = notifier.isCurrentQuestionAnswered();
                  final hasNext = notifier.hasNextQuestion();

                  return ElevatedButton(
                    onPressed:
                        hasAnswer
                            ? () {
                              if (hasNext) {
                                _goToNextQuestion();
                              } else {
                                _submitTest();
                              }
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      disabledBackgroundColor: AppColors.surface,
                      disabledForegroundColor: AppColors.textSecondary,
                    ),
                    child: Text(hasNext ? '다음' : '완료'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
