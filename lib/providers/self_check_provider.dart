import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/self_check_models.dart';
import '../shared/services/self_check_service.dart';

// === 자가진단 서비스 프로바이더 ===
final selfCheckServiceProvider = Provider<SelfCheckService>((ref) {
  // SelfCheckService는 싱글톤이므로 getInstance() 사용
  throw UnimplementedError('Use selfCheckServiceFutureProvider instead');
});

// 비동기 서비스 프로바이더
final selfCheckServiceFutureProvider = FutureProvider<SelfCheckService>((ref) {
  return SelfCheckService.getInstance();
});

// === 자가진단 상태 프로바이더 ===
final selfCheckProvider =
    StateNotifierProvider<SelfCheckNotifier, SelfCheckState>((ref) {
      return SelfCheckNotifier();
    });

// === 편의용 프로바이더들 ===
final currentQuestionProvider = Provider<SelfCheckQuestion?>((ref) {
  final state = ref.watch(selfCheckProvider);
  if (state.currentTest == null ||
      state.currentQuestionIndex >= state.currentTest!.questions.length) {
    return null;
  }
  return state.currentTest!.questions[state.currentQuestionIndex];
});

final currentQuestionNumberProvider = Provider<int>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.currentQuestionIndex + 1;
});

final totalQuestionsProvider = Provider<int>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.currentTest?.questions.length ?? 0;
});

final testProgressProvider = Provider<double>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.testProgress;
});

final canGoToPreviousProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.currentQuestionIndex > 0;
});

// 🔥 SelfCheckTestScreen에서 필요한 추가 프로바이더들
final canGoToNextProvider = Provider<bool>((ref) {
  final notifier = ref.watch(selfCheckProvider.notifier);
  return notifier.hasNextQuestion();
});

final currentQuestionAnsweredProvider = Provider<bool>((ref) {
  final notifier = ref.watch(selfCheckProvider.notifier);
  return notifier.isCurrentQuestionAnswered();
});

final currentAnswerProvider = Provider<UserAnswer?>((ref) {
  final notifier = ref.watch(selfCheckProvider.notifier);
  return notifier.getCurrentAnswer();
});

final testLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.isLoading;
});

final testErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.error;
});

final hasCurrentTestProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.hasCurrentTest;
});

final testInProgressProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.isTestInProgress;
});

final testCompletedProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.isTestCompleted;
});

// === 자가진단 상태 관리 클래스 ===
class SelfCheckNotifier extends StateNotifier<SelfCheckState> {
  SelfCheckService? _service;

  SelfCheckNotifier() : super(const SelfCheckState()) {
    _initializeService();
  }

  // 서비스 초기화
  Future<void> _initializeService() async {
    try {
      _service = await SelfCheckService.getInstance();
      debugPrint('SelfCheckNotifier: 서비스 초기화 완료');
    } catch (e) {
      debugPrint('SelfCheckNotifier: 서비스 초기화 오류: $e');
    }
  }

  // 서비스 가져오기 (초기화되지 않았으면 초기화)
  Future<SelfCheckService> _getService() async {
    if (_service == null) {
      debugPrint('SelfCheckNotifier: 서비스 재초기화');
      _service = await SelfCheckService.getInstance();
    }
    return _service!;
  }

  // === 데이터 로딩 ===

