import 'package:flutter/foundation.dart';
import '../models/self_check_models.dart';

class SelfCheckService {
  // Mock 서비스이므로 실제 API 클라이언트 불필요

  // === 검사 목록 관련 ===

  /// 사용 가능한 모든 검사 목록 조회
  Future<List<SelfCheckTest>> getAvailableTests() async {
    try {
      // 개발 환경에서는 Mock 데이터 반환
      if (kDebugMode) {
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // 네트워크 지연 시뮬레이션
        return _getMockTests();
      }

      // 실제 구현 시 아래 코드 사용:
      /*
      final response = await _apiClient.get('/self-check/tests');
      
      if (response.data['success'] == true) {
        final List<dynamic> testsJson = response.data['data'];
        return testsJson
            .map((json) => SelfCheckTest.fromJson(json))
            .toList();
      } else {
        throw Exception(response.data['message'] ?? '검사 목록을 불러올 수 없습니다.');
      }
      */

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 사용자 맞춤 추천 검사 목록 조회
  Future<List<SelfCheckTest>> getRecommendedTests() async {
    try {
      // 개발 환경에서는 Mock 데이터 반환
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        final allTests = _getMockTests();
        return allTests.take(2).toList(); // 처음 2개만 추천으로 반환
      }

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 특정 검사 상세 정보 조회
  Future<SelfCheckTest> getTestById(String testId) async {
    try {
      // 개발 환경에서는 Mock 데이터 반환
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 400));
        final tests = _getMockTests();
        final test = tests.firstWhere(
          (t) => t.id == testId,
          orElse: () => throw Exception('검사를 찾을 수 없습니다.'),
        );
        return test.copyWith(questions: _getMockQuestions(test.type));
      }

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  // === 검사 결과 관련 ===

  /// 검사 결과 제출 및 저장
  Future<SelfCheckResult> submitTestResult({
    required String testId,
    required List<UserAnswer> answers,
  }) async {
    try {
      // 개발 환경에서는 Mock 결과 반환
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // 저장 시뮬레이션
        return _generateMockResult(testId, answers);
      }

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 최근 검사 결과 조회
  Future<List<SelfCheckResult>> getRecentResults({int limit = 10}) async {
    try {
      // 개발 환경에서는 Mock 데이터 반환
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _getMockRecentResults(limit);
      }

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 검사 결과 상세 조회
  Future<SelfCheckResult> getResultById(String resultId) async {
    try {
      // 개발 환경에서는 Mock 데이터 반환
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 400));
        final recentResults = _getMockRecentResults(10);
        return recentResults.firstWhere(
          (r) => r.id == resultId,
          orElse: () => throw Exception('검사 결과를 찾을 수 없습니다.'),
        );
      }

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 검사 결과 히스토리 조회
  Future<List<SelfCheckResult>> getResultHistory({
    int page = 1,
    int limit = 20,
    SelfCheckTestType? testType,
  }) async {
    try {
      // 개발 환경에서는 Mock 데이터 반환
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _getMockRecentResults(limit);
      }

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 검사 결과 삭제
  Future<void> deleteResult(String resultId) async {
    try {
      // 개발 환경에서는 성공으로 처리
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      throw Exception('API가 구현되지 않았습니다.');
    } catch (e) {
      throw Exception('네트워크 오류가 발생했습니다: $e');
    }
  }

  // === Mock 데이터 (개발용) ===

  List<SelfCheckTest> _getMockTests() {
    return [
      SelfCheckTest(
        id: 'tops2',
        type: SelfCheckTestType.tops2,
        title: 'TOPS-2 검사',
        description:
            '경기력 향상을 위한 심리기술을 종합적으로 평가합니다. 목표설정, 이완, 자신감 등 8개 영역을 측정합니다.',
        category: SelfCheckCategory.performance,
        questionCount: 64,
        estimatedMinutes: 15,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      SelfCheckTest(
        id: 'csai2',
        type: SelfCheckTestType.csai2,
        title: 'CSAI-2 불안 검사',
        description: '경기 상황에서의 불안 수준을 측정합니다. 인지불안, 신체불안, 자신감 등을 평가합니다.',
        category: SelfCheckCategory.anxiety,
        questionCount: 27,
        estimatedMinutes: 10,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      SelfCheckTest(
        id: 'psis',
        type: SelfCheckTestType.psis,
        title: 'PSIS 심리기술 검사',
        description: '스포츠에 필요한 심리적 기술 수준을 평가합니다. 집중력, 자신감, 동기 등을 측정합니다.',
        category: SelfCheckCategory.concentration,
        questionCount: 45,
        estimatedMinutes: 12,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      SelfCheckTest(
        id: 'msci',
        type: SelfCheckTestType.msci,
        title: 'MSCI 정신기술 검사',
        description: '경기에서의 정신적 기술과 대처 능력을 평가합니다.',
        category: SelfCheckCategory.confidence,
        questionCount: 32,
        estimatedMinutes: 8,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      SelfCheckTest(
        id: 'smq',
        type: SelfCheckTestType.smq,
        title: 'SMQ 동기 검사',
        description: '스포츠 참여 동기와 동기 유형을 분석합니다.',
        category: SelfCheckCategory.motivation,
        questionCount: 28,
        estimatedMinutes: 7,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  List<SelfCheckQuestion> _getMockQuestions(SelfCheckTestType testType) {
    switch (testType) {
      case SelfCheckTestType.tops2:
        return _getTops2Questions();
      case SelfCheckTestType.csai2:
        return _getCsai2Questions();
      case SelfCheckTestType.psis:
        return _getPsisQuestions();
      case SelfCheckTestType.msci:
        return _getMsciQuestions();
      case SelfCheckTestType.smq:
        return _getSmqQuestions();
    }
  }

  List<SelfCheckQuestion> _getTops2Questions() {
    final likert5Answers = [
      const SelfCheckAnswer(id: 'never', text: '전혀 그렇지 않다', score: 1, order: 1),
      const SelfCheckAnswer(
        id: 'rarely',
        text: '거의 그렇지 않다',
        score: 2,
        order: 2,
      ),
      const SelfCheckAnswer(id: 'sometimes', text: '보통이다', score: 3, order: 3),
      const SelfCheckAnswer(id: 'often', text: '대체로 그렇다', score: 4, order: 4),
      const SelfCheckAnswer(id: 'always', text: '매우 그렇다', score: 5, order: 5),
    ];

    return [
      SelfCheckQuestion(
        id: 'tops2_1',
        order: 1,
        text: '나는 구체적이고 현실적인 목표를 세운다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '목표설정',
      ),
      SelfCheckQuestion(
        id: 'tops2_2',
        order: 2,
        text: '나는 경기 전에 긴장을 푸는 방법을 안다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '이완',
      ),
      SelfCheckQuestion(
        id: 'tops2_3',
        order: 3,
        text: '나는 어려운 상황에서도 자신감을 유지한다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '자신감',
      ),
      SelfCheckQuestion(
        id: 'tops2_4',
        order: 4,
        text: '나는 경기 중에 집중력을 유지할 수 있다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '집중',
      ),
      SelfCheckQuestion(
        id: 'tops2_5',
        order: 5,
        text: '나는 경기 전에 마음속으로 시뮬레이션을 한다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '심상',
      ),
    ];
  }

  List<SelfCheckQuestion> _getCsai2Questions() {
    final likert4Answers = [
      const SelfCheckAnswer(
        id: 'not_at_all',
        text: '전혀 아니다',
        score: 1,
        order: 1,
      ),
      const SelfCheckAnswer(id: 'somewhat', text: '조금 그렇다', score: 2, order: 2),
      const SelfCheckAnswer(id: 'moderately', text: '보통이다', score: 3, order: 3),
      const SelfCheckAnswer(
        id: 'very_much',
        text: '매우 그렇다',
        score: 4,
        order: 4,
      ),
    ];

    return [
      SelfCheckQuestion(
        id: 'csai2_1',
        order: 1,
        text: '나는 경기에 대해 걱정이 된다.',
        answerType: AnswerType.likert5,
        answers: likert4Answers,
        category: '인지불안',
      ),
      SelfCheckQuestion(
        id: 'csai2_2',
        order: 2,
        text: '나는 경기 전에 몸이 긴장된다.',
        answerType: AnswerType.likert5,
        answers: likert4Answers,
        category: '신체불안',
      ),
      SelfCheckQuestion(
        id: 'csai2_3',
        order: 3,
        text: '나는 이번 경기에서 잘 할 수 있다고 확신한다.',
        answerType: AnswerType.likert5,
        answers: likert4Answers,
        category: '상태자신감',
      ),
    ];
  }

  List<SelfCheckQuestion> _getPsisQuestions() {
    final likert5Answers = [
      const SelfCheckAnswer(id: 'never', text: '전혀 그렇지 않다', score: 1, order: 1),
      const SelfCheckAnswer(
        id: 'rarely',
        text: '거의 그렇지 않다',
        score: 2,
        order: 2,
      ),
      const SelfCheckAnswer(id: 'sometimes', text: '보통이다', score: 3, order: 3),
      const SelfCheckAnswer(id: 'often', text: '대체로 그렇다', score: 4, order: 4),
      const SelfCheckAnswer(id: 'always', text: '매우 그렇다', score: 5, order: 5),
    ];

    return [
      SelfCheckQuestion(
        id: 'psis_1',
        order: 1,
        text: '나는 경기 중에 집중력을 유지할 수 있다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '집중력',
      ),
      SelfCheckQuestion(
        id: 'psis_2',
        order: 2,
        text: '나는 나 자신의 능력을 믿는다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '자신감',
      ),
    ];
  }

  List<SelfCheckQuestion> _getMsciQuestions() {
    final likert5Answers = [
      const SelfCheckAnswer(id: 'never', text: '전혀 그렇지 않다', score: 1, order: 1),
      const SelfCheckAnswer(
        id: 'rarely',
        text: '거의 그렇지 않다',
        score: 2,
        order: 2,
      ),
      const SelfCheckAnswer(id: 'sometimes', text: '보통이다', score: 3, order: 3),
      const SelfCheckAnswer(id: 'often', text: '대체로 그렇다', score: 4, order: 4),
      const SelfCheckAnswer(id: 'always', text: '매우 그렇다', score: 5, order: 5),
    ];

    return [
      SelfCheckQuestion(
        id: 'msci_1',
        order: 1,
        text: '나는 압박감 속에서도 침착함을 유지한다.',
        answerType: AnswerType.likert5,
        answers: likert5Answers,
        category: '정신력',
      ),
    ];
  }

  List<SelfCheckQuestion> _getSmqQuestions() {
    final likert7Answers = [
      const SelfCheckAnswer(
        id: 'strongly_disagree',
        text: '매우 그렇지 않다',
        score: 1,
        order: 1,
      ),
      const SelfCheckAnswer(id: 'disagree', text: '그렇지 않다', score: 2, order: 2),
      const SelfCheckAnswer(
        id: 'somewhat_disagree',
        text: '약간 그렇지 않다',
        score: 3,
        order: 3,
      ),
      const SelfCheckAnswer(id: 'neutral', text: '보통이다', score: 4, order: 4),
      const SelfCheckAnswer(
        id: 'somewhat_agree',
        text: '약간 그렇다',
        score: 5,
        order: 5,
      ),
      const SelfCheckAnswer(id: 'agree', text: '그렇다', score: 6, order: 6),
      const SelfCheckAnswer(
        id: 'strongly_agree',
        text: '매우 그렇다',
        score: 7,
        order: 7,
      ),
    ];

    return [
      SelfCheckQuestion(
        id: 'smq_1',
        order: 1,
        text: '나는 재미있기 때문에 스포츠를 한다.',
        answerType: AnswerType.likert7,
        answers: likert7Answers,
        category: '내재적 동기',
      ),
    ];
  }

  List<SelfCheckResult> _getMockRecentResults(int limit) {
    final tests = _getMockTests();
    final results = <SelfCheckResult>[];

    for (int i = 0; i < limit && i < tests.length; i++) {
      final test = tests[i];
      final answers = _generateMockAnswers(test);

      results.add(
        SelfCheckResult(
          id: 'result_${test.id}_$i',
          userId: 'user_123',
          test: test,
          answers: answers,
          totalScore: answers.fold(0, (sum, answer) => sum + answer.score),
          maxScore: test.questionCount * 5, // 5점 척도 가정
          percentage: 65.0 + (i * 5), // Mock 퍼센트
          riskLevel:
              i == 0
                  ? RiskLevel.high
                  : i == 1
                  ? RiskLevel.moderate
                  : RiskLevel.low,
          categoryScores: {
            '전체': answers.fold(0, (sum, answer) => sum + answer.score),
          },
          interpretation: '${test.title} 결과에 따르면 전반적으로 양호한 상태입니다.',
          recommendations: [
            '정기적인 심리 훈련을 권장합니다.',
            '전문가와의 상담을 고려해보세요.',
            '스트레스 관리 기법을 익혀보세요.',
          ],
          completedAt: DateTime.now().subtract(Duration(days: i * 3)),
        ),
      );
    }

    return results;
  }

  List<UserAnswer> _generateMockAnswers(SelfCheckTest test) {
    final questions = _getMockQuestions(test.type);
    return questions.take(5).map((question) {
      final randomScore = 2 + (question.order % 4); // 2-5점 사이
      final selectedAnswer = question.answers.firstWhere(
        (answer) => answer.score == randomScore,
      );

      return UserAnswer(
        questionId: question.id,
        answerId: selectedAnswer.id,
        score: selectedAnswer.score,
        answeredAt: DateTime.now().subtract(Duration(minutes: question.order)),
      );
    }).toList();
  }

  SelfCheckResult _generateMockResult(String testId, List<UserAnswer> answers) {
    final tests = _getMockTests();
    final test = tests.firstWhere((t) => t.id == testId);

    final totalScore = answers.fold(0, (sum, answer) => sum + answer.score);
    final maxScore = answers.length * 5; // 5점 척도 가정
    final percentage = (totalScore / maxScore) * 100;

    return SelfCheckResult(
      id: 'result_${testId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_123',
      test: test,
      answers: answers,
      totalScore: totalScore,
      maxScore: maxScore,
      percentage: percentage,
      riskLevel: RiskLevel.fromScore(totalScore, maxScore),
      categoryScores: {'전체': totalScore},
      interpretation: _generateInterpretation(percentage),
      recommendations: _generateRecommendations(percentage),
      completedAt: DateTime.now(),
    );
  }

  String _generateInterpretation(double percentage) {
    if (percentage >= 80) {
      return '매우 우수한 심리 상태를 보이고 있습니다. 현재 수준을 유지하며 지속적인 발전을 추구하세요.';
    } else if (percentage >= 60) {
      return '양호한 심리 상태입니다. 일부 영역에서 개선의 여지가 있으니 전문가의 조언을 구해보세요.';
    } else if (percentage >= 40) {
      return '보통 수준의 심리 상태입니다. 체계적인 심리 훈련을 통해 개선할 수 있습니다.';
    } else {
      return '심리적 지원이 필요한 상태입니다. 전문 상담사와의 상담을 강력히 권장합니다.';
    }
  }

  List<String> _generateRecommendations(double percentage) {
    if (percentage >= 80) {
      return ['현재 수준 유지를 위한 정기적인 점검', '고급 심리기술 훈련 참여', '후배 멘토링을 통한 경험 공유'];
    } else if (percentage >= 60) {
      return ['주 2-3회 이완 훈련 실시', '목표설정 및 계획 수립 연습', '정기적인 자가진단 실시'];
    } else if (percentage >= 40) {
      return [
        '전문가와의 정기적인 상담',
        '체계적인 심리기술 훈련 프로그램 참여',
        '스트레스 관리 기법 학습',
        '팀 동료나 코치와의 소통 증대',
      ];
    } else {
      return [
        '즉시 전문 상담사와 상담 예약',
        '심리적 지원 프로그램 참여',
        '충분한 휴식과 회복 시간 확보',
        '가족이나 지인의 지지체계 활용',
      ];
    }
  }
}
