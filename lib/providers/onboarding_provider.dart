import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/onboarding_model.dart';
import 'package:flutter/foundation.dart';

// 온보딩 상태 관리
class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(const OnboardingData());

  // 1단계: 기본 정보 업데이트
  void updateBasicInfo({
    String? name,
    String? birthDate,
    String? sport,
    String? goal,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      birthDate: birthDate ?? state.birthDate,
      sport: sport ?? state.sport,
      goal: goal ?? state.goal,
    );
  }

  // 2단계: 심리 상태 업데이트
  void updateMentalState({
    int? stressLevel,
    int? anxietyLevel,
    int? confidenceLevel,
    int? motivationLevel,
  }) {
    state = state.copyWith(
      stressLevel: stressLevel ?? state.stressLevel,
      anxietyLevel: anxietyLevel ?? state.anxietyLevel,
      confidenceLevel: confidenceLevel ?? state.confidenceLevel,
      motivationLevel: motivationLevel ?? state.motivationLevel,
    );
  }

  // 3단계: 선호도 업데이트
  void updatePreferences({
    CounselingPreference? counselingPreference,
    List<String>? preferredTimes,
  }) {
    state = state.copyWith(
      counselingPreference: counselingPreference ?? state.counselingPreference,
      preferredTimes: preferredTimes ?? state.preferredTimes,
    );
  }

  // 특정 필드 업데이트
  void updateField(String field, dynamic value) {
    switch (field) {
      case 'name':
        state = state.copyWith(name: value as String?);
        break;
      case 'birthDate':
        state = state.copyWith(birthDate: value as String?);
        break;
      case 'sport':
        state = state.copyWith(sport: value as String?);
        break;
      case 'goal':
        state = state.copyWith(goal: value as String?);
        break;
      case 'stressLevel':
        state = state.copyWith(stressLevel: value as int?);
        break;
      case 'anxietyLevel':
        state = state.copyWith(anxietyLevel: value as int?);
        break;
      case 'confidenceLevel':
        state = state.copyWith(confidenceLevel: value as int?);
        break;
      case 'motivationLevel':
        state = state.copyWith(motivationLevel: value as int?);
        break;
      case 'counselingPreference':
        state = state.copyWith(
          counselingPreference: value as CounselingPreference?,
        );
        break;
      case 'preferredTimes':
        state = state.copyWith(preferredTimes: value as List<String>?);
        break;
    }
  }

  // 회원가입 정보를 온보딩에 반영하는 메서드
  void setSignupInfo({
    required String name,
    String? birthDate,
    String? sport,
    String? goal,
  }) {
    state = state.copyWith(
      name: name,
      birthDate: birthDate,
      sport: sport,
      goal: goal,
    );
    debugPrint('✅ 회원가입 정보를 온보딩에 반영: $name');
  }

  // 회원가입 완료 여부 확인
  bool get isSignupInfoComplete => state.name != null && state.name!.isNotEmpty;

  // 온보딩 단계별 완료 상태 업데이트
  void updateStepCompletion(int step, bool isCompleted) {
    final currentSteps = state.completedSteps ?? [];
    if (isCompleted && !currentSteps.contains(step)) {
      state = state.copyWith(completedSteps: [...currentSteps, step]);
    } else if (!isCompleted && currentSteps.contains(step)) {
      state = state.copyWith(
        completedSteps: currentSteps.where((s) => s != step).toList(),
      );
    }
  }

  // 현재 온보딩 단계 가져오기
  int get currentStep {
    final completedSteps = state.completedSteps ?? [];
    if (completedSteps.isEmpty) return 1;
    return completedSteps.last + 1;
  }

  // 온보딩 완료 여부 확인
  bool get isOnboardingComplete {
    final completedSteps = state.completedSteps ?? [];
    return completedSteps.length >= 4; // 총 4단계
  }

  // 온보딩 완료
  Future<void> completeOnboarding() async {
    try {
      // TODO: API 호출로 온보딩 데이터 저장
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isCompleted: true);
    } catch (e) {
      throw Exception('온보딩 완료 중 오류가 발생했습니다: $e');
    }
  }

  // 온보딩 데이터 초기화
  void reset() {
    state = const OnboardingData();
  }

  // 로컬 저장소에 임시 저장
  Future<void> saveToLocal() async {
    // TODO: SharedPreferences에 저장
  }

  // 로컬 저장소에서 불러오기
  Future<void> loadFromLocal() async {
    // TODO: SharedPreferences에서 불러오기
  }
}

// Provider 정의
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
      return OnboardingNotifier();
    });

// 편의용 Provider들
final onboardingProgressProvider = Provider<double>((ref) {
  return ref.watch(onboardingProvider).progress;
});

final isStep1CompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isStep1Completed;
});

final isStep2CompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isStep2Completed;
});

final isStep3CompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isStep3Completed;
});

final isOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isCompleted;
});
