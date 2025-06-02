import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/user_model.dart';

// 인증 상태 관리
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

// AuthNotifier 클래스
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // 로그인
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 실제 API 호출로 교체
      await Future.delayed(const Duration(seconds: 2));

      // 임시 사용자 데이터
      final user = User(
        id: 'user_123',
        email: email,
        name: '홍길동',
        userType: UserType.athlete,
        isOnboardingCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(user: user, isLoading: false, isLoggedIn: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 소셜 로그인
  Future<void> socialLogin({required SocialLoginType type}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 소셜 로그인 구현
      await Future.delayed(const Duration(seconds: 2));

      final user = User(
        id: 'user_social_123',
        email: 'social@example.com',
        name: '김소셜',
        userType: UserType.general,
        isOnboardingCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(user: user, isLoading: false, isLoggedIn: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 회원가입
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 실제 API 호출로 교체
      await Future.delayed(const Duration(seconds: 2));

      final user = User(
        id: 'user_new_123',
        email: email,
        name: name,
        userType: userType,
        isOnboardingCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(user: user, isLoading: false, isLoggedIn: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 로그아웃
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // TODO: 토큰 삭제, 로컬 데이터 정리
      await Future.delayed(const Duration(seconds: 1));

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 사용자 정보 업데이트
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  // 온보딩 완료 표시
  void completeOnboarding() {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        isOnboardingCompleted: true,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(user: updatedUser);
    }
  }

  // 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 소셜 로그인 타입
enum SocialLoginType { google, kakao }

// Provider 정의
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// 편의용 Provider들
final userProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
