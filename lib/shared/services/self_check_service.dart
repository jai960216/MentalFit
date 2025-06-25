import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/self_check_models.dart';
import 'firestore_service.dart';

const List<SelfCheckAnswer> likert5Answers = [
  SelfCheckAnswer(id: 'likert5_1', text: '1점', score: 1, order: 1),
  SelfCheckAnswer(id: 'likert5_2', text: '2점', score: 2, order: 2),
  SelfCheckAnswer(id: 'likert5_3', text: '3점', score: 3, order: 3),
  SelfCheckAnswer(id: 'likert5_4', text: '4점', score: 4, order: 4),
  SelfCheckAnswer(id: 'likert5_5', text: '5점', score: 5, order: 5),
];

class SelfCheckService {
  static SelfCheckService? _instance;
  late FirebaseFirestore _firestore;
  late FirestoreService _firestoreService;
  late CollectionReference _selfCheckResultsCollection;

  SelfCheckService._internal();

  static Future<SelfCheckService> getInstance() async {
    _instance ??= SelfCheckService._internal();
    await _instance!._initialize();
    return _instance!;
  }

  /// 서비스 초기화
  Future<void> _initialize() async {
    try {
      _firestore = FirebaseFirestore.instance;
      _firestoreService = await FirestoreService.getInstance();
      _selfCheckResultsCollection = _firestore.collection('self_check_results');
      debugPrint('SelfCheckService 초기화 완료');
    } catch (e) {
      debugPrint('SelfCheckService 초기화 오류: $e');
      rethrow;
    }
  }

  // 앱 내 고정 스포츠 심리 검사 리스트
  List<SelfCheckTest> get _availableTests => [
    // TOPS-2 (준비중)
    // SelfCheckTest(
    //   id: 'tops2',
    //   ...
    // ),
    SelfCheckTest(
      id: 'csai2',
      type: SelfCheckTestType.csai2,
      title: 'CSAI-2 (Competitive State Anxiety Inventory-2)',
      description: '경기 전 불안의 인지적, 신체적 요소 + 자신감을 구분해 측정. 국내외 연구 다수.',
      category: SelfCheckCategory.anxiety,
      questionCount: 27,
      estimatedMinutes: 7,
      questions:
          _generateCSAI2Questions()
              .map(
                (q) => SelfCheckQuestion(
                  id: q['id'],
                  order: q['order'],
                  text: q['text'],
                  answerType: AnswerType.likert5,
                  answers: likert5Answers,
                  category: q['category'],
                ),
              )
              .toList(),
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
    ),
    // POMS (준비중)
    // SelfCheckTest(
    //   id: 'poms',
    //   ...
    // ),
    // ACSI-28 (준비중)
    // SelfCheckTest(
    //   id: 'acsi28',
    //   ...
    // ),
    // SCAT (준비중)
    // SelfCheckTest(
    //   id: 'scat',
    //   ...
    // ),
    // MTQ48 (준비중)
    // SelfCheckTest(
    //   id: 'mtq48',
    //   ...
    // ),
    // RESTQ (준비중)
    // SelfCheckTest(
    //   id: 'restq',
    //   ...
    // ),
  ];

  List<SelfCheckTest> getAvailableTests() {
    return _availableTests;
  }

  /// 추천 검사 조회
  Future<List<SelfCheckTest>> getRecommendedTests() async {
    try {
      final snapshot =
          await _firestore
              .collection('self_check_tests')
              .where('isActive', isEqualTo: true)
              .limit(2)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SelfCheckTest.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('추천 검사 조회 오류: $e');
      return [];
    }
  }