  /// 사용 가능한 검사 목록 로드
  Future<void> loadAvailableTests() async {
    debugPrint('SelfCheckNotifier: 검사 목록 로드 시작');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = await _getService();
      final tests = await service.getAvailableTests();
      final recommended = await service.getRecommendedTests();
      final recent = await service.getRecentResults(limit: 3);

      debugPrint('SelfCheckNotifier: 검사 목록 로드 완료 - ${tests.length}개');

      state = state.copyWith(
        availableTests: tests,
        recommendedTests: recommended,
        recentResults: recent,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('SelfCheckNotifier: 검사 목록 로드 오류: $e');
      state = state.copyWith(
        isLoading: false,
        error: '검사 목록을 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 특정 검사 정보 로드 - 🔥 핵심 개선
  Future<void> loadTest(String testId) async {
    debugPrint('SelfCheckNotifier: 검사 로드 시작 - $testId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = await _getService();
      final test = await service.getAvailableTests().firstWhere(
        (t) => t.id == testId,
        orElse: () => throw Exception('검사를 찾을 수 없습니다: $testId'),
      );
      debugPrint('SelfCheckNotifier: 검사 로드 성공 - ${test.title}');
      state = state.copyWith(
        currentTest: test,
        currentAnswers: [],
        currentQuestionIndex: 0,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('SelfCheckNotifier: 검사 로드 오류: $e');
      state = state.copyWith(isLoading: false, error: '검사 데이터를 불러올 수 없습니다: $e');
    }
  }

  /// 🔥 추가: 검사 시작 메서드
  Future<void> startTest(SelfCheckTest test) async {
    debugPrint('SelfCheckNotifier: 검사 시작 - ${test.id}');

    try {
      state = state.copyWith(
        currentTest: test,
        currentAnswers: [],
        currentQuestionIndex: 0,
        isLoading: false,
        error: null,
      );

      debugPrint('SelfCheckNotifier: 검사 시작 완료');
    } catch (e) {
      debugPrint('SelfCheckNotifier: 검사 시작 오류: $e');
      state = state.copyWith(error: '검사를 시작할 수 없습니다: $e');
    }
  }

  /// 🔥 추가: 검사 시작 (testId로)
  Future<void> startTestById(String testId) async {
    debugPrint('SelfCheckNotifier: ID로 검사 시작 - $testId');

    // 먼저 검사 데이터 로드
    await loadTest(testId);

    // 로드 후 현재 상태 확인
    if (state.currentTest != null && state.error == null) {
      debugPrint('SelfCheckNotifier: 검사 시작 준비 완료');
      // 이미 loadTest에서 상태가 설정되므로 추가 작업 불필요
    } else {
      debugPrint('SelfCheckNotifier: 검사 시작 실패 - ${state.error}');
    }
  }

  /// 답변 선택
  void selectAnswer(SelfCheckAnswer answer) {
    if (state.currentTest == null) {
      debugPrint('SelfCheckNotifier: 현재 검사가 없어 답변 선택 불가');
      return;
    }

    final currentQuestion =
        state.currentTest!.questions[state.currentQuestionIndex];
    final userAnswer = UserAnswer(
      questionId: currentQuestion.id,
      answerId: answer.id,
      score: answer.score,
      answeredAt: DateTime.now(),
    );

    final updatedAnswers = List<UserAnswer>.from(state.currentAnswers);

    // 기존 답변이 있으면 교체, 없으면 추가
    final existingIndex = updatedAnswers.indexWhere(
      (ans) => ans.questionId == currentQuestion.id,
    );

    if (existingIndex != -1) {
      updatedAnswers[existingIndex] = userAnswer;
      debugPrint('SelfCheckNotifier: 답변 수정 - ${currentQuestion.id}');
    } else {
      updatedAnswers.add(userAnswer);
      debugPrint('SelfCheckNotifier: 답변 추가 - ${currentQuestion.id}');
    }

    state = state.copyWith(currentAnswers: updatedAnswers);
  }

  /// 현재 질문의 답변 가져오기
  UserAnswer? getCurrentAnswer() {
    if (state.currentTest == null) return null;

    final currentQuestion =
        state.currentTest!.questions[state.currentQuestionIndex];
    return state.currentAnswers.cast<UserAnswer?>().firstWhere(
      (answer) => answer?.questionId == currentQuestion.id,
      orElse: () => null,
    );
  }

  /// 다음 질문으로 이동
  bool nextQuestion() {
    if (state.currentTest == null) return false;

    final nextIndex = state.currentQuestionIndex + 1;
    if (nextIndex < state.currentTest!.questions.length) {
      state = state.copyWith(currentQuestionIndex: nextIndex);
      debugPrint('SelfCheckNotifier: 다음 질문으로 이동 - $nextIndex');
      return true;
    }

    debugPrint('SelfCheckNotifier: 마지막 질문에 도달');
    return false;
  }

  /// 이전 질문으로 이동
  bool previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      final prevIndex = state.currentQuestionIndex - 1;
      state = state.copyWith(currentQuestionIndex: prevIndex);
      debugPrint('SelfCheckNotifier: 이전 질문으로 이동 - $prevIndex');
      return true;
    }

    debugPrint('SelfCheckNotifier: 첫 번째 질문에 도달');
    return false;
  }

  /// 특정 질문으로 이동
  void goToQuestion(int questionIndex) {
    if (state.currentTest == null) return;

    if (questionIndex >= 0 &&
        questionIndex < state.currentTest!.questions.length) {
      state = state.copyWith(currentQuestionIndex: questionIndex);
      debugPrint('SelfCheckNotifier: 질문 $questionIndex로 이동');
    }
  }

  /// 검사 완료 확인
  bool isTestCompleted() {
    if (state.currentTest == null) return false;

    final totalQuestions = state.currentTest!.questions.length;
    final answeredQuestions = state.currentAnswers.length;

    debugPrint('SelfCheckNotifier: 진행 상황 - $answeredQuestions/$totalQuestions');
    return answeredQuestions == totalQuestions;
  }

  /// 검사 제출
  Future<SelfCheckResult> submitTest() async {
    if (state.currentTest == null) {
      throw Exception('현재 진행 중인 검사가 없습니다');
    }

    if (!isTestCompleted()) {
      throw Exception('모든 질문에 답변해주세요');
    }

    debugPrint('SelfCheckNotifier: 검사 제출 시작');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = await _getService();
      final result = await service.submitTest(
        testId: state.currentTest!.id,
        answers: state.currentAnswers,
      );

      debugPrint('SelfCheckNotifier: 검사 제출 완료 - ${result.id}');

      // 제출 후 상태 정리
      state = state.copyWith(
        isLoading: false,
        currentTest: null,
        currentAnswers: [],
        currentQuestionIndex: 0,
      );

      return result;
    } catch (e) {
      debugPrint('SelfCheckNotifier: 검사 제출 오류: $e');
      state = state.copyWith(isLoading: false, error: '검사 제출에 실패했습니다: $e');
      rethrow;
    }
  }

  /// 현재 검사 초기화
  void resetCurrentTest() {
    debugPrint('SelfCheckNotifier: 현재 검사 초기화');
    state = state.copyWith(
      currentTest: null,
      currentAnswers: [],
      currentQuestionIndex: 0,
      error: null,
    );
  }

  /// 전체 상태 초기화
  void reset() {
    debugPrint('SelfCheckNotifier: 전체 상태 초기화');
    state = const SelfCheckState();
  }

  /// 오류 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 특정 검사 결과 상세 조회
  Future<SelfCheckResult?> getResultDetail(String resultId) async {
    try {
      final service = await _getService();
      final allResults = await service.getRecentResults(limit: 100);
      final result = allResults.cast<SelfCheckResult?>().firstWhere(
        (result) => result?.id == resultId,
        orElse: () => null,
      );

      if (result != null) {
        debugPrint('SelfCheckNotifier: 결과 상세 조회 성공 - ${result.id}');
      } else {
        debugPrint('SelfCheckNotifier: 결과를 찾을 수 없음 - $resultId');
      }

      return result;
    } catch (e) {
      debugPrint('SelfCheckNotifier: 결과 상세 조회 오류: $e');
      return null;
    }
  }

  /// 특정 검사 결과 조회
  Future<List<SelfCheckResult>> getTestResults(String testId) async {
    try {
      final service = await _getService();
      final allResults = await service.getRecentResults(limit: 100);
      return allResults.where((result) => result.test.id == testId).toList();
    } catch (e) {
      debugPrint('SelfCheckNotifier: 검사 결과 조회 오류: $e');
      return [];
    }
  }

  /// 진행률 계산
  double getProgress() {
    return state.testProgress;
  }

  /// 현재 질문 번호 (1부터 시작)
  int getCurrentQuestionNumber() {
    return state.currentQuestionIndex + 1;
  }

  /// 전체 질문 수
  int getTotalQuestions() {
    return state.currentTest?.questions.length ?? 0;
  }

  /// 다음 질문 존재 여부
  bool hasNextQuestion() {
    if (state.currentTest == null) return false;
    return state.currentQuestionIndex < state.currentTest!.questions.length - 1;
  }

  /// 이전 질문 존재 여부
  bool hasPreviousQuestion() {
    return state.currentQuestionIndex > 0;
  }

  /// 현재 질문의 답변 여부
  bool isCurrentQuestionAnswered() {
    if (state.currentTest == null) return false;

    final currentQuestion =
        state.currentTest!.questions[state.currentQuestionIndex];
    return state.currentAnswers.any(
      (answer) => answer.questionId == currentQuestion.id,
    );
  }

  /// 필수 질문들의 답변 완료 여부
  bool areRequiredQuestionsAnswered() {
    if (state.currentTest == null) return false;

    final requiredQuestions =
        state.currentTest!.questions.where((q) => q.isRequired).toList();

    for (final question in requiredQuestions) {
      final hasAnswer = state.currentAnswers.any(
        (answer) => answer.questionId == question.id,
      );
      if (!hasAnswer) return false;
    }

    return true;
  }

  Future<void> loadRecentResults() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = await _getService();
      final results = await service.getRecentResults(limit: 20);
      state = state.copyWith(
        recentResults: results,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '결과를 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }
}
