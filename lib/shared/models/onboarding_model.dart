class OnboardingData {
  // 기본 정보 (1/4)
  final String? name;
  final String? birthDate;
  final String? sport;
  final String? goal;

  // 심리 상태 체크 (2/4)
  final int? stressLevel;
  final int? anxietyLevel;
  final int? confidenceLevel;
  final int? motivationLevel;

  // 선호도 조사 (3/4)
  final CounselingPreference? counselingPreference;
  final List<String>? preferredTimes;

  // 완료 여부
  final bool isCompleted;

  final List<int>? completedSteps;

  const OnboardingData({
    this.name,
    this.birthDate,
    this.sport,
    this.goal,
    this.stressLevel,
    this.anxietyLevel,
    this.confidenceLevel,
    this.motivationLevel,
    this.counselingPreference,
    this.preferredTimes,
    this.isCompleted = false,
    this.completedSteps,
  });

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      name: json['name'] as String?,
      birthDate: json['birthDate'] as String?,
      sport: json['sport'] as String?,
      goal: json['goal'] as String?,
      stressLevel: json['stressLevel'] as int?,
      anxietyLevel: json['anxietyLevel'] as int?,
      confidenceLevel: json['confidenceLevel'] as int?,
      motivationLevel: json['motivationLevel'] as int?,
      counselingPreference:
          json['counselingPreference'] != null
              ? CounselingPreference.fromString(
                json['counselingPreference'] as String,
              )
              : null,
      preferredTimes:
          json['preferredTimes'] != null
              ? List<String>.from(json['preferredTimes'] as List)
              : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedSteps:
          json['completedSteps'] != null
              ? List<int>.from(json['completedSteps'] as List)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthDate': birthDate,
      'sport': sport,
      'goal': goal,
      'stressLevel': stressLevel,
      'anxietyLevel': anxietyLevel,
      'confidenceLevel': confidenceLevel,
      'motivationLevel': motivationLevel,
      'counselingPreference': counselingPreference?.value,
      'preferredTimes': preferredTimes,
      'isCompleted': isCompleted,
      'completedSteps': completedSteps,
    };
  }

  OnboardingData copyWith({
    String? name,
    String? birthDate,
    String? sport,
    String? goal,
    int? stressLevel,
    int? anxietyLevel,
    int? confidenceLevel,
    int? motivationLevel,
    CounselingPreference? counselingPreference,
    List<String>? preferredTimes,
    bool? isCompleted,
    List<int>? completedSteps,
  }) {
    return OnboardingData(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      sport: sport ?? this.sport,
      goal: goal ?? this.goal,
      stressLevel: stressLevel ?? this.stressLevel,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      motivationLevel: motivationLevel ?? this.motivationLevel,
      counselingPreference: counselingPreference ?? this.counselingPreference,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }

  // 단계별 완료 여부 확인
  bool get isStep1Completed =>
      name != null && birthDate != null && sport != null;

  bool get isStep2Completed =>
      stressLevel != null &&
      anxietyLevel != null &&
      confidenceLevel != null &&
      motivationLevel != null;

  bool get isStep3Completed =>
      counselingPreference != null && preferredTimes != null;

  // 전체 진행률 계산
  double get progress {
    int completedSteps = 0;
    if (isStep1Completed) completedSteps++;
    if (isStep2Completed) completedSteps++;
    if (isStep3Completed) completedSteps++;
    return completedSteps / 3.0;
  }

  @override
  String toString() {
    return 'OnboardingData(name: $name, progress: ${(progress * 100).toInt()}%)';
  }
}

enum CounselingPreference {
  faceToFace('face_to_face', '대면 상담'),
  video('video', '비대면 상담');

  const CounselingPreference(this.value, this.displayName);

  final String value;
  final String displayName;

  static CounselingPreference fromString(String value) {
    return CounselingPreference.values.firstWhere(
      (pref) => pref.value == value,
      orElse: () => CounselingPreference.video,
    );
  }

  @override
  String toString() => displayName;
}

// 선호 시간대
class PreferredTime {
  static const List<String> timeSlots = ['아침', '오후', '저녁', '유동적'];

  static const Map<String, String> timeValues = {
    '아침': 'morning',
    '오후': 'afternoon',
    '저녁': 'evening',
    '유동적': 'flexible',
  };
}
