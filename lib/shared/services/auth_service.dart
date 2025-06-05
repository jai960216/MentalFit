import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/token_manager.dart';

class AuthService {
  static AuthService? _instance;
  late ApiClient _apiClient;
  late TokenManager _tokenManager;

  // 싱글톤 패턴
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
      return AuthResult.failure('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  // === 소셜 로그인 ===
  Future<AuthResult> socialLogin({
    required SocialLoginType type,
    required String accessToken,
  }) async {
    try {
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

  // === 토큰 갱신 ===
  Future<bool> refreshToken() async {
    try {
      final refreshToken = _tokenManager.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.success && response.data != null) {
        final newAccessToken = response.data!['accessToken'] as String;
        final newRefreshToken = response.data!['refreshToken'] as String?;

        await _tokenManager.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _tokenManager.saveRefreshToken(newRefreshToken);
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // === 로그아웃 ===
  Future<void> logout() async {
    try {
      // 서버에 로그아웃 요청 (선택사항)
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // 로그아웃 실패해도 로컬 토큰은 삭제
    } finally {
      // 로컬 토큰 삭제
      await _tokenManager.clearTokens();
    }
  }

  // === 현재 사용자 정보 조회 ===
  Future<User?> getCurrentUser() async {
    try {
      if (!_tokenManager.isTokenValid()) {
        // 토큰이 만료되었으면 갱신 시도
        final refreshed = await refreshToken();
        if (!refreshed) return null;
      }

      final response = await _apiClient.get<User>(
        ApiEndpoints.userProfile,
        fromJson: User.fromJson,
      );

      return response.success ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  // === 자동 로그인 확인 ===
  Future<User?> checkAutoLogin() async {
    try {
      // 토큰이 있는지 확인
      if (!_tokenManager.hasTokens()) return null;

      // 토큰이 만료되었으면 갱신 시도
      if (_tokenManager.isAccessTokenExpired()) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _tokenManager.clearTokens();
          return null;
        }
      }

      // 사용자 정보 조회
      return await getCurrentUser();
    } catch (e) {
      // 오류 발생 시 토큰 삭제
      await _tokenManager.clearTokens();
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
        '${ApiEndpoints.userProfile}/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      return response.success;
    } catch (e) {
      return false;
    }
  }

  // === 비밀번호 재설정 요청 ===
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.login}/forgot-password',
        data: {'email': email},
      );

      return response.success;
    } catch (e) {
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
      return false;
    }
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
      return null;
    }
  }

  // === 헬퍼 메서드 ===

  // 인증 성공 처리
  Future<AuthResult> _handleAuthSuccess(Map<String, dynamic> data) async {
    try {
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      // 토큰 저장
      await _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userData['id'] as String,
      );

      // 사용자 객체 생성
      final user = User.fromJson(userData);

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('인증 데이터 처리 중 오류가 발생했습니다: $e');
    }
  }

  // 토큰 상태 확인
  bool get isLoggedIn => _tokenManager.hasTokens();

  // 토큰 만료 확인
  bool get isTokenExpired => _tokenManager.isAccessTokenExpired();
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
