import '../models/onboarding_model.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/token_manager.dart';

class OnboardingService {
  static OnboardingService? _instance;
  late ApiClient _apiClient;
  late TokenManager _tokenManager;

  // 싱글톤 패턴
  OnboardingService._();

  static Future<OnboardingService> getInstance() async {
    if (_instance == null) {
      _instance = OnboardingService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _apiClient = await ApiClient.getInstance();
    _tokenManager = await TokenManager.getInstance();
  }

  // === 온보딩 데이터 저장 (임시 저장) ===
  Future<bool> saveOnboardingData(OnboardingData data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.saveOnboarding,
        data: data.toJson(),
      );

      return response.success;
    } catch (e) {
      print('온보딩 데이터 저장 오류: $e');
      return false;
    }
  }

  // === 온보딩 데이터 조회 ===
  Future<OnboardingData?> getOnboardingData() async {
    try {
      final response = await _apiClient.get<OnboardingData>(
        ApiEndpoints.getOnboarding,
        fromJson: OnboardingData.fromJson,
      );

      return response.success ? response.data : null;
    } catch (e) {
      print('온보딩 데이터 조회 오류: $e');
      return null;
    }
  }

  // === 온보딩 완료 처리 ===
  Future<OnboardingResult> completeOnboarding(OnboardingData data) async {
    try {
      // 1. 최종 온보딩 데이터 저장
      final completeData = data.copyWith(isCompleted: true);

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.completeOnboarding,
        data: completeData.toJson(),
      );

      if (response.success && response.data != null) {
        final userData = response.data!['user'] as Map<String, dynamic>?;
        final recommendations =
            response.data!['recommendations'] as List<dynamic>?;

        User? updatedUser;
        if (userData != null) {
          updatedUser = User.fromJson(userData);
        }

        List<OnboardingRecommendation> recommendationList = [];
        if (recommendations != null) {
          recommendationList =
              recommendations
                  .map(
                    (item) => OnboardingRecommendation.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();
        }

        return OnboardingResult.success(
          user: updatedUser,
          recommendations: recommendationList,
        );
      } else {
        return OnboardingResult.failure(response.error ?? '온보딩 완료 처리에 실패했습니다.');
      }
    } catch (e) {
      return OnboardingResult.failure('온보딩 완료 중 오류가 발생했습니다: $e');
    }
  }

  // === 단계별 온보딩 데이터 업데이트 ===

  // 1단계: 기본 정보 저장
  Future<bool> saveBasicInfo({
    required String name,
    required String birthDate,
    required String sport,
    String? goal,
  }) async {
    try {
      final data = {
        'step': 1,
        'name': name,
        'birthDate': birthDate,
        'sport': sport,
        'goal': goal,
      };

      final response = await _apiClient.patch(
        ApiEndpoints.saveOnboarding,
        data: data,
      );

      return response.success;
    } catch (e) {
      print('기본 정보 저장 오류: $e');
      return false;
    }
  }

  // 2단계: 심리 상태 저장
  Future<bool> saveMentalState({
    required int stressLevel,
    required int anxietyLevel,
    required int confidenceLevel,
    required int motivationLevel,
  }) async {
    try {
      final data = {
        'step': 2,
        'stressLevel': stressLevel,
        'anxietyLevel': anxietyLevel,
        'confidenceLevel': confidenceLevel,
        'motivationLevel': motivationLevel,
      };

      final response = await _apiClient.patch(
        ApiEndpoints.saveOnboarding,
        data: data,
      );

      return response.success;
    } catch (e) {
      print('심리 상태 저장 오류: $e');
      return false;
    }
  }

  // 3단계: 선호도 저장
  Future<bool> savePreferences({
    required CounselingPreference counselingPreference,
    required List<String> preferredTimes,
  }) async {
    try {
      final data = {
        'step': 3,
        'counselingPreference': counselingPreference.value,
        'preferredTimes': preferredTimes,
      };

      final response = await _apiClient.patch(
        ApiEndpoints.saveOnboarding,
        data: data,
      );

      return response.success;
    } catch (e) {
      print('선호도 저장 오류: $e');
      return false;
    }
  }

  // === 스포츠 종목 목록 조회 ===
  Future<List<SportCategory>> getSportCategories() async {
    try {
      // 실제로는 서버에서 가져오지만, 현재는 Mock 데이터 반환
      await Future.delayed(const Duration(milliseconds: 500));

      return _getMockSportCategories();
    } catch (e) {
      print('스포츠 종목 조회 오류: $e');
      return _getMockSportCategories();
    }
  }

  // === AI 기반 추천 시스템 ===
  Future<List<OnboardingRecommendation>> getPersonalizedRecommendations(
    OnboardingData data,
  ) async {
    try {
      final response = await _apiClient.post<List<dynamic>>(
        '${ApiEndpoints.saveOnboarding}/recommendations',
        data: data.toJson(),
      );

      if (response.success && response.data != null) {
        return response.data!
            .map(
              (item) => OnboardingRecommendation.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      return _getMockRecommendations(data);
    } catch (e) {
      print('추천 조회 오류: $e');
      return _getMockRecommendations(data);
    }
  }

  // === Mock 데이터 생성 메서드들 ===

  List<SportCategory> _getMockSportCategories() {
    return [
      SportCategory(
        name: '구기 종목',
        sports: ['축구', '농구', '배구', '야구', '테니스', '탁구', '배드민턴', '골프'],
      ),
      SportCategory(
        name: '개인 종목',
        sports: ['육상', '수영', '체조', '태권도', '유도', '검도', '복싱', '펜싱'],
      ),
      SportCategory(
        name: '동계 종목',
        sports: ['스키', '스노보드', '피겨스케이팅', '쇼트트랙', '아이스하키', '컬링'],
      ),
      SportCategory(
        name: '기타',
        sports: ['e스포츠', '사격', '양궁', '승마', '요트', '사이클', '트라이애슬론'],
      ),
    ];
  }

  List<OnboardingRecommendation> _getMockRecommendations(OnboardingData data) {
    final recommendations = <OnboardingRecommendation>[];

    // 스트레스 레벨에 따른 추천
    if ((data.stressLevel ?? 0) >= 7) {
      recommendations.add(
        OnboardingRecommendation(
          type: RecommendationType.technique,
          title: '스트레스 관리 기법',
          description: '높은 스트레스 수준이 감지되었습니다. 호흡법과 이완 기법을 통해 스트레스를 관리해보세요.',
          priority: RecommendationPriority.high,
        ),
      );
    }

    // 불안 레벨에 따른 추천
    if ((data.anxietyLevel ?? 0) >= 6) {
      recommendations.add(
        OnboardingRecommendation(
          type: RecommendationType.counseling,
          title: '불안 관리 상담',
          description: '경기 전 불안감이 높으신 것 같습니다. 전문 상담사와의 상담을 권장합니다.',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    // 자신감 레벨에 따른 추천
    if ((data.confidenceLevel ?? 0) <= 4) {
      recommendations.add(
        OnboardingRecommendation(
          type: RecommendationType.program,
          title: '자신감 향상 프로그램',
          description: '자신감을 높이는 다양한 프로그램을 준비했습니다. 단계별로 참여해보세요.',
          priority: RecommendationPriority.medium,
        ),
      );
    }

    // 동기 레벨에 따른 추천
    if ((data.motivationLevel ?? 0) <= 5) {
      recommendations.add(
        OnboardingRecommendation(
          type: RecommendationType.technique,
          title: '동기 부여 전략',
          description: '목표 설정과 동기 유지를 위한 전략을 학습해보세요.',
          priority: RecommendationPriority.low,
        ),
      );
    }

    // 기본 추천사항
    recommendations.add(
      OnboardingRecommendation(
        type: RecommendationType.ai,
        title: 'AI 상담 체험',
        description: '24시간 언제든지 이용 가능한 AI 상담으로 시작해보세요.',
        priority: RecommendationPriority.low,
      ),
    );

    return recommendations;
  }

  // === 온보딩 진행률 분석 ===
  Future<OnboardingAnalysis> analyzeOnboardingData(OnboardingData data) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.saveOnboarding}/analysis',
        data: data.toJson(),
      );

      if (response.success && response.data != null) {
        return OnboardingAnalysis.fromJson(response.data!);
      }

      return _getMockAnalysis(data);
    } catch (e) {
      print('온보딩 분석 오류: $e');
      return _getMockAnalysis(data);
    }
  }

  OnboardingAnalysis _getMockAnalysis(OnboardingData data) {
    // 간단한 분석 로직
    final stressLevel = data.stressLevel ?? 5;
    final anxietyLevel = data.anxietyLevel ?? 5;
    final confidenceLevel = data.confidenceLevel ?? 5;
    final motivationLevel = data.motivationLevel ?? 5;

    final overallScore =
        (confidenceLevel +
            motivationLevel +
            (10 - stressLevel) +
            (10 - anxietyLevel)) /
        4;

    String riskLevel;
    String summary;

    if (overallScore >= 7) {
      riskLevel = 'low';
      summary = '전반적으로 안정적인 심리 상태를 보이고 있습니다. 현재 상태를 유지하시면 됩니다.';
    } else if (overallScore >= 5) {
      riskLevel = 'medium';
      summary = '일부 영역에서 관리가 필요합니다. 정기적인 상담과 관리를 권장합니다.';
    } else {
      riskLevel = 'high';
      summary = '심리적 지원이 필요한 상태입니다. 전문가와의 상담을 적극 권장합니다.';
    }

    return OnboardingAnalysis(
      overallScore: overallScore,
      riskLevel: riskLevel,
      summary: summary,
      detailedAnalysis: {
        'stress': stressLevel,
        'anxiety': anxietyLevel,
        'confidence': confidenceLevel,
        'motivation': motivationLevel,
      },
    );
  }
}

