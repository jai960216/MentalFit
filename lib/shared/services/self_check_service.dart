import 'package:flutter/foundation.dart';
import '../models/self_check_models.dart';

class SelfCheckService {
  static SelfCheckService? _instance;
  List<SelfCheckTest>? _cachedTests;
  List<SelfCheckResult>? _cachedResults;

  SelfCheckService._internal();

  static Future<SelfCheckService> getInstance() async {
    _instance ??= SelfCheckService._internal();
    await _instance!._initialize();
    return _instance!;
  }

  /// 서비스 초기화
  Future<void> _initialize() async {
    try {
      // 초기화 시 기본 데이터 캐싱
      _cachedTests = _getMockTests();
      _cachedResults = _getMockResults();
      debugPrint('SelfCheckService 초기화 완료');
    } catch (e) {
      debugPrint('SelfCheckService 초기화 오류: $e');
      // 초기화 실패 시에도 기본 데이터는 생성
      _cachedTests = _getEmergencyMockTests();
      _cachedResults = [];
    }
  }

  /// 사용 가능한 검사 목록 조회
  Future<List<SelfCheckTest>> getAvailableTests() async {
    try {
      // 실제 API 호출 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 800));

      // 캐시된 데이터가 있으면 반환
      if (_cachedTests != null && _cachedTests!.isNotEmpty) {
        debugPrint('캐시된 검사 목록 반환: ${_cachedTests!.length}개');
        return List.from(_cachedTests!);
      }

      // 캐시가 없으면 새로 생성
      _cachedTests = _getMockTests();
      return List.from(_cachedTests!);
    } catch (e) {
      debugPrint('검사 목록 조회 오류: $e');
      // 오류 발생 시 기본 Mock 데이터 반환
      return _getEmergencyMockTests();
    }
  }

  /// 추천 검사 조회
  Future<List<SelfCheckTest>> getRecommendedTests() async {
    try {
      final allTests = await getAvailableTests();
      // 활성화된 검사 중 처음 2개를 추천으로 반환
      final recommendedTests =
          allTests.where((test) => test.isActive).take(2).toList();

      debugPrint('추천 검사 반환: ${recommendedTests.length}개');
      return recommendedTests;
    } catch (e) {
      debugPrint('추천 검사 조회 오류: $e');
      // 오류 시 기본 추천 검사 반환
      final emergencyTests = _getEmergencyMockTests();
      return emergencyTests.take(1).toList();
    }
  }

  /// 특정 검사 조회 - 🔥 핵심 개선 부분
  Future<SelfCheckTest> getTestById(String testId) async {
    try {
      debugPrint('검사 조회 시작: $testId');

      // 먼저 캐시에서 검색
      if (_cachedTests != null) {
        final test = _cachedTests!.cast<SelfCheckTest?>().firstWhere(
          (test) => test?.id == testId,
          orElse: () => null,
        );

        if (test != null) {
          debugPrint('캐시에서 검사 발견: ${test.title}');
          return test;
        }
      }

      // 캐시에 없으면 전체 목록에서 다시 검색
      final allTests = await getAvailableTests();
      final foundTest = allTests.cast<SelfCheckTest?>().firstWhere(
        (test) => test?.id == testId,
        orElse: () => null,
      );

      if (foundTest != null) {
        debugPrint('전체 목록에서 검사 발견: ${foundTest.title}');
        return foundTest;
      }

      // 여전히 찾지 못한 경우, ID 기반으로 기본 검사 생성
      debugPrint('검사를 찾을 수 없어 기본 검사 생성: $testId');
      return _createDefaultTestById(testId);
    } catch (e) {
      debugPrint('검사 조회 심각한 오류: $e');
      // 최후의 수단: 기본 검사 반환
      return _createEmergencyTest(testId);
    }
  }

