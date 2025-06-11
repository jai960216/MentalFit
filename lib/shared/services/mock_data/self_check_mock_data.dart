import '../../models/self_check_models.dart';

class SelfCheckMockData {
  // === 기본 Mock 검사 목록 ===
  List<SelfCheckTest> getMockTests() {
    return [
      SelfCheckTest(
        id: 'tops2',
        type: SelfCheckTestType.tops2,
        title: 'TOPS-2 수행 전략 검사',
        description: '경기력 향상을 위한 심리기술을 종합적으로 평가합니다.',
        category: SelfCheckCategory.performance,
        questionCount: 15,
        estimatedMinutes: 8,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SelfCheckTest(
        id: 'csai2',
        type: SelfCheckTestType.csai2,
        title: 'CSAI-2 경기 불안 검사',
        description: '경기나 중요한 상황에서 느끼는 불안감 수준을 측정합니다.',
        category: SelfCheckCategory.anxiety,
        questionCount: 20,
        estimatedMinutes: 10,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SelfCheckTest(
        id: 'psis',
        type: SelfCheckTestType.psis,
        title: 'PSIS 심리기술 검사',
        description: '스포츠에 필요한 심리적 기술 수준을 평가합니다.',
        category: SelfCheckCategory.concentration,
        questionCount: 18,
        estimatedMinutes: 9,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      SelfCheckTest(
        id: 'msci',
        type: SelfCheckTestType.msci,
        title: 'MSCI 정신기술 검사',
        description: '경기에서의 정신적 기술과 대처 능력을 평가합니다.',
        category: SelfCheckCategory.confidence,
        questionCount: 16,
        estimatedMinutes: 8,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SelfCheckTest(
        id: 'smq',
        type: SelfCheckTestType.smq,
        title: 'SMQ 스포츠 동기 검사',
        description: '스포츠 참여 동기와 동기 유형을 분석합니다.',
        category: SelfCheckCategory.motivation,
        questionCount: 14,
        estimatedMinutes: 7,
        questions: [],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  // === 추천 검사 목록 ===
  List<SelfCheckTest> getRecommendedTests() {
    final allTests = getMockTests();
    return allTests.take(3).toList();
  }

  // === 검사별 질문 생성 ===
  SelfCheckTest getTestWithQuestions(String testId) {
    final tests = getMockTests();
    final test = tests.firstWhere(
      (t) => t.id == testId,
      orElse: () => throw Exception('검사를 찾을 수 없습니다.'),
    );

    return test.copyWith(questions: _getQuestionsForTest(test.type));
  }

  List<SelfCheckQuestion> _getQuestionsForTest(SelfCheckTestType testType) {
    final answers = _getLikert5Answers();

    switch (testType) {
      case SelfCheckTestType.tops2:
        return _generateQuestions('tops2', [
          '나는 구체적이고 현실적인 목표를 세운다.',
          '나는 경기 전에 긴장을 푸는 방법을 안다.',
          '나는 어려운 상황에서도 자신감을 유지한다.',
          '나는 경기 중에 집중력을 유지할 수 있다.',
          '나는 실수를 해도 빨리 회복할 수 있다.',
          '나는 압박 상황에서도 차분함을 유지한다.',
          '나는 경기 전략을 세우고 실행할 수 있다.',
          '나는 팀원들과 효과적으로 소통할 수 있다.',
          '나는 부정적인 생각을 긍정적으로 바꿀 수 있다.',
          '나는 에너지 수준을 적절히 조절할 수 있다.',
          '나는 경기 중 감정을 효과적으로 관리한다.',
          '나는 어떤 상황에서도 최선을 다한다.',
          '나는 예상치 못한 상황에 잘 적응한다.',
          '나는 경기 후 성과를 객관적으로 평가한다.',
          '나는 지속적으로 실력 향상을 위해 노력한다.',
        ], answers);

      case SelfCheckTestType.csai2:
        return _generateQuestions('csai2', [
          '중요한 경기 전에 걱정이 많아진다.',
          '경기 전에 심장이 빨리 뛴다.',
          '나는 내 능력에 확신을 가지고 있다.',
          '실패할 것 같은 생각이 자주 든다.',
          '몸이 긴장되고 경직된다.',
          '목표를 달성할 수 있다고 확신한다.',
          '다른 사람들이 나를 어떻게 평가할지 걱정된다.',
          '손이나 다리가 떨린다.',
          '나는 어떤 도전이든 잘 해낼 수 있다.',
          '집중하려고 해도 불안한 생각이 방해한다.',
          '배가 아프거나 소화가 안 된다.',
          '내가 최선의 수행을 할 수 있다고 느낀다.',
          '경기에서 실수할까 봐 두렵다.',
          '근육이 긴장되어 있다.',
          '내 실력을 보여줄 자신이 있다.',
          '완벽하게 해야 한다는 압박감을 느낀다.',
          '호흡이 빨라지거나 가빠진다.',
          '어려운 상황도 극복할 수 있다고 믿는다.',
          '다른 선수들과 비교되는 것이 부담스럽다.',
          '중요한 순간에 내 실력을 발휘할 수 있다.',
        ], answers);

      case SelfCheckTestType.psis:
        return _generateQuestions('psis', [
          '나는 중요한 순간에 집중력을 유지할 수 있다.',
          '나는 나 자신의 능력을 믿는다.',
          '나는 최선을 다하려는 강한 의욕이 있다.',
          '나는 경기 상황을 머릿속으로 미리 그려본다.',
          '나는 스트레스를 받을 때 이완 기법을 사용한다.',
          '나는 부정적인 생각을 긍정적으로 바꿀 수 있다.',
          '나는 실수를 해도 금세 다음 플레이에 집중한다.',
          '나는 어려운 상황에서도 침착함을 유지한다.',
          '나는 경기 전에 구체적인 계획을 세운다.',
          '나는 팀원들과 원활하게 소통한다.',
          '나는 압박감 속에서도 최고의 퍼포먼스를 낸다.',
          '나는 경기 후 자신의 수행을 객관적으로 분석한다.',
          '나는 지속적으로 기술 향상을 위해 노력한다.',
          '나는 경기 중 감정을 효과적으로 조절한다.',
          '나는 목표를 달성하기 위해 체계적으로 준비한다.',
          '나는 어떤 상대와 경기해도 자신 있다.',
          '나는 부상이나 실패를 빨리 극복한다.',
          '나는 현재 순간에 완전히 몰입할 수 있다.',
        ], answers);

      case SelfCheckTestType.msci:
        return _generateQuestions('msci', [
          '나는 압박감 속에서도 침착함을 유지한다.',
          '나는 어려운 도전을 즐긴다.',
          '나는 역경을 이겨낼 수 있다고 믿는다.',
          '나는 실패를 학습의 기회로 생각한다.',
          '나는 중요한 경기에서 더욱 집중한다.',
          '나는 팀의 리더 역할을 잘 수행한다.',
          '나는 경기 전략을 빠르게 조정할 수 있다.',
          '나는 감정적으로 흔들리지 않는다.',
          '나는 완벽한 수행을 위해 세부사항에 신경 쓴다.',
          '나는 다른 선수들을 격려하고 지원한다.',
          '나는 경기 중 빠른 의사결정을 내린다.',
          '나는 자신만의 경기 루틴을 가지고 있다.',
          '나는 경기 결과에 상관없이 최선을 다한다.',
          '나는 상대방의 전술 변화에 빠르게 적응한다.',
          '나는 경기 후에도 긍정적인 마음을 유지한다.',
          '나는 항상 더 나은 선수가 되기 위해 노력한다.',
        ], answers);

      case SelfCheckTestType.smq:
        return _generateQuestions('smq', [
          '나는 재미있기 때문에 스포츠를 한다.',
          '나는 다른 사람들에게 인정받기 위해 운동한다.',
          '나는 새로운 기술을 배우는 것이 즐겁다.',
          '나는 승리하기 위해 운동한다.',
          '나는 건강을 위해 운동한다.',
          '나는 친구들과 함께하기 위해 운동한다.',
          '나는 스트레스 해소를 위해 운동한다.',
          '나는 자신감을 얻기 위해 운동한다.',
          '나는 경쟁하는 것이 좋아서 운동한다.',
          '나는 목표를 달성했을 때의 성취감이 좋다.',
          '나는 완벽한 기술 동작을 구사하고 싶다.',
          '나는 체력을 기르기 위해 운동한다.',
          '나는 운동할 때 몰입감을 느낀다.',
          '나는 더 나은 선수가 되기 위해 계속 노력한다.',
        ], answers);
    }
  }

  List<SelfCheckQuestion> _generateQuestions(
    String prefix,
    List<String> questionTexts,
    List<SelfCheckAnswer> answers,
  ) {
    return questionTexts.asMap().entries.map((entry) {
      final index = entry.key;
      final text = entry.value;

      return SelfCheckQuestion(
        id: '${prefix}_${index + 1}',
        order: index + 1,
        text: text,
        answerType: AnswerType.likert5,
        answers: answers,
        category: _getCategoryForQuestion(prefix, index),
      );
    }).toList();
  }

  String? _getCategoryForQuestion(String testPrefix, int questionIndex) {
    // 각 검사별로 카테고리를 간단하게 순환 배정
    final categories = {
      'tops2': ['목표설정', '이완', '자신감', '집중력', '회복력'],
      'csai2': ['인지적 불안', '신체적 불안', '자신감'],
      'psis': ['집중력', '자신감', '동기', '심상훈련', '이완기술'],
      'msci': ['정신력', '도전의식', '리더십'],
      'smq': ['내재적 동기', '외재적 동기', '사회적 동기'],
    };

    final testCategories = categories[testPrefix];
    if (testCategories == null) return null;

    return testCategories[questionIndex % testCategories.length];
  }

  // === 5점 척도 답변 옵션 ===
  List<SelfCheckAnswer> _getLikert5Answers() {
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

  // === Mock 결과 생성 ===
  SelfCheckResult generateMockResult(String testId, List<UserAnswer> answers) {
    final tests = getMockTests();
    final test = tests.firstWhere((t) => t.id == testId);
    final totalScore = answers.fold(0, (sum, answer) => sum + answer.score);
    final maxScore = test.questionCount * 5;
    final percentage = (totalScore / maxScore * 100).roundToDouble();

    RiskLevel riskLevel;
    if (percentage >= 80) {
      riskLevel = RiskLevel.low;
    } else if (percentage >= 60) {
      riskLevel = RiskLevel.moderate;
    } else {
      riskLevel = RiskLevel.high;
    }

    return SelfCheckResult(
      id: 'result_${testId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_123',
      test: test,
      answers: answers,
      totalScore: totalScore,
      maxScore: maxScore,
      percentage: percentage,
      riskLevel: riskLevel,
      categoryScores: _calculateCategoryScores(answers, test),
      interpretation: _generateInterpretation(percentage),
      recommendations: _generateRecommendations(percentage, test.type),
      completedAt: DateTime.now(),
    );
  }

  Map<String, int> _calculateCategoryScores(
    List<UserAnswer> answers,
    SelfCheckTest test,
  ) {
    final categoryScores = <String, int>{};
    final questions = _getQuestionsForTest(test.type);

    for (final answer in answers) {
      final question = questions.firstWhere((q) => q.id == answer.questionId);
      final category = question.category ?? '기타';
      categoryScores[category] = (categoryScores[category] ?? 0) + answer.score;
    }

    return categoryScores;
  }

  String _generateInterpretation(double percentage) {
    if (percentage >= 80) {
      return '매우 좋은 상태입니다. 현재 수준을 유지하며 지속적인 발전을 추구하세요.';
    } else if (percentage >= 60) {
      return '양호한 상태입니다. 일부 영역에서 개선의 여지가 있으니 전문가의 조언을 구해보세요.';
    } else {
      return '개선이 필요한 상태입니다. 체계적인 심리 훈련을 통해 향상시킬 수 있습니다.';
    }
  }

  List<String> _generateRecommendations(
    double percentage,
    SelfCheckTestType testType,
  ) {
    final baseRecommendations = <String>[];

    if (percentage >= 80) {
      baseRecommendations.addAll(['현재 수준 유지를 위한 정기적인 점검', '고급 심리기술 훈련 참여']);
    } else if (percentage >= 60) {
      baseRecommendations.addAll(['주 2-3회 이완 훈련 실시', '목표설정 및 계획 수립 연습']);
    } else {
      baseRecommendations.addAll(['전문가와의 정기적인 상담', '체계적인 심리기술 훈련 프로그램 참여']);
    }

    // 검사별 특화 추천사항
    switch (testType) {
      case SelfCheckTestType.tops2:
        baseRecommendations.add('목표 설정 및 수행 계획 수립');
        break;
      case SelfCheckTestType.csai2:
        baseRecommendations.add('불안 상황 노출 연습');
        break;
      case SelfCheckTestType.psis:
        baseRecommendations.add('집중력 향상 훈련');
        break;
      case SelfCheckTestType.msci:
        baseRecommendations.add('정신력 강화 훈련');
        break;
      case SelfCheckTestType.smq:
        baseRecommendations.add('내재적 동기 강화 방법 탐색');
        break;
    }

    return baseRecommendations;
  }

  // === Mock 최근 결과 ===
  List<SelfCheckResult> getMockRecentResults(int limit) {
    final tests = getMockTests();
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
          maxScore: test.questionCount * 5,
          percentage: 65.0 + (i * 5),
          riskLevel: i == 0 ? RiskLevel.moderate : RiskLevel.low,
          categoryScores: _calculateCategoryScores(answers, test),
          interpretation: _generateInterpretation(65.0 + (i * 5)),
          recommendations: _generateRecommendations(65.0 + (i * 5), test.type),
          completedAt: DateTime.now().subtract(Duration(days: i + 1)),
        ),
      );
    }

    return results;
  }

  List<UserAnswer> _generateMockAnswers(SelfCheckTest test) {
    final questions = _getQuestionsForTest(test.type);
    final answers = <UserAnswer>[];

    for (final question in questions) {
      final score = 3 + (DateTime.now().millisecondsSinceEpoch % 2);
      answers.add(
        UserAnswer(
          questionId: question.id,
          answerId: question.answers[score - 1].id,
          score: score,
          answeredAt: DateTime.now(),
        ),
      );
    }

    return answers;
  }
}