// === 온보딩 결과 클래스 ===
class OnboardingResult {
  final bool success;
  final User? user;
  final List<OnboardingRecommendation>? recommendations;
  final String? error;

  const OnboardingResult._({
    required this.success,
    this.user,
    this.recommendations,
    this.error,
  });

  factory OnboardingResult.success({
    User? user,
    List<OnboardingRecommendation>? recommendations,
  }) {
    return OnboardingResult._(
      success: true,
      user: user,
      recommendations: recommendations,
    );
  }

  factory OnboardingResult.failure(String error) {
    return OnboardingResult._(success: false, error: error);
  }
}

// === 스포츠 카테고리 클래스 ===
class SportCategory {
  final String name;
  final List<String> sports;

  const SportCategory({required this.name, required this.sports});

  factory SportCategory.fromJson(Map<String, dynamic> json) {
    return SportCategory(
      name: json['name'] as String,
      sports: List<String>.from(json['sports'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'sports': sports};
  }
}

// === 온보딩 추천사항 클래스 ===
class OnboardingRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  const OnboardingRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.actionUrl,
    this.metadata,
  });

  factory OnboardingRecommendation.fromJson(Map<String, dynamic> json) {
    return OnboardingRecommendation(
      type: RecommendationType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: RecommendationPriority.fromString(json['priority'] as String),
      actionUrl: json['actionUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'title': title,
      'description': description,
      'priority': priority.value,
      'actionUrl': actionUrl,
      'metadata': metadata,
    };
  }
}