  /// 특정 검사 조회
  Future<SelfCheckTest> getTestById(String testId) async {
    // 1. 앱 내 고정 데이터에서 먼저 찾기
    final local = _availableTests.where((t) => t.id == testId).toList();
    if (local.isNotEmpty) return local.first;

    // 2. Firestore에서 찾기 (없으면 예외)
    try {
      final doc =
          await _firestore.collection('self_check_tests').doc(testId).get();
      if (!doc.exists) {
        throw Exception('검사를 찾을 수 없습니다: $testId');
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return SelfCheckTest.fromJson(data);
    } catch (e) {
      debugPrint('검사 조회 오류: $e');
      rethrow;
    }
  }

  /// 최근 검사 결과 조회
  Future<List<SelfCheckResult>> getRecentResults({int limit = 10}) async {
    try {
      final snapshot =
          await _selfCheckResultsCollection
              .orderBy('completedAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return SelfCheckResult.fromJson(data);
      }).toList();
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
      debugPrint('검사 제출 시작: $testId, 답변 수: ${answers.length}');

      final test = await getTestById(testId);
      final result = _calculateTestResult(test, answers);

      // Firestore에 결과 저장
      final resultData = result.toJson();
      resultData['completedAt'] = Timestamp.fromDate(result.completedAt);

      final docRef = await _selfCheckResultsCollection.add(resultData);
      resultData['id'] = docRef.id;

      debugPrint('검사 제출 완료: ${result.id}');
      return SelfCheckResult.fromJson(resultData);
    } catch (e) {
      debugPrint('검사 제출 오류: $e');
      throw Exception('검사 제출에 실패했습니다: ${e.toString()}');
    }
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

  /// 기본 검사 데이터 초기화
  Future<void> initializeDefaultTests() async {
    try {
      // 컬렉션이 비어있는지 확인
      final snapshot =
          await _firestore.collection('self_check_tests').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('기본 검사 데이터가 이미 존재합니다.');
        return;
      }

      // 기본 검사 데이터 생성
      final defaultTests = [
        {
          'type': SelfCheckTestType.tops2.code,
          'title': 'TOPS-2 수행전략 검사',
          'description':
              '스포츠 수행 전략과 심리적 기술을 평가하는 검사입니다. 운동선수의 정신력과 수행 능력을 종합적으로 분석합니다.',
          'category': SelfCheckCategory.performance.id,
          'questionCount': 64,
          'estimatedMinutes': 15,
          'questions': _generateTOPS2Questions(),
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'type': SelfCheckTestType.csai2.code,
          'title': 'CSAI-2 경쟁불안 검사',
          'description':
              '경기 상황에서의 불안 수준을 측정하는 검사입니다. 인지불안, 신체불안, 자신감을 각각 평가합니다.',
          'category': SelfCheckCategory.anxiety.id,
          'questionCount': 27,
          'estimatedMinutes': 8,
          'questions': _generateCSAI2Questions(),
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'type': SelfCheckTestType.psis.code,
          'title': 'PSIS 스포츠 심리기술 검사',
          'description': '스포츠에 필요한 다양한 심리적 기술들을 종합적으로 평가합니다.',
          'category': SelfCheckCategory.concentration.id,
          'questionCount': 45,
          'estimatedMinutes': 12,
          'questions': _generatePSISQuestions(),
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      // Firestore에 데이터 추가
      final batch = _firestore.batch();
      for (final test in defaultTests) {
        final docRef = _firestore.collection('self_check_tests').doc();
        batch.set(docRef, test);
      }
      await batch.commit();

      debugPrint('기본 검사 데이터 초기화 완료');
    } catch (e) {
      debugPrint('기본 검사 데이터 초기화 오류: $e');
      rethrow;
    }
  }

  /// TOPS-2 질문 생성
  List<Map<String, dynamic>> _generateTOPS2Questions() {
    final questions = <Map<String, dynamic>>[];
    final categories = ['기본 기술', '심리 기술', '인지 전략', '수행 전략'];

    for (int i = 1; i <= 64; i++) {
      final categoryIndex = ((i - 1) ~/ 16) % categories.length;
      questions.add({
        'id': 'tops2_q$i',
        'order': i,
        'text': _getTOPS2QuestionText(i),
        'answerType': AnswerType.likert5.id,
        'answers': _generateLikert5Answers(),
        'category': categories[categoryIndex],
      });
    }
    return questions;
  }

  /// CSAI-2 질문 생성
  List<Map<String, dynamic>> _generateCSAI2Questions() {
    final questions = <Map<String, dynamic>>[];
    final categories = ['인지불안', '신체불안', '자신감'];
    for (int i = 1; i <= 27; i++) {
      final categoryIndex = ((i - 1) ~/ 9) % categories.length;
      questions.add({
        'id': 'csai2_q$i',
        'order': i,
        'text': _getCSAI2QuestionText(i),
        'answerType': AnswerType.likert5.id,
        'answers': _generateLikert5Answers(),
        'category': categories[categoryIndex],
      });
    }
    return questions;
  }

  /// PSIS 질문 생성
  List<Map<String, dynamic>> _generatePSISQuestions() {
    final questions = <Map<String, dynamic>>[];
    final categories = ['집중력', '자신감', '동기'];

    for (int i = 1; i <= 45; i++) {
      final categoryIndex = ((i - 1) ~/ 15) % categories.length;
      questions.add({
        'id': 'psis_q$i',
        'order': i,
        'text': _getPSISQuestionText(i),
        'answerType': AnswerType.likert5.id,
        'answers': _generateLikert5Answers(),
        'category': categories[categoryIndex],
      });
    }
    return questions;
  }

  /// 5점 척도 답변 생성
  List<Map<String, dynamic>> _generateLikert5Answers() {
    return [
      {'id': 'ans1', 'text': '전혀 그렇지 않다', 'score': 1, 'order': 1},
      {'id': 'ans2', 'text': '그렇지 않다', 'score': 2, 'order': 2},
      {'id': 'ans3', 'text': '보통이다', 'score': 3, 'order': 3},
      {'id': 'ans4', 'text': '그렇다', 'score': 4, 'order': 4},
      {'id': 'ans5', 'text': '매우 그렇다', 'score': 5, 'order': 5},
    ];
  }

  /// TOPS-2 질문 텍스트
  String _getTOPS2QuestionText(int num) {
    final tops2Questions = [
      '목표를 설정할 때 구체적이고 명확하게 설정한다',
      '경기 중 실수를 했을 때 빠르게 집중력을 회복한다',
      '어려운 상황에서도 자신감을 유지한다',
      '경기 전 긴장을 적절히 조절할 수 있다',
      '팀원들과 효과적으로 소통한다',
      '부정적인 생각을 긍정적으로 바꿀 수 있다',
      '스트레스 상황에서도 침착함을 유지한다',
      '자신의 감정을 잘 조절할 수 있다',
      '동기를 스스로 높일 수 있다',
      '집중력을 오래 유지할 수 있다',
      '심리적 압박감을 잘 견딘다',
      '실패를 성공의 밑거름으로 삼는다',
      '자신의 강점을 잘 활용한다',
      '약점을 보완하기 위해 노력한다',
      '팀원들과의 관계를 잘 유지한다',
      '경기 전 준비를 철저히 한다',
    ];

    if (num <= tops2Questions.length) {
      return tops2Questions[num - 1];
    }
    return '목표 달성을 위해 꾸준히 노력한다 ($num)';
  }

  /// CSAI-2 질문 텍스트
  String _getCSAI2QuestionText(int num) {
    final csai2Questions = [
      // 인지적 불안(1~9)
      '나는 이번 시합이 신경이 쓰인다.',
      '나는 지금 이 순간 내 자신의 능력에 대해 의심스럽다.',
      '나는 이번 시합이 잘 풀리지 않을 것 같은 예감이 든다.',
      '나는 이 순간 패배에 대한 걱정이 된다.',
      '나는 이번 시합이 부담이 된다.',
      '나는 형편없는 시합이 될까 걱정된다.',
      '나는 지금 내 목표에 도달할 수 있을지 걱정이 된다.',
      '나는 다른 사람이 내 경기를 보고 실망할까봐 걱정이 된다.',
      '나는 지금 이 순간 집중을 할 수 없을 것 같아 걱정이다.',
      // 신체적 불안(10~18)
      '나는 지금 이 순간 이 경기에 신경이 쓰인다.',
      '나는 지금 이 순간 마음이 초조하다.',
      '나의 온몸이 긴장되어 있다.',
      '나는 지금 속이 거북하다.',
      '지금 나의 몸은 편안하게 이완되어 있다. (역채점)',
      '나는 지금 이 순간 내 심장이 마구 뛰는 것을 느낀다.',
      '나는 지금 이 순간 속이 철렁한다.',
      '나는 지금 이 순간 손에 땀이 난다.',
      '나는 지금 이 순간 몸이 뻣뻣해짐을 느낀다.',
      // 자신감(19~27)
      '나는 지금 마음이 홀가분하다.',
      '나는 지금 이 순간 안락한 기분을 느낀다.',
      '나는 이번 시합에 자신감이 있다.',
      '나는 지금 이 순간 마음이 든든하다.',
      '나는 지금 이 도전을 감당할 자신이 있다.',
      '나는 시합이 잘될 것을 확신한다.',
      '나는 지금 내 마음이 편안해 있음을 느낀다.',
      '나는 목표에 도달하는 나를 상상하기 때문에 자신이 있다.',
      '나는 지금 이 순간 정신적 압박을 이겨낼 자신이 있다.',
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
      '목표를 향해 꾸준히 노력한다',
      '실패를 성공의 밑거름으로 삼는다',
      '자신의 강점을 잘 활용한다',
      '약점을 보완하기 위해 노력한다',
      '팀원들과의 관계를 잘 유지한다',
      '경기 전 준비를 철저히 한다',
      '경기 중에 침착함을 유지한다',
      '자신의 실력을 믿는다',
      '어려운 상황에서도 포기하지 않는다',
      '성공적인 결과를 기대한다',
    ];

    if (num <= psisQuestions.length) {
      return psisQuestions[num - 1];
    }
    return '심리적 압박감을 잘 견딘다 ($num)';
  }
}
