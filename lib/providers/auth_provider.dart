import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/user_model.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/social_auth_service.dart';

// 인증 상태 관리
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;
  final AuthStatus status;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
    this.status = AuthStatus.initial,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
    AuthStatus? status,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'AuthState(isLoggedIn: $isLoggedIn, status: $status, user: ${user?.id})';
  }
}

// AuthNotifier 클래스
class AuthNotifier extends StateNotifier<AuthState> {
  late AuthService _authService;
  late SocialAuthService _socialAuthService;
  bool _initialized = false;

  AuthNotifier() : super(const AuthState()) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (_initialized) return;

    _authService = await AuthService.getInstance();
    _socialAuthService = await SocialAuthService.getInstance();
    _initialized = true;

    // 자동 로그인 체크
    await checkAutoLogin();
  }

  // === 자동 로그인 체크 ===
  Future<void> checkAutoLogin() async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(isLoading: true, status: AuthStatus.loading);

    try {
      final user = await _authService.checkAutoLogin();

      if (user != null) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          isLoggedIn: true,
          status: AuthStatus.authenticated,
          error: null,
        );
      } else {
        state = state.copyWith(
          user: null,
          isLoading: false,
          isLoggedIn: false,
          status: AuthStatus.unauthenticated,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  // === 로그인 ===
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(
      isLoading: true,
      error: null,
      status: AuthStatus.loading,
    );

    try {
      final result = await _authService.login(email: email, password: password);

      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isLoggedIn: true,
          status: AuthStatus.authenticated,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.error,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: e.toString(),
      );
      return AuthResult.failure(e.toString());
    }
  }

  // === 회원가입 ===
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(
      isLoading: true,
      error: null,
      status: AuthStatus.loading,
    );

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );

      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isLoggedIn: true,
          status: AuthStatus.authenticated,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.error,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: e.toString(),
      );
      return AuthResult.failure(e.toString());
    }
  }

  // === 소셜 로그인 ===
  Future<AuthResult> socialLogin({required SocialLoginType type}) async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(
      isLoading: true,
      error: null,
      status: AuthStatus.loading,
    );

    try {
      AuthResult result;

      switch (type) {
        case SocialLoginType.google:
          result = await _socialAuthService.signInWithGoogle();
          break;
        case SocialLoginType.kakao:
          result = await _socialAuthService.signInWithKakao();
          break;
      }

      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isLoggedIn: true,
          status: AuthStatus.authenticated,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.error,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: e.toString(),
      );
      return AuthResult.failure(e.toString());
    }
  }

  // === 로그아웃 ===
  Future<void> logout() async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();
      await _socialAuthService.signOutAll();

      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 사용자 정보 업데이트 ===
  void updateUser(User user) {
    state = state.copyWith(
      user: user,
      isLoggedIn: true,
      status: AuthStatus.authenticated,
    );
  }

  // === 프로필 업데이트 ===
  Future<bool> updateProfile({
    String? name,
    String? profileImageUrl,
    String? birthDate,
    String? sport,
    String? goal,
  }) async {
    if (!_initialized) await _initializeServices();

    try {
      final updatedUser = await _authService.updateProfile(
        name: name,
        profileImageUrl: profileImageUrl,
        birthDate: birthDate,
        sport: sport,
        goal: goal,
      );

      if (updatedUser != null) {
        updateUser(updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // === 온보딩 완료 표시 ===
  void completeOnboarding() {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        isOnboardingCompleted: true,
        updatedAt: DateTime.now(),
      );
      updateUser(updatedUser);
    }
  }

  // === 사용자 정보 새로고침 ===
  Future<void> refreshUser() async {
    if (!_initialized) await _initializeServices();

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        updateUser(user);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // === 비밀번호 변경 ===
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!_initialized) await _initializeServices();

    try {
      return await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // === 계정 삭제 ===
  Future<bool> deleteAccount(String password) async {
    if (!_initialized) await _initializeServices();

    try {
      final success = await _authService.deleteAccount(password);

      if (success) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // === 에러 초기화 ===
  void clearError() {
    state = state.copyWith(error: null);
  }

  // === 로그인 상태 확인 ===
  bool get isAuthenticated => state.isLoggedIn && state.user != null;

  // === 온보딩 완료 여부 ===
  bool get isOnboardingCompleted => state.user?.isOnboardingCompleted ?? false;

  // === 현재 사용자 ===
  User? get currentUser => state.user;
}

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

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier.isAuthenticated;
});

final isOnboardingCompletedProvider = Provider<bool>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier.isOnboardingCompleted;
});

// AuthService와 SocialAuthService Provider (의존성 주입용)
final authServiceProvider = FutureProvider<AuthService>((ref) async {
  return await AuthService.getInstance();
});

final socialAuthServiceProvider = FutureProvider<SocialAuthService>((
  ref,
) async {
  return await SocialAuthService.getInstance();
});
