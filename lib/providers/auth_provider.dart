import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/user_model.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/social_auth_service.dart';
import '../shared/services/firestore_service.dart';

/// 인증 상태 관리 (Firebase 기반)
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

/// Firebase 기반 인증 관리자
class AuthNotifier extends StateNotifier<AuthState> {
  late AuthService _authService;
  late SocialAuthService _socialAuthService;
  late FirestoreService _firestoreService;
  bool _initialized = false;

  AuthNotifier() : super(const AuthState()) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (_initialized) return;

    try {
      _authService = await AuthService.getInstance();
      _socialAuthService = await SocialAuthService.getInstance();
      _firestoreService = await FirestoreService.getInstance();
      _initialized = true;

      debugPrint('✅ AuthProvider Firebase 서비스 초기화 완료');

      // 자동 로그인 체크
      await checkAutoLogin();
    } catch (e) {
      debugPrint('❌ AuthProvider 초기화 실패: $e');
      state = state.copyWith(
        error: '서비스 초기화 중 오류가 발생했습니다: $e',
        status: AuthStatus.error,
      );
    }
  }

  /// === 자동 로그인 체크 ===
  Future<void> checkAutoLogin() async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(isLoading: true, status: AuthStatus.loading);

    try {
      final user = await _authService.checkAutoLogin();

      if (user != null) {
        // 온보딩 미완료 상태라면 안내 후 로그아웃
        if (!(user.isOnboardingCompleted ?? false)) {
          // 온보딩 미완료 안내 후 로그아웃 처리
          state = state.copyWith(
            user: null,
            isLoading: false,
            isLoggedIn: false,
            status: AuthStatus.unauthenticated,
            error: '회원가입(온보딩) 미완료 상태입니다. 회원가입을 완료해주세요.',
          );
          // 필요시: await logout();
          debugPrint('ℹ️ 온보딩 미완료 계정 자동 로그아웃');
          return;
        }
        state = state.copyWith(
          user: user,
          isLoading: false,
          isLoggedIn: true,
          status: AuthStatus.authenticated,
          error: null,
        );
        debugPrint('✅ 자동 로그인 성공: ${user.email}');
      } else {
        state = state.copyWith(
          user: null,
          isLoading: false,
          isLoggedIn: false,
          status: AuthStatus.unauthenticated,
          error: null,
        );
        debugPrint('ℹ️ 자동 로그인 불가: 로그인 필요');
      }
    } catch (e) {
      debugPrint('❌ 자동 로그인 체크 실패: $e');
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        status: AuthStatus.error,
        error: '자동 로그인 확인 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// === 이메일 로그인 ===
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
        debugPrint('✅ 로그인 성공: ${result.user!.email}');
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.error,
          error: result.error,
        );
        debugPrint('❌ 로그인 실패: ${result.error}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ 로그인 중 오류: $e');
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: '로그인 중 오류가 발생했습니다: $e',
      );
      return AuthResult.failure(e.toString());
    }
  }

  /// === 회원가입 ===
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
        debugPrint('✅ 회원가입 성공: ${result.user!.email}');
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.error,
          error: result.error,
        );
        debugPrint('❌ 회원가입 실패: ${result.error}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ 회원가입 중 오류: $e');
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: '회원가입 중 오류가 발생했습니다: $e',
      );
      return AuthResult.failure(e.toString());
    }
  }

  /// === Google 소셜 로그인 ===
  Future<AuthResult> signInWithGoogle() async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(
      isLoading: true,
      error: null,
      status: AuthStatus.loading,
    );

    try {
      final result = await _socialAuthService.signInWithGoogle();

      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isLoggedIn: true,
          status: AuthStatus.authenticated,
          error: null,
        );
        debugPrint('✅ Google 로그인 성공: ${result.user!.email}');
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.error,
          error: result.error,
        );
        debugPrint('❌ Google 로그인 실패: ${result.error}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Google 로그인 중 오류: $e');
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: 'Google 로그인 중 오류가 발생했습니다: $e',
      );
      return AuthResult.failure(e.toString());
    }
  }

  /// === Kakao 소셜 로그인 ===
  Future<AuthResult> signInWithKakao() async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(
      isLoading: true,
      error: null,
      status: AuthStatus.loading,
    );

    try {
      final result = await _socialAuthService.signInWithKakao();

      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          isLoggedIn: true,
          status: AuthStatus.authenticated,
          error: null,
        );
        debugPrint('✅ Kakao 로그인 성공: ${result.user!.email}');
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.error,
          error: result.error,
        );
        debugPrint('❌ Kakao 로그인 실패: ${result.error}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Kakao 로그인 중 오류: $e');
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        error: 'Kakao 로그인 중 오류가 발생했습니다: $e',
      );
      return AuthResult.failure(e.toString());
    }
  }

  /// === 로그아웃 ===
  Future<void> logout() async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(isLoading: true);

    try {
      // 모든 소셜 로그인 로그아웃
      await _socialAuthService.signOutAll();

      // Firebase Auth 로그아웃
      await _authService.logout();

      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );

      debugPrint('✅ 로그아웃 완료');
    } catch (e) {
      debugPrint('❌ 로그아웃 중 오류: $e');
      // 로그아웃은 실패해도 로컬 상태는 초기화
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// === 비밀번호 재설정 ===
  Future<bool> resetPassword(String email) async {
    if (!_initialized) await _initializeServices();

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.resetPassword(email);

      state = state.copyWith(
        isLoading: false,
        error: success ? null : '비밀번호 재설정 요청에 실패했습니다.',
      );

      if (success) {
        debugPrint('✅ 비밀번호 재설정 이메일 발송 완료');
      } else {
        debugPrint('❌ 비밀번호 재설정 이메일 발송 실패');
      }

      return success;
    } catch (e) {
      debugPrint('❌ 비밀번호 재설정 중 오류: $e');
      state = state.copyWith(
        isLoading: false,
        error: '비밀번호 재설정 중 오류가 발생했습니다: $e',
      );
      return false;
    }
  }

  /// === 사용자 정보 업데이트 ===
  void updateUser(User user) {
    state = state.copyWith(user: user);
    debugPrint('✅ 사용자 정보 업데이트: ${user.email}');
  }

  /// === 프로필 업데이트 ===
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
        debugPrint('✅ 프로필 업데이트 성공');
        return true;
      }

      debugPrint('❌ 프로필 업데이트 실패');
      return false;
    } catch (e) {
      debugPrint('❌ 프로필 업데이트 중 오류: $e');
      state = state.copyWith(error: '프로필 업데이트 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// === 온보딩 완료 표시 ===
  void completeOnboarding() {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        isOnboardingCompleted: true,
        updatedAt: DateTime.now(),
      );
      updateUser(updatedUser);

      // Firestore에도 업데이트
      _updateOnboardingStatusInFirestore(updatedUser);

      debugPrint('✅ 온보딩 완료 표시');
    }
  }

  /// === 사용자 정보 새로고침 ===
  Future<void> refreshUser() async {
    if (!_initialized) await _initializeServices();

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        updateUser(user);
        debugPrint('✅ 사용자 정보 새로고침 완료');
      }
    } catch (e) {
      debugPrint('❌ 사용자 정보 새로고침 실패: $e');
      state = state.copyWith(error: '사용자 정보 새로고침 중 오류가 발생했습니다: $e');
    }
  }

  /// === 비밀번호 변경 ===
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!_initialized) await _initializeServices();

    try {
      final success = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!success) {
        state = state.copyWith(error: '비밀번호 변경에 실패했습니다.');
        debugPrint('❌ 비밀번호 변경 실패');
      } else {
        debugPrint('✅ 비밀번호 변경 성공');
      }

      return success;
    } catch (e) {
      debugPrint('❌ 비밀번호 변경 중 오류: $e');
      state = state.copyWith(error: '비밀번호 변경 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// === 계정 삭제 ===
  Future<bool> deleteAccount(String password) async {
    if (!_initialized) await _initializeServices();

    try {
      final success = await _authService.deleteAccount(password);

      if (success) {
        // 모든 소셜 로그인 연결 해제
        await _socialAuthService.signOutAll();

        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );

        debugPrint('✅ 계정 삭제 완료');
      } else {
        state = state.copyWith(error: '계정 삭제에 실패했습니다.');
        debugPrint('❌ 계정 삭제 실패');
      }

      return success;
    } catch (e) {
      debugPrint('❌ 계정 삭제 중 오류: $e');
      state = state.copyWith(error: '계정 삭제 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// === 내부 헬퍼 메서드 ===

  /// Firestore에 온보딩 상태 업데이트
  Future<void> _updateOnboardingStatusInFirestore(User user) async {
    try {
      await _firestoreService.saveUser(user);
    } catch (e) {
      debugPrint('❌ Firestore 온보딩 상태 업데이트 실패: $e');
    }
  }

  /// 디버그 정보 출력
  void printDebugInfo() {
    if (!kDebugMode) return;

    debugPrint('=== AuthProvider Debug Info ===');
    debugPrint('초기화 상태: $_initialized');
    debugPrint('로그인 상태: ${state.isLoggedIn}');
    debugPrint('인증 상태: ${state.status}');
    debugPrint('사용자 ID: ${state.user?.id}');
    debugPrint('사용자 이메일: ${state.user?.email}');
    debugPrint('온보딩 완료: ${state.user?.isOnboardingCompleted}');
    debugPrint('로딩 상태: ${state.isLoading}');
    debugPrint('에러: ${state.error}');
    debugPrint('===============================');
  }
}

/// === AuthProvider 생성 ===
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// === 편의 Provider들 ===

/// 현재 로그인 상태
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

/// 현재 사용자 정보
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// 로딩 상태
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// 에러 상태
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

/// 온보딩 완료 여부
final isOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.isOnboardingCompleted ?? false;
});
