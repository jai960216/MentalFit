import 'package:flutter_riverpod/flutter_riverpod.dart';

// 앱 전역 상태
class AppState {
  final bool isFirstLaunch;
  final String? currentTheme;
  final bool notificationsEnabled;
  final String? selectedLanguage;
  final bool isOffline;

  const AppState({
    this.isFirstLaunch = true,
    this.currentTheme = 'light',
    this.notificationsEnabled = true,
    this.selectedLanguage = 'ko',
    this.isOffline = false,
  });

  AppState copyWith({
    bool? isFirstLaunch,
    String? currentTheme,
    bool? notificationsEnabled,
    String? selectedLanguage,
    bool? isOffline,
  }) {
    return AppState(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      currentTheme: currentTheme ?? this.currentTheme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// 앱 상태 관리
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  // 첫 실행 완료 표시
  void completeFirstLaunch() {
    state = state.copyWith(isFirstLaunch: false);
  }

  // 테마 변경
  void changeTheme(String theme) {
    state = state.copyWith(currentTheme: theme);
  }

  // 알림 설정 토글
  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }

  // 언어 변경
  void changeLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
  }

  // 네트워크 상태 업데이트
  void updateNetworkStatus(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }
}

// Provider 정의
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  return AppStateNotifier();
});

// 편의용 Provider들
final isFirstLaunchProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isFirstLaunch;
});

final currentThemeProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).currentTheme;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).notificationsEnabled;
});

final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isOffline;
});