// === 온보딩 분석 결과 클래스 ===
class OnboardingAnalysis {
  final double overallScore;
  final String riskLevel;
  final String summary;
  final Map<String, dynamic> detailedAnalysis;

  const OnboardingAnalysis({
    required this.overallScore,
    required this.riskLevel,
    required this.summary,
    required this.detailedAnalysis,
  });

  factory OnboardingAnalysis.fromJson(Map<String, dynamic> json) {
    return OnboardingAnalysis(
      overallScore: (json['overallScore'] as num).toDouble(),
      riskLevel: json['riskLevel'] as String,
      summary: json['summary'] as String,
      detailedAnalysis: json['detailedAnalysis'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'riskLevel': riskLevel,
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
    };
  }
}

// === 추천 타입 열거형 ===
enum RecommendationType {
  technique('technique'),
  counseling('counseling'),
  program('program'),
  ai('ai'),
  resource('resource');

  const RecommendationType(this.value);
  final String value;

  static RecommendationType fromString(String value) {
    return RecommendationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RecommendationType.ai,
    );
  }
}

// === 추천 우선순위 열거형 ===
enum RecommendationPriority {
  high('high'),
  medium('medium'),
  low('low');

  const RecommendationPriority(this.value);
  final String value;

  static RecommendationPriority fromString(String value) {
    return RecommendationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => RecommendationPriority.low,
    );
  }
}
