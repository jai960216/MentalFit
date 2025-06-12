import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/token_manager.dart';

class AuthService {
  static AuthService? _instance;
  late ApiClient _apiClient;
  late TokenManager _tokenManager;

  AuthService._();

  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      _instance = AuthService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _apiClient = await ApiClient.getInstance();
    _tokenManager = await TokenManager.getInstance();
  }

  // === 로그인 ===
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.success && response.data != null) {
        return await _handleAuthSuccess(response.data!);
      } else {
        return AuthResult.failure(response.error ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      if (kDebugMode) {
        return await _mockLogin(email, password);
      }
      return AuthResult.failure('로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === 회원가입 ===
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'userType': userType.value,
        },
      );

      if (response.success && response.data != null) {
        return await _handleAuthSuccess(response.data!);
      } else {
        return AuthResult.failure(response.error ?? '회원가입에 실패했습니다.');
      }
    } catch (e) {
      if (kDebugMode) {
        return await _mockRegister(email, password, name, userType);
      }
      return AuthResult.failure('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  // === 소셜 로그인 ===
  Future<AuthResult> socialLogin({
    required SocialLoginType type,
    required String accessToken,
  }) async {
    try {
      // 개발 모드에서는 바로 Mock 사용
      if (kDebugMode) {
        return await _mockSocialLogin(type, accessToken);
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.socialLogin,
        data: {'provider': type.name, 'accessToken': accessToken},
      );

      if (response.success && response.data != null) {
        return await _handleAuthSuccess(response.data!);
      } else {
        return AuthResult.failure(response.error ?? '소셜 로그인에 실패했습니다.');
      }
    } catch (e) {
      return AuthResult.failure('소셜 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === 자동 로그인 체크 ===
  Future<User?> checkAutoLogin() async {
    try {
      if (!(await _tokenManager.hasTokens())) {
        return null;
      }

      if (_tokenManager.isAccessTokenExpired()) {
        final refreshed = await _refreshToken();
        if (!refreshed) {
          await _tokenManager.clearTokens();
          return null;
        }
      }

      return await getCurrentUser();
    } catch (e) {
      await _tokenManager.clearTokens();
      return null;
    }
  }

  // === 현재 사용자 정보 조회 ===
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get<User>(
        ApiEndpoints.userProfile,
        fromJson: User.fromJson,
      );

      return response.success ? response.data : null;
    } catch (e) {
      if (kDebugMode) {
        return _getMockUser();
      }
      return null;
    }
  }

  // === 로그아웃 ===
  Future<bool> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      debugPrint('서버 로그아웃 요청 실패: $e');
    }

    await _tokenManager.clearTokens();
    return true;
  }

  // === 비밀번호 재설정 ===
  Future<bool> resetPassword(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {'email': email},
      );

      return response.success;
    } catch (e) {
      if (kDebugMode) {
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }
      return false;
    }
  }

  // 호환성을 위한 별칭
  Future<bool> requestPasswordReset(String email) async {
    return await resetPassword(email);
  }

  // === 프로필 업데이트 ===
  Future<User?> updateProfile({
    String? name,
    String? profileImageUrl,
    String? birthDate,
    String? sport,
    String? goal,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (profileImageUrl != null)
        updateData['profileImageUrl'] = profileImageUrl;
      if (birthDate != null) updateData['birthDate'] = birthDate;
      if (sport != null) updateData['sport'] = sport;
      if (goal != null) updateData['goal'] = goal;

      final response = await _apiClient.patch<User>(
        ApiEndpoints.updateProfile,
        data: updateData,
        fromJson: User.fromJson,
      );

      return response.success ? response.data : null;
    } catch (e) {
      debugPrint('프로필 업데이트 실패: $e');
      return null;
    }
  }

  // === 비밀번호 변경 ===
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      return response.success;
    } catch (e) {
      debugPrint('비밀번호 변경 실패: $e');
      return false;
    }
  }

  // === 계정 삭제 ===
  Future<bool> deleteAccount(String password) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteAccount,
        data: {'password': password},
      );

      if (response.success) {
        await _tokenManager.clearTokens();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('계정 삭제 실패: $e');
      return false;
    }
  }

  // === 토큰 갱신 ===
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.success && response.data != null) {
        final newAccessToken = response.data!['accessToken'] as String;
        final newRefreshToken = response.data!['refreshToken'] as String?;

        await _tokenManager.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
        );

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // === Mock 메서드들 ===
  Future<AuthResult> _mockLogin(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) {
      return AuthResult.failure('이메일과 비밀번호를 입력해주세요.');
    }

    if (password.length < 6) {
      return AuthResult.failure('비밀번호가 올바르지 않습니다.');
    }

    final mockUser = _createMockUser(email);
    await _saveMockTokens(mockUser.id);

    return AuthResult.success(mockUser);
  }

  Future<AuthResult> _mockRegister(
    String email,
    String password,
    String name,
    UserType userType,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final mockUser = _createMockUser(email, name: name, userType: userType);
    await _saveMockTokens(mockUser.id);

    return AuthResult.success(mockUser);
  }

  Future<AuthResult> _mockSocialLogin(
    SocialLoginType type,
    String accessToken,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final email = '${type.name}_user@mentalfit.com';
    final mockUser = _createMockUser(
      email,
      name: '${type.name.toUpperCase()} 사용자',
    );
    await _saveMockTokens(mockUser.id);

    return AuthResult.success(mockUser);
  }

  User _createMockUser(String email, {String? name, UserType? userType}) {
    final now = DateTime.now();
    return User(
      id: 'mock_user_${now.millisecondsSinceEpoch}',
      email: email,
      name: name ?? email.split('@')[0],
      userType: userType ?? UserType.general, // general로 수정
      isOnboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  User _getMockUser() {
    final userId = _tokenManager.getUserId();
    return User(
      id: userId ?? 'mock_user_current',
      email: 'current@mentalfit.com',
      name: '현재 사용자',
      userType: UserType.general, // general로 수정
      isOnboardingCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveMockTokens(String userId) async {
    final accessToken =
        'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken =
        'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}';

    await _tokenManager.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  // === 헬퍼 메서드 ===
  Future<AuthResult> _handleAuthSuccess(Map<String, dynamic> data) async {
    try {
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      await _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userData['id'] as String,
      );

      final user = User.fromJson(userData);
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('인증 데이터 처리 중 오류가 발생했습니다: $e');
    }
  }
}

// === 인증 결과 클래스 ===
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  const AuthResult._(this.success, this.user, this.error);

  factory AuthResult.success(User user) {
    return AuthResult._(true, user, null);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(false, null, error);
  }
}

// === 소셜 로그인 타입 ===
enum SocialLoginType { google, kakao }

// === 인증 상태 ===
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }
