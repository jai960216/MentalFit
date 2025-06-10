import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/self_check_models.dart';
import '../shared/services/self_check_service.dart';

// === 자가진단 서비스 프로바이더 ===
final selfCheckServiceProvider = Provider<SelfCheckService>((ref) {
  return SelfCheckService();
});

// === 자가진단 상태 프로바이더 ===
final selfCheckProvider =
    StateNotifierProvider<SelfCheckNotifier, SelfCheckState>((ref) {
      return SelfCheckNotifier(ref.watch(selfCheckServiceProvider));
    });

// === 자가진단 상태 관리 클래스 ===
class SelfCheckNotifier extends StateNotifier<SelfCheckState> {
  final SelfCheckService _service;

  SelfCheckNotifier(this._service) : super(const SelfCheckState());

  // === 데이터 로딩 ===

  /// 사용 가능한 검사 목록 로드
  Future<void> loadAvailableTests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tests = await _service.getAvailableTests();
      final recommended = await _service.getRecommendedTests();
      final recent = await _service.getRecentResults(limit: 3);

      state = state.copyWith(
        availableTests: tests,
        recommendedTests: recommended,
        recentResults: recent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '검사 목록을 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 특정 검사 정보 로드
  Future<void> loadTest(String testId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final test = await _service.getTestById(testId);
      state = state.copyWith(
        currentTest: test,
        currentAnswers: [],
        currentQuestionIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '검사 정보를 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 최근 검사 결과 로드
  Future<void> loadRecentResults({int limit = 10}) async {
    try {
      final results = await _service.getRecentResults(limit: limit);
      state = state.copyWith(recentResults: results);
    } catch (e) {
      state = state.copyWith(error: '최근 검사 결과를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // === 검사 진행 ===

  /// 검사 시작
  void startTest(SelfCheckTest test) {
    state = state.copyWith(
      currentTest: test,
      currentAnswers: [],
      currentQuestionIndex: 0,
      error: null,
    );
  }

  /// 답변 저장
  void answerQuestion(String questionId, String answerId, int score) {
    if (!state.hasCurrentTest) return;

    final answer = UserAnswer(
      questionId: questionId,
      answerId: answerId,
      score: score,
      answeredAt: DateTime.now(),
    );

    // 기존 답변 제거 (같은 질문에 대한)
    final updatedAnswers =
        state.currentAnswers.where((a) => a.questionId != questionId).toList();

    updatedAnswers.add(answer);

    state = state.copyWith(currentAnswers: updatedAnswers);
  }

  /// 다음 질문으로 이동
  void goToNextQuestion() {
    if (!state.canGoToNextQuestion) return;

    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
  }

  /// 이전 질문으로 이동
  void goToPreviousQuestion() {
    if (!state.canGoToPreviousQuestion) return;

    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex - 1,
    );
  }

  /// 특정 질문으로 이동
  void goToQuestion(int index) {
    if (!state.hasCurrentTest) return;
    if (index < 0 || index >= state.currentTest!.questions.length) return;

    state = state.copyWith(currentQuestionIndex: index);
  }

  /// 검사 완료 및 결과 저장
  Future<SelfCheckResult> completeTest() async {
    if (!state.isTestCompleted) {
      throw Exception('모든 질문에 답변해주세요.');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.submitTestResult(
        testId: state.currentTest!.id,
        answers: state.currentAnswers,
      );

      // 상태 초기화
      state = state.copyWith(
        currentTest: null,
        currentAnswers: [],
        currentQuestionIndex: 0,
        isLoading: false,
      );

      // 최근 결과 목록 갱신
      await loadRecentResults(limit: 3);

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '검사 결과 저장 중 오류가 발생했습니다: $e',
      );
      rethrow;
    }
  }

  /// 검사 중단
  void cancelTest() {
    state = state.copyWith(
      currentTest: null,
      currentAnswers: [],
      currentQuestionIndex: 0,
      error: null,
    );
  }

  /// 답변 수정 (이전 질문으로 돌아갈 때)
  void updateAnswer(String questionId, String answerId, int score) {
    final updatedAnswers =
        state.currentAnswers.map((answer) {
          if (answer.questionId == questionId) {
            return answer.copyWith(
              answerId: answerId,
              score: score,
              answeredAt: DateTime.now(),
            );
          }
          return answer;
        }).toList();

    state = state.copyWith(currentAnswers: updatedAnswers);
  }

  /// 특정 질문의 답변 가져오기
  UserAnswer? getAnswerForQuestion(String questionId) {
    try {
      return state.currentAnswers.firstWhere(
        (answer) => answer.questionId == questionId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 현재 진행률 계산
  double getCurrentProgress() {
    return state.testProgress;
  }

  /// 답변된 질문 수
  int getAnsweredQuestionsCount() {
    return state.currentAnswers.length;
  }

  /// 미답변 질문 수
  int getUnansweredQuestionsCount() {
    if (!state.hasCurrentTest) return 0;
    return state.currentTest!.questions.length - state.currentAnswers.length;
  }

  // === 검사 결과 관리 ===

  /// 검사 결과 상세 조회
  Future<SelfCheckResult> getResultDetail(String resultId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.getResultById(resultId);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '검사 결과를 불러오는 중 오류가 발생했습니다: $e',
      );
      rethrow;
    }
  }

  /// 검사 결과 목록 조회
  Future<List<SelfCheckResult>> getResultHistory({
    int page = 1,
    int limit = 20,
    SelfCheckTestType? testType,
  }) async {
    try {
      return await _service.getResultHistory(
        page: page,
        limit: limit,
        testType: testType,
      );
    } catch (e) {
      state = state.copyWith(error: '검사 기록을 불러오는 중 오류가 발생했습니다: $e');
      rethrow;
    }
  }

  /// 검사 결과 삭제
  Future<void> deleteResult(String resultId) async {
    try {
      await _service.deleteResult(resultId);

      // 최근 결과 목록에서 제거
      final updatedResults =
          state.recentResults.where((result) => result.id != resultId).toList();

      state = state.copyWith(recentResults: updatedResults);
    } catch (e) {
      state = state.copyWith(error: '검사 결과 삭제 중 오류가 발생했습니다: $e');
      rethrow;
    }
  }

  // === 상태 초기화 ===

  /// 에러 상태 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 전체 상태 초기화
  void reset() {
    state = const SelfCheckState();
  }

  /// 현재 검사만 초기화
  void resetCurrentTest() {
    state = state.copyWith(
      currentTest: null,
      currentAnswers: [],
      currentQuestionIndex: 0,
    );
  }
}

// === 추가 프로바이더들 ===

/// 현재 진행 중인 검사가 있는지 확인
final hasActiveTestProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.hasCurrentTest;
});

/// 현재 검사 진행률
final testProgressProvider = Provider<double>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.testProgress;
});

/// 현재 질문
final currentQuestionProvider = Provider<SelfCheckQuestion?>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.currentQuestion;
});

/// 현재 질문 번호 (1부터 시작)
final currentQuestionNumberProvider = Provider<int>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.currentQuestionIndex + 1;
});

/// 총 질문 수
final totalQuestionsProvider = Provider<int>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.currentTest?.questions.length ?? 0;
});

/// 검사 완료 가능 여부
final canCompleteTestProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.isTestCompleted;
});

/// 이전 질문으로 이동 가능 여부
final canGoToPreviousProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.canGoToPreviousQuestion;
});

/// 다음 질문으로 이동 가능 여부
final canGoToNextProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.canGoToNextQuestion;
});

/// 현재 질문의 답변 상태
final currentQuestionAnswerProvider = Provider<UserAnswer?>((ref) {
  final state = ref.watch(selfCheckProvider);
  final question = state.currentQuestion;

  if (question == null) return null;

  return ref
      .watch(selfCheckProvider.notifier)
      .getAnswerForQuestion(question.id);
});

/// 추천 검사 목록
final recommendedTestsProvider = Provider<List<SelfCheckTest>>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.recommendedTests;
});

/// 최근 검사 결과
final recentResultsProvider = Provider<List<SelfCheckResult>>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.recentResults;
});

/// 로딩 상태
final selfCheckLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.isLoading;
});

/// 에러 상태
final selfCheckErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(selfCheckProvider);
  return state.error;
});