  /// 최근 검사 결과 조회
  Future<List<SelfCheckResult>> getRecentResults({int limit = 10}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (_cachedResults != null) {
        final results = _cachedResults!.take(limit).toList();
        debugPrint('최근 결과 반환: ${results.length}개');
        return results;
      }

      _cachedResults = _getMockResults();
      return _cachedResults!.take(limit).toList();
    } catch (e) {
      debugPrint('최근 결과 조회 오류: $e');
      return []; // 빈 리스트 반환
    }
  }

  /// 검사 결과 제출
  Future<SelfCheckResult> submitTest({
    required String testId,
    required List<UserAnswer> answers,
  }) async {
    try {
      debugPrint('검사 제출 시작: $testId, 답변 수: ${answers.length}');
      await Future.delayed(const Duration(milliseconds: 1500));

      final test = await getTestById(testId);
      final result = _calculateTestResult(test, answers);

      // 결과를 캐시에 추가
      _cachedResults ??= [];
      _cachedResults!.insert(0, result);

      debugPrint('검사 제출 완료: ${result.id}');
      return result;
    } catch (e) {
      debugPrint('검사 제출 오류: $e');
      throw Exception('검사 제출에 실패했습니다: ${e.toString()}');
    }
  }

  /// ID 기반 기본 검사 생성
  SelfCheckTest _createDefaultTestById(String testId) {
    // testId 패턴에 따라 적절한 검사 생성
    if (testId.contains('tops2')) {
      return _createTOPS2Test(testId);
    } else if (testId.contains('csai2')) {
      return _createCSAI2Test(testId);
    } else {
      return _createGenericTest(testId);
    }
  }

  /// 긴급 상황용 기본 검사 생성
  SelfCheckTest _createEmergencyTest(String testId) {
    return SelfCheckTest(
      id: testId,
      type: SelfCheckTestType.tops2,
      title: '기본 심리 검사',
      description: '임시로 생성된 기본 검사입니다.',
      category: SelfCheckCategory.performance,
      questionCount: 5,
      estimatedMinutes: 3,
      questions: _generateBasicQuestions(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 기본 질문 생성
  List<SelfCheckQuestion> _generateBasicQuestions() {
    return [
      SelfCheckQuestion(
        id: 'basic_q1',
        order: 1,
        text: '운동할 때 자신감을 느끼십니까?',
        answerType: AnswerType.likert5,
        answers: _generateLikert5Answers(),
      ),
      SelfCheckQuestion(
        id: 'basic_q2',
        order: 2,
        text: '경기 전에 긴장을 잘 조절할 수 있습니까?',
        answerType: AnswerType.likert5,
        answers: _generateLikert5Answers(),
      ),
      SelfCheckQuestion(
        id: 'basic_q3',
        order: 3,
        text: '목표를 향해 꾸준히 노력하고 있습니까?',
        answerType: AnswerType.likert5,
        answers: _generateLikert5Answers(),
      ),
      SelfCheckQuestion(
        id: 'basic_q4',
        order: 4,
        text: '어려운 상황에서도 집중력을 유지할 수 있습니까?',
        answerType: AnswerType.likert5,
        answers: _generateLikert5Answers(),
      ),
      SelfCheckQuestion(
        id: 'basic_q5',
        order: 5,
        text: '동료들과 잘 협력할 수 있습니까?',
        answerType: AnswerType.likert5,
        answers: _generateLikert5Answers(),
      ),
    ];
  }

  /// 5점 척도 답변 생성
  List<SelfCheckAnswer> _generateLikert5Answers() {
    return [
      const SelfCheckAnswer(id: 'ans1', text: '전혀 그렇지 않다', score: 1, order: 1),
      const SelfCheckAnswer(id: 'ans2', text: '그렇지 않다', score: 2, order: 2),
      const SelfCheckAnswer(id: 'ans3', text: '보통이다', score: 3, order: 3),
      const SelfCheckAnswer(id: 'ans4', text: '그렇다', score: 4, order: 4),
      const SelfCheckAnswer(id: 'ans5', text: '매우 그렇다', score: 5, order: 5),
    ];
  }

  /// TOPS2 검사 생성
  SelfCheckTest _createTOPS2Test(String testId) {
    return SelfCheckTest(
      id: testId,
      type: SelfCheckTestType.tops2,
      title: 'TOPS-2 수행전략 검사',
      description: '스포츠 수행 전략과 심리적 기술을 평가하는 검사입니다.',
      category: SelfCheckCategory.performance,
      questionCount: 20,
      estimatedMinutes: 10,
      questions: _generateTOPS2Questions(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// CSAI2 검사 생성
  SelfCheckTest _createCSAI2Test(String testId) {
    return SelfCheckTest(
      id: testId,
      type: SelfCheckTestType.csai2,
      title: 'CSAI-2 경쟁불안 검사',
      description: '경기 상황에서의 불안 수준을 측정하는 검사입니다.',
      category: SelfCheckCategory.anxiety,
      questionCount: 15,
      estimatedMinutes: 8,
      questions: _generateCSAI2Questions(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 범용 검사 생성
  SelfCheckTest _createGenericTest(String testId) {
    return SelfCheckTest(
      id: testId,
      type: SelfCheckTestType.psis,
      title: '심리적 기술 검사',
      description: '스포츠 심리적 기술을 종합적으로 평가합니다.',
      category: SelfCheckCategory.performance,
      questionCount: 12,
      estimatedMinutes: 6,
      questions: _generateGenericQuestions(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 비상용 Mock 검사 데이터 (최소한의 데이터)
  List<SelfCheckTest> _getEmergencyMockTests() {
    return [
      SelfCheckTest(
        id: 'emergency_test_001',
        type: SelfCheckTestType.tops2,
        title: '기본 심리 검사',
        description: '기본적인 스포츠 심리 상태를 평가합니다.',
        category: SelfCheckCategory.performance,
        questionCount: 5,
        estimatedMinutes: 3,
        questions: _generateBasicQuestions(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
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
        estimatedMinutes: 8,
        questions: _generateMockQuestions(27, 'CSAI2'),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SelfCheckTest(
        id: 'psis_test_001',
        type: SelfCheckTestType.psis,
        title: 'PSIS 스포츠 심리기술 검사',
        description: '스포츠에 필요한 다양한 심리적 기술들을 종합적으로 평가합니다.',
        category: SelfCheckCategory.concentration,
        questionCount: 45,
        estimatedMinutes: 12,
        questions: _generateMockQuestions(45, 'PSIS'),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Mock 질문 생성
  List<SelfCheckQuestion> _generateMockQuestions(int count, String prefix) {
    final questions = <SelfCheckQuestion>[];

    for (int i = 1; i <= count; i++) {
      questions.add(
        SelfCheckQuestion(
          id: '${prefix.toLowerCase()}_q$i',
          order: i,
          text: _getQuestionText(prefix, i),
          answerType: AnswerType.likert5,
          answers: _generateLikert5Answers(),
          category: _getQuestionCategory(prefix, i),
        ),
      );
    }

    return questions;
  }

  /// 검사별 질문 텍스트 생성
  String _getQuestionText(String prefix, int questionNumber) {
    switch (prefix) {
      case 'TOPS2':
        return _getTOPS2QuestionText(questionNumber);
      case 'CSAI2':
        return _getCSAI2QuestionText(questionNumber);
      case 'PSIS':
        return _getPSISQuestionText(questionNumber);
      default:
        return '질문 $questionNumber: 이 항목에 대해 어떻게 생각하십니까?';
    }
  }

  /// TOPS2 질문 텍스트
  String _getTOPS2QuestionText(int num) {
    final tops2Questions = [
      '목표를 설정할 때 구체적이고 명확하게 설정한다',
      '경기 중 실수를 했을 때 빠르게 집중력을 회복한다',
      '어려운 상황에서도 자신감을 유지한다',
      '경기 전 긴장을 적절히 조절할 수 있다',
      '팀원들과 효과적으로 소통한다',
    ];

    if (num <= tops2Questions.length) {
      return tops2Questions[num - 1];
    }
    return '목표 달성을 위해 꾸준히 노력한다 ($num)';
  }

  /// CSAI2 질문 텍스트
  String _getCSAI2QuestionText(int num) {
    final csai2Questions = [
      '경기 전에 걱정이 많아진다',
      '경기 전에 몸이 긴장된다',
      '경기에서 좋은 성과를 낼 자신이 있다',
      '경기 결과에 대해 불안하다',
      '경기 전에 심장이 빨리 뛴다',
    ];

    if (num <= csai2Questions.length) {
      return csai2Questions[num - 1];
    }
    return '경기 상황에서 평정심을 유지한다 ($num)';
  }

  /// PSIS 질문 텍스트
  String _getPSISQuestionText(int num) {
    final psisQuestions = [
      '집중력을 오래 유지할 수 있다',
      '부정적인 생각을 긍정적으로 바꿀 수 있다',
      '동기를 스스로 높일 수 있다',
      '스트레스를 잘 관리한다',
      '자신의 감정을 잘 조절한다',
    ];

    if (num <= psisQuestions.length) {
      return psisQuestions[num - 1];
    }
    return '심리적 압박감을 잘 견딘다 ($num)';
  }

  /// 질문 카테고리 설정
  String? _getQuestionCategory(String prefix, int questionNumber) {
    switch (prefix) {
      case 'TOPS2':
        if (questionNumber <= 16) return '기본 기술';
        if (questionNumber <= 32) return '심리 기술';
        if (questionNumber <= 48) return '인지 전략';
        return '수행 전략';
      case 'CSAI2':
        if (questionNumber <= 9) return '인지불안';
        if (questionNumber <= 18) return '신체불안';
        return '자신감';
      case 'PSIS':
        if (questionNumber <= 15) return '집중력';
        if (questionNumber <= 30) return '자신감';
        return '동기';
      default:
        return null;
    }
  }

  /// TOPS2 전용 질문 생성
  List<SelfCheckQuestion> _generateTOPS2Questions() {
    return _generateMockQuestions(20, 'TOPS2');
  }

  /// CSAI2 전용 질문 생성
  List<SelfCheckQuestion> _generateCSAI2Questions() {
    return _generateMockQuestions(15, 'CSAI2');
  }

  /// 범용 질문 생성
  List<SelfCheckQuestion> _generateGenericQuestions() {
    return _generateMockQuestions(12, 'GENERIC');
  }

  /// Mock 결과 데이터 생성
  List<SelfCheckResult> _getMockResults() {
    final now = DateTime.now();
    return [
      SelfCheckResult(
        id: 'result_001',
        userId: 'user_123',
        test: _getMockTests()[0],
        answers: [],
        totalScore: 240,
        maxScore: 320,
        percentage: 75.0,
        riskLevel: RiskLevel.moderate,
        categoryScores: {'기본 기술': 60, '심리 기술': 65, '인지 전략': 55, '수행 전략': 60},
        interpretation: '전반적으로 양호한 수준입니다.',
        recommendations: ['인지 전략 향상이 필요합니다', '정기적인 심리 훈련을 권장합니다'],
        completedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
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
    final maxScore = test.questions.length * 5; // 5점 척도 기준
    final percentage = (totalScore / maxScore) * 100;
    final riskLevel = RiskLevel.fromScore(totalScore, maxScore);

    return SelfCheckResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
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
        orElse: () => test.questions.first,
      );

      final category = question.category ?? '기타';
      categoryScores[category] = (categoryScores[category] ?? 0) + answer.score;
    }

    return categoryScores;
  }

  /// 결과 해석 생성
  String _generateInterpretation(double percentage, RiskLevel riskLevel) {
    if (percentage >= 80) {
      return '매우 우수한 심리적 상태를 보이고 있습니다. 현재의 좋은 상태를 유지하시기 바랍니다.';
    } else if (percentage >= 60) {
      return '전반적으로 양호한 수준입니다. 일부 영역에서 개선이 필요할 수 있습니다.';
    } else if (percentage >= 40) {
      return '보통 수준입니다. 지속적인 관리와 개선 노력이 필요합니다.';
    } else {
      return '관심과 주의가 필요한 상태입니다. 전문가 상담을 권장합니다.';
    }
  }

  /// 추천사항 생성
  List<String> _generateRecommendations(
    RiskLevel riskLevel,
    SelfCheckCategory category,
  ) {
    final recommendations = <String>[];

    switch (riskLevel) {
      case RiskLevel.low:
        recommendations.addAll([
          '현재의 좋은 상태를 유지하세요',
          '정기적인 자가점검을 통해 상태를 모니터링하세요',
        ]);
        break;
      case RiskLevel.moderate:
        recommendations.addAll([
          '꾸준한 심리 훈련이 필요합니다',
          '스트레스 관리 방법을 익히세요',
          '목표 설정과 계획 수립을 체계적으로 하세요',
        ]);
        break;
      case RiskLevel.high:
        recommendations.addAll([
          '전문가 상담을 받으시기 바랍니다',
          '체계적인 심리 치료 프로그램 참여를 고려하세요',
          '일상생활에서의 스트레스 요인을 점검하세요',
        ]);
        break;
    }

    // 카테고리별 추가 추천사항
    switch (category) {
      case SelfCheckCategory.anxiety:
        recommendations.add('이완 기법과 호흡법을 연습하세요');
        break;
      case SelfCheckCategory.performance:
        recommendations.add('목표 설정과 성과 분석을 정기적으로 하세요');
        break;
      case SelfCheckCategory.concentration:
        recommendations.add('집중력 향상 훈련을 꾸준히 하세요');
        break;
      case SelfCheckCategory.confidence:
        recommendations.add('성공 경험을 기록하고 회상하세요');
        break;
      case SelfCheckCategory.motivation:
        recommendations.add('동기 부여 요소들을 명확히 하세요');
        break;
    }

    return recommendations;
  }
}
