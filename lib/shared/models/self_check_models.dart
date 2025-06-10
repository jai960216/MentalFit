import 'package:flutter/material.dart';
import '../../core/config/app_colors.dart';

// === 자가진단 검사 유형 ===
enum SelfCheckTestType {
  tops2('TOPS2', 'Test of Performance Strategies-2'),
  csai2('CSAI-2', 'Competitive State Anxiety Inventory-2'),
  psis('PSIS', 'Psychological Skills Inventory for Sports'),
  msci('MSCI', 'Mental Skills for Competition Inventory'),
  smq('SMQ', 'Sport Motivation Questionnaire');

  const SelfCheckTestType(this.code, this.fullName);

  final String code;
  final String fullName;
}

// === 검사 카테고리 ===
enum SelfCheckCategory {
  anxiety('anxiety', '불안 관리', Icons.psychology, AppColors.error),
  performance('performance', '수행 전략', Icons.trending_up, AppColors.primary),
  motivation(
    'motivation',
    '동기 부여',
    Icons.energy_savings_leaf,
    AppColors.success,
  ),
  concentration(
    'concentration',
    '집중력',
    Icons.center_focus_strong,
    AppColors.info,
  ),
  confidence('confidence', '자신감', Icons.emoji_events, AppColors.warning);

  const SelfCheckCategory(this.id, this.name, this.icon, this.color);

  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

// === 위험도 레벨 ===
enum RiskLevel {
  low('low', '양호', '정상 범위입니다', AppColors.success),
  moderate('moderate', '보통', '주의가 필요합니다', AppColors.warning),
  high('high', '높음', '전문가 상담을 권장합니다', AppColors.error);

  const RiskLevel(this.id, this.name, this.description, this.color);

  final String id;
  final String name;
  final String description;
  final Color color;

  static RiskLevel fromScore(int score, int maxScore) {
    final percentage = (score / maxScore) * 100;
    if (percentage >= 70) return RiskLevel.high;
    if (percentage >= 40) return RiskLevel.moderate;
    return RiskLevel.low;
  }
}

// === 답변 유형 ===
enum AnswerType {
  likert5('likert5', '5점 척도', 5),
  likert7('likert7', '7점 척도', 7),
  yesNo('yesNo', '예/아니오', 2),
  multiple('multiple', '객관식', 0);

  const AnswerType(this.id, this.name, this.maxScore);

