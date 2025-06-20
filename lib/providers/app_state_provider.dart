import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 테마 상태 관리
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const String _themeKey = 'theme_mode';

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    state = mode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// ✅ 수정된 isDarkModeProvider - 직접 state를 감시
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider); // ✅ 직접 state 감시
  return themeMode == ThemeMode.dark; // ✅ 반응형으로 작동
});

// 앱 전역 상태
class AppState {
  final bool isFirstLaunch;
  final String? currentTheme;
  final bool notificationsEnabled;
  final String? selectedLanguage;
  final bool isOffline;
  final bool isLoading;
  final String? error;

  const AppState({
    this.isFirstLaunch = true,
    this.currentTheme = 'light',
    this.notificationsEnabled = true,
    this.selectedLanguage = 'ko',
    this.isOffline = false,
    this.isLoading = false,
    this.error,
  });

  AppState copyWith({
    bool? isFirstLaunch,
    String? currentTheme,
    bool? notificationsEnabled,
    String? selectedLanguage,
    bool? isOffline,
    bool? isLoading,
    String? error,
  }) {
    return AppState(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      currentTheme: currentTheme ?? this.currentTheme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isOffline: isOffline ?? this.isOffline,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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

  void updateLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void updateError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
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

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isLoading;
});

final errorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).error;
});
