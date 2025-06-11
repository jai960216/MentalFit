import 'package:flutter/foundation.dart';
import '../models/self_check_models.dart';

class SelfCheckService {
  static SelfCheckService? _instance;

  SelfCheckService._internal();

  static Future<SelfCheckService> getInstance() async {
    _instance ??= SelfCheckService._internal();
    return _instance!;
  }

  /// 사용 가능한 검사 목록 조회
  Future<List<SelfCheckTest>> getAvailableTests() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockTests();
    } catch (e) {
      debugPrint('검사 목록 조회 오류: $e');
      return _getMockTests();
    }
  }

  /// 추천 검사 조회
  Future<List<SelfCheckTest>> getRecommendedTests() async {
    try {
      final allTests = await getAvailableTests();
      return allTests.take(2).toList();
    } catch (e) {
      debugPrint('추천 검사 조회 오류: $e');
      return [];
    }
  }

  /// 특정 검사 조회
  Future<SelfCheckTest> getTestById(String testId) async {
    try {
      final tests = await getAvailableTests();
      return tests.firstWhere((test) => test.id == testId);
    } catch (e) {
      debugPrint('검사 조회 오류: $e');
      throw Exception('검사를 찾을 수 없습니다');
    }
  }

  /// 최근 검사 결과 조회
  Future<List<SelfCheckResult>> getRecentResults({int limit = 10}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockResults().take(limit).toList();
    } catch (e) {
      debugPrint('최근 결과 조회 오류: $e');
      return [];
    }
  }

  /// 검사 결과 제출
  Future<SelfCheckResult> submitTest({
    required String testId,
    required List<UserAnswer> answers,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      final test = await getTestById(testId);
      final result = _calculateTestResult(test, answers);

      return result;
    } catch (e) {
      debugPrint('검사 제출 오류: $e');
      throw Exception('검사 제출에 실패했습니다');
    }
  }

  /// Mock 검사 데이터 생성
  List<SelfCheckTest> _getMockTests() {
    return [
      SelfCheckTest(
        id: 'tops2_test_001',
        type: SelfCheckTestType.tops2,
        title: 'TOPS-2 수행전략 검사',
        description:
            '스포츠 수행 전략과 심리적 기술을 평가하는 검사입니다. 운동선수의 정신력과 수행 능력을 종합적으로 분석합니다.',
        category: SelfCheckCategory.performance,
        questionCount: 64,
        estimatedMinutes: 15,
        questions: _generateMockQuestions(64, 'TOPS2'),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SelfCheckTest(
        id: 'csai2_test_001',
        type: SelfCheckTestType.csai2,
        title: 'CSAI-2 경쟁불안 검사',
        description: '경기 상황에서의 불안 수준을 측정하는 검사입니다. 인지불안, 신체불안, 자신감을 각각 평가합니다.',
        category: SelfCheckCategory.anxiety,
        questionCount: 27,
        estimatedMinutes: 10,
        questions: _generateMockQuestions(27, 'CSAI2'),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      SelfCheckTest(
        id: 'psis_test_001',
        type: SelfCheckTestType.psis,
        title: 'PSIS 심리기술 검사',
        description: '스포츠 심리 기술 수준을 측정하는 검사입니다. 집중력, 자신감, 불안 조절 등을 평가합니다.',
        category: SelfCheckCategory.concentration,
        questionCount: 45,
        estimatedMinutes: 12,
        questions: _generateMockQuestions(45, 'PSIS'),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      SelfCheckTest(
        id: 'smq_test_001',
        type: SelfCheckTestType.smq,
        title: 'SMQ 스포츠 동기 검사',
        description: '스포츠 참여 동기를 측정하는 검사입니다. 내재적 동기, 외재적 동기, 무동기를 분석합니다.',
        category: SelfCheckCategory.motivation,
        questionCount: 28,
        estimatedMinutes: 8,
        questions: _generateMockQuestions(28, 'SMQ'),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  /// Mock 질문 생성
  List<SelfCheckQuestion> _generateMockQuestions(int count, String testType) {
    final questions = <SelfCheckQuestion>[];

    for (int i = 1; i <= count; i++) {
      final questionText = _getQuestionText(testType, i);
      final answers = _generateAnswerOptions();

      questions.add(
        SelfCheckQuestion(
          id: '${testType.toLowerCase()}_q_$i',
          order: i,
          text: questionText,
          answerType: AnswerType.likert5,
          answers: answers,
          category: _getQuestionCategory(testType, i),
          isRequired: true,
        ),
      );
    }

    return questions;
  }

  /// 질문 텍스트 가져오기
  String _getQuestionText(String testType, int questionNumber) {
    switch (testType) {
      case 'TOPS2':
        return _getTOPS2Questions()[questionNumber %
            _getTOPS2Questions().length];
      case 'CSAI2':
        return _getCSAI2Questions()[questionNumber %
            _getCSAI2Questions().length];
      case 'PSIS':
        return _getPSISQuestions()[questionNumber % _getPSISQuestions().length];
      case 'SMQ':
        return _getSMQQuestions()[questionNumber % _getSMQQuestions().length];
      default:
        return '질문 $questionNumber';
    }
  }

  /// TOPS2 질문 목록
  List<String> _getTOPS2Questions() {
    return [
      '나는 스포츠에서 목표를 설정한다',
      '나는 경기 중 집중을 유지한다',
      '나는 실수 후에도 빠르게 회복한다',
      '나는 압박감 속에서도 침착함을 유지한다',
      '나는 경기 전에 심상훈련을 한다',
      '나는 부정적인 생각을 긍정적으로 바꾼다',
      '나는 나만의 경기 루틴이 있다',
      '나는 팀원들과 효과적으로 소통한다',
    ];
  }

  /// CSAI2 질문 목록
  List<String> _getCSAI2Questions() {
    return [
      '나는 경기가 다가오면 걱정이 된다',
      '몸이 긴장되어 있다고 느낀다',
      '나는 내 능력에 대해 확신한다',
      '심장이 빠르게 뛴다',
      '나는 목표를 달성할 수 있다고 확신한다',
      '위가 안 좋다고 느낀다',
      '나는 도전에 대해 준비가 되어 있다',
    ];
  }

  /// PSIS 질문 목록
  List<String> _getPSISQuestions() {
    return [
      '나는 운동할 때 완전히 집중할 수 있다',
      '나는 실수를 했을 때 빠르게 잊는다',
      '나는 내 감정을 잘 조절할 수 있다',
      '나는 경기 전에 긴장을 완화시킬 수 있다',
      '나는 어려운 상황에서도 자신감을 유지한다',
    ];
  }

  /// SMQ 질문 목록
  List<String> _getSMQQuestions() {
    return [
      '나는 운동하는 것 자체가 즐겁다',
      '나는 실력 향상을 위해 운동한다',
      '나는 다른 사람들에게 인정받기 위해 운동한다',
      '나는 상금이나 보상을 위해 운동한다',
      '나는 건강을 위해 운동한다',
    ];
  }

  /// 질문 카테고리 가져오기
  String? _getQuestionCategory(String testType, int questionNumber) {
    switch (testType) {
      case 'CSAI2':
        if (questionNumber % 3 == 1) return '인지불안';
        if (questionNumber % 3 == 2) return '신체불안';
        return '자신감';
      case 'PSIS':
        final categories = ['집중력', '불안조절', '자신감', '동기'];
        return categories[questionNumber % categories.length];
      default:
        return null;
    }
  }

  /// 답변 옵션 생성
  List<SelfCheckAnswer> _generateAnswerOptions() {
    return [
      const SelfCheckAnswer(
        id: 'strongly_disagree',
        text: '전혀 그렇지 않다',
        score: 1,
        order: 1,
      ),
      const SelfCheckAnswer(id: 'disagree', text: '그렇지 않다', score: 2, order: 2),
      const SelfCheckAnswer(id: 'neutral', text: '보통이다', score: 3, order: 3),
      const SelfCheckAnswer(id: 'agree', text: '그렇다', score: 4, order: 4),
      const SelfCheckAnswer(
        id: 'strongly_agree',
        text: '매우 그렇다',
        score: 5,
        order: 5,
      ),
    ];
  }

  /// Mock 결과 데이터 생성
  List<SelfCheckResult> _getMockResults() {
    final tests = _getMockTests();
    return tests.map((test) {
      return SelfCheckResult(
        id: 'result_${test.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        test: test,
        answers: [],
        totalScore: 150 + (test.questionCount * 2),
        maxScore: test.questionCount * 5,
        percentage: 75.0,
        riskLevel: RiskLevel.moderate,
        categoryScores: {'집중력': 15, '불안조절': 12, '자신감': 18},
        interpretation: '전반적으로 양호한 상태이며, 일부 영역에서 개선이 필요합니다.',
        recommendations: [
          '규칙적인 심상훈련을 통해 집중력을 향상시키세요',
          '호흡법을 활용한 불안 관리 기법을 연습하세요',
          '긍정적 자기대화를 통해 자신감을 높이세요',
        ],
        completedAt: DateTime.now().subtract(
          Duration(days: DateTime.now().day % 10),
        ),
        viewedAt: DateTime.now().subtract(
          Duration(hours: DateTime.now().hour % 24),
        ),
      );
    }).toList();
  }

  /// 검사 결과 계산
  SelfCheckResult _calculateTestResult(
    SelfCheckTest test,
    List<UserAnswer> answers,
  ) {
    final totalScore = answers.fold<int>(
      0,
      (sum, answer) => sum + answer.score,
    );
    final maxScore = test.questions.length * 5;
    final percentage = (totalScore / maxScore) * 100;
    final riskLevel = RiskLevel.fromScore(totalScore, maxScore);

    return SelfCheckResult(
      id: 'result_${test.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user',
      test: test,
      answers: answers,
      totalScore: totalScore,
      maxScore: maxScore,
      percentage: percentage,
      riskLevel: riskLevel,
      categoryScores: _calculateCategoryScores(test, answers),
      interpretation: _generateInterpretation(percentage, riskLevel),
      recommendations: _generateRecommendations(riskLevel, test.category),
      completedAt: DateTime.now(),
    );
  }

  /// 카테고리별 점수 계산
  Map<String, int> _calculateCategoryScores(
    SelfCheckTest test,
    List<UserAnswer> answers,
  ) {
    final categoryScores = <String, int>{};

    for (final answer in answers) {
      final question = test.questions.firstWhere(
        (q) => q.id == answer.questionId,
      );
      final category = question.category ?? '기타';
      categoryScores[category] = (categoryScores[category] ?? 0) + answer.score;
    }

    return categoryScores;
  }

  /// 결과 해석 생성
  String _generateInterpretation(double percentage, RiskLevel riskLevel) {
    if (percentage >= 80) {
      return '매우 우수한 심리적 상태를 보이고 있습니다. 현재의 긍정적인 상태를 유지하시기 바랍니다.';
    } else if (percentage >= 60) {
      return '전반적으로 양호한 상태이며, 일부 영역에서 개선이 필요합니다.';
    } else {
      return '심리적 지원이 필요한 상태입니다. 전문가와의 상담을 권장합니다.';
    }
  }

  /// 추천사항 생성
  List<String> _generateRecommendations(
    RiskLevel riskLevel,
    SelfCheckCategory category,
  ) {
    final baseRecommendations = [
      '규칙적인 운동과 충분한 휴식을 취하세요',
      '명상이나 요가를 통해 마음의 안정을 찾으세요',
      '긍정적인 사고방식을 유지하세요',
    ];

    final categoryRecommendations = {
      SelfCheckCategory.anxiety: [
        '호흡법을 활용한 불안 관리 기법을 연습하세요',
        '스트레스 요인을 파악하고 관리 방법을 찾으세요',
      ],
      SelfCheckCategory.performance: [
        '목표 설정과 계획 수립을 체계적으로 하세요',
        '피드백을 적극적으로 활용하세요',
      ],
      SelfCheckCategory.concentration: [
        '집중력 향상을 위한 훈련을 꾸준히 하세요',
        '주변 환경을 정리하여 집중하기 좋은 환경을 만드세요',
      ],
      SelfCheckCategory.motivation: [
        '명확한 목표를 설정하고 작은 성취를 축하하세요',
        '동기부여가 되는 활동을 찾아보세요',
      ],
      SelfCheckCategory.confidence: [
        '긍정적 자기대화를 통해 자신감을 높이세요',
        '과거의 성공 경험을 되새기세요',
      ],
    };

    return [
      ...baseRecommendations,
      ...(categoryRecommendations[category] ?? []),
    ];
  }
}