  final String id;
  final String name;
  final int maxScore;
}

// === 자가진단 검사 모델 ===
class SelfCheckTest {
  final String id;
  final SelfCheckTestType type;
  final String title;
  final String description;
  final SelfCheckCategory category;
  final int questionCount;
  final int estimatedMinutes;
  final List<SelfCheckQuestion> questions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SelfCheckTest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.questionCount,
    required this.estimatedMinutes,
    required this.questions,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SelfCheckTest.fromJson(Map<String, dynamic> json) {
    return SelfCheckTest(
      id: json['id'] as String,
      type: SelfCheckTestType.values.firstWhere(
        (t) => t.code == json['type'],
        orElse: () => SelfCheckTestType.tops2,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      category: SelfCheckCategory.values.firstWhere(
        (c) => c.id == json['category'],
        orElse: () => SelfCheckCategory.performance,
      ),
      questionCount: json['questionCount'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map(
                (q) => SelfCheckQuestion.fromJson(q as Map<String, dynamic>),
              )
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.code,
      'title': title,
      'description': description,
      'category': category.id,
      'questionCount': questionCount,
      'estimatedMinutes': estimatedMinutes,
      'questions': questions.map((q) => q.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SelfCheckTest copyWith({
    String? id,
    SelfCheckTestType? type,
    String? title,
    String? description,
    SelfCheckCategory? category,
    int? questionCount,
    int? estimatedMinutes,
    List<SelfCheckQuestion>? questions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SelfCheckTest(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      questionCount: questionCount ?? this.questionCount,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// === 자가진단 질문 모델 ===
class SelfCheckQuestion {
  final String id;
  final int order;
  final String text;
  final AnswerType answerType;
  final List<SelfCheckAnswer> answers;
  final String? category; // 하위 카테고리 (예: 인지불안, 신체불안)
  final bool isRequired;

  const SelfCheckQuestion({
    required this.id,
    required this.order,
    required this.text,
    required this.answerType,
    required this.answers,
    this.category,
    this.isRequired = true,
  });

  factory SelfCheckQuestion.fromJson(Map<String, dynamic> json) {
    return SelfCheckQuestion(
      id: json['id'] as String,
      order: json['order'] as int,
      text: json['text'] as String,
      answerType: AnswerType.values.firstWhere(
        (t) => t.id == json['answerType'],
        orElse: () => AnswerType.likert5,
      ),
      answers:
          (json['answers'] as List<dynamic>)
              .map((a) => SelfCheckAnswer.fromJson(a as Map<String, dynamic>))
              .toList(),
      category: json['category'] as String?,
      isRequired: json['isRequired'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'text': text,
      'answerType': answerType.id,
      'answers': answers.map((a) => a.toJson()).toList(),
      'category': category,
      'isRequired': isRequired,
    };
  }

  SelfCheckQuestion copyWith({
    String? id,
    int? order,
    String? text,
    AnswerType? answerType,
    List<SelfCheckAnswer>? answers,
    String? category,
    bool? isRequired,
  }) {
    return SelfCheckQuestion(
      id: id ?? this.id,
      order: order ?? this.order,
      text: text ?? this.text,
      answerType: answerType ?? this.answerType,
      answers: answers ?? this.answers,
      category: category ?? this.category,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

// === 자가진단 답변 옵션 모델 ===
class SelfCheckAnswer {
  final String id;
  final String text;
  final int score;
  final int order;

  const SelfCheckAnswer({
    required this.id,
    required this.text,
    required this.score,
    required this.order,
  });

  factory SelfCheckAnswer.fromJson(Map<String, dynamic> json) {
    return SelfCheckAnswer(
      id: json['id'] as String,
      text: json['text'] as String,
      score: json['score'] as int,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'score': score, 'order': order};
  }

  SelfCheckAnswer copyWith({String? id, String? text, int? score, int? order}) {
    return SelfCheckAnswer(
      id: id ?? this.id,
      text: text ?? this.text,
      score: score ?? this.score,
      order: order ?? this.order,
    );
  }
}

// === 사용자 답변 모델 ===
class UserAnswer {
  final String questionId;
  final String answerId;
  final int score;
  final DateTime answeredAt;

  const UserAnswer({
    required this.questionId,
    required this.answerId,
    required this.score,
    required this.answeredAt,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      questionId: json['questionId'] as String,
      answerId: json['answerId'] as String,
      score: json['score'] as int,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answerId': answerId,
      'score': score,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  UserAnswer copyWith({
    String? questionId,
    String? answerId,
    int? score,
    DateTime? answeredAt,
  }) {
    return UserAnswer(
      questionId: questionId ?? this.questionId,
      answerId: answerId ?? this.answerId,
      score: score ?? this.score,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}

// === 자가진단 결과 모델 ===
class SelfCheckResult {
  final String id;
  final String userId;
  final SelfCheckTest test;
  final List<UserAnswer> answers;
  final int totalScore;
  final int maxScore;
  final double percentage;
  final RiskLevel riskLevel;
  final Map<String, int> categoryScores; // 카테고리별 점수
  final String? interpretation; // 결과 해석
  final List<String> recommendations; // 추천사항
  final DateTime completedAt;
  final DateTime? viewedAt;

  const SelfCheckResult({
    required this.id,
    required this.userId,
    required this.test,
    required this.answers,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.riskLevel,
    required this.categoryScores,
    this.interpretation,
    required this.recommendations,
    required this.completedAt,
    this.viewedAt,
  });

  factory SelfCheckResult.fromJson(Map<String, dynamic> json) {
    return SelfCheckResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      test: SelfCheckTest.fromJson(json['test'] as Map<String, dynamic>),
      answers:
          (json['answers'] as List<dynamic>)
              .map((a) => UserAnswer.fromJson(a as Map<String, dynamic>))
              .toList(),
      totalScore: json['totalScore'] as int,
      maxScore: json['maxScore'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      riskLevel: RiskLevel.values.firstWhere(
        (r) => r.id == json['riskLevel'],
        orElse: () => RiskLevel.low,
      ),
      categoryScores: Map<String, int>.from(json['categoryScores'] as Map),
      interpretation: json['interpretation'] as String?,
      recommendations: List<String>.from(json['recommendations'] as List),
      completedAt: DateTime.parse(json['completedAt'] as String),
      viewedAt:
          json['viewedAt'] != null
              ? DateTime.parse(json['viewedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'test': test.toJson(),
      'answers': answers.map((a) => a.toJson()).toList(),
      'totalScore': totalScore,
      'maxScore': maxScore,
      'percentage': percentage,
      'riskLevel': riskLevel.id,
      'categoryScores': categoryScores,
      'interpretation': interpretation,
      'recommendations': recommendations,
      'completedAt': completedAt.toIso8601String(),
      'viewedAt': viewedAt?.toIso8601String(),
    };
  }

  SelfCheckResult copyWith({
    String? id,
    String? userId,
    SelfCheckTest? test,
    List<UserAnswer>? answers,
    int? totalScore,
    int? maxScore,
    double? percentage,
    RiskLevel? riskLevel,
    Map<String, int>? categoryScores,
    String? interpretation,
    List<String>? recommendations,
    DateTime? completedAt,
    DateTime? viewedAt,
  }) {
    return SelfCheckResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      test: test ?? this.test,
      answers: answers ?? this.answers,
      totalScore: totalScore ?? this.totalScore,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      riskLevel: riskLevel ?? this.riskLevel,
      categoryScores: categoryScores ?? this.categoryScores,
      interpretation: interpretation ?? this.interpretation,
      recommendations: recommendations ?? this.recommendations,
      completedAt: completedAt ?? this.completedAt,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }
}

// === 자가진단 상태 모델 ===
class SelfCheckState {
  final List<SelfCheckTest> availableTests;
  final List<SelfCheckTest> recommendedTests;
  final List<SelfCheckResult> recentResults;
  final SelfCheckTest? currentTest;
  final List<UserAnswer> currentAnswers;
  final int currentQuestionIndex;
  final bool isLoading;
  final String? error;

  const SelfCheckState({
    this.availableTests = const [],
    this.recommendedTests = const [],
    this.recentResults = const [],
    this.currentTest,
    this.currentAnswers = const [],
    this.currentQuestionIndex = 0,
    this.isLoading = false,
    this.error,
  });

  SelfCheckState copyWith({
    List<SelfCheckTest>? availableTests,
    List<SelfCheckTest>? recommendedTests,
    List<SelfCheckResult>? recentResults,
    SelfCheckTest? currentTest,
    List<UserAnswer>? currentAnswers,
    int? currentQuestionIndex,
    bool? isLoading,
    String? error,
  }) {
    return SelfCheckState(
      availableTests: availableTests ?? this.availableTests,
      recommendedTests: recommendedTests ?? this.recommendedTests,
      recentResults: recentResults ?? this.recentResults,
      currentTest: currentTest ?? this.currentTest,
      currentAnswers: currentAnswers ?? this.currentAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // === 유틸리티 메서드 ===

  bool get hasCurrentTest => currentTest != null;

  bool get isTestInProgress => hasCurrentTest && currentAnswers.isNotEmpty;

  bool get isTestCompleted =>
      hasCurrentTest && currentAnswers.length == currentTest!.questions.length;

  double get testProgress =>
      hasCurrentTest
          ? currentAnswers.length / currentTest!.questions.length
          : 0.0;

  SelfCheckQuestion? get currentQuestion =>
      hasCurrentTest && currentQuestionIndex < currentTest!.questions.length
          ? currentTest!.questions[currentQuestionIndex]
          : null;

  bool get canGoToPreviousQuestion => currentQuestionIndex > 0;

  bool get canGoToNextQuestion =>
      hasCurrentTest &&
      currentQuestionIndex < currentTest!.questions.length - 1;
}
