import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';

  static TokenManager? _instance;
  late SharedPreferences _prefs;

  // 싱글톤 패턴
  TokenManager._();

  static Future<TokenManager> getInstance() async {
    if (_instance == null) {
      _instance = TokenManager._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // === 토큰 저장 ===

  // 액세스 토큰 저장
  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);

    // JWT 토큰에서 만료 시간 추출 및 저장
    final expiryTime = _extractExpiryFromToken(token);
    if (expiryTime != null) {
      await _prefs.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch);
    }
  }

  // 리프레시 토큰 저장
  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  // 사용자 ID 저장
  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  // 모든 토큰 정보 한번에 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      if (userId != null) saveUserId(userId),
    ]);
  }

  // === 토큰 조회 ===

  // 액세스 토큰 조회
  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  // 리프레시 토큰 조회
  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  // 사용자 ID 조회
  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  // 토큰 만료 시간 조회
  DateTime? getTokenExpiry() {
    final expiryMillis = _prefs.getInt(_tokenExpiryKey);
    return expiryMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(expiryMillis)
        : null;
  }

  // === 토큰 상태 확인 ===

  // 토큰 존재 여부 확인
  bool hasTokens() {
    return getAccessToken() != null && getRefreshToken() != null;
  }

  // 액세스 토큰 만료 여부 확인
  bool isAccessTokenExpired() {
    final expiry = getTokenExpiry();
    if (expiry == null) return true;

    // 만료 5분 전을 만료로 간주 (자동 갱신을 위해)
    final buffer = const Duration(minutes: 5);
    return DateTime.now().add(buffer).isAfter(expiry);
  }

  // 토큰 유효성 확인
  bool isTokenValid() {
    return hasTokens() && !isAccessTokenExpired();
  }

  // === 토큰 삭제 ===

  // 모든 토큰 삭제 (로그아웃)
  Future<void> clearTokens() async {
    await Future.wait([
      _prefs.remove(_accessTokenKey),
      _prefs.remove(_refreshTokenKey),
      _prefs.remove(_tokenExpiryKey),
      _prefs.remove(_userIdKey),
    ]);
  }

  // 액세스 토큰만 삭제
  Future<void> clearAccessToken() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_tokenExpiryKey);
  }

  // === 유틸리티 메서드 ===

  // JWT 토큰에서 만료 시간 추출
  DateTime? _extractExpiryFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // JWT payload 디코딩
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;

      // exp 클레임에서 만료 시간 추출
      final exp = payloadMap['exp'] as int?;
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      // JWT 파싱 실패 시 null 반환
      print('JWT 토큰 파싱 오류: $e');
    }
    return null;
  }

  // JWT 토큰에서 사용자 정보 추출
  Map<String, dynamic>? extractUserInfoFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;

      return {
        'userId': payloadMap['sub'] ?? payloadMap['user_id'],
        'email': payloadMap['email'],
        'name': payloadMap['name'],
        'role': payloadMap['role'],
        'exp': payloadMap['exp'],
        'iat': payloadMap['iat'],
      };
    } catch (e) {
      print('JWT 사용자 정보 추출 오류: $e');
      return null;
    }
  }

  // Authorization 헤더 값 생성
  String? getAuthorizationHeader() {
    final token = getAccessToken();
    return token != null ? 'Bearer $token' : null;
  }

  // 토큰 상태 정보 반환
  TokenStatus getTokenStatus() {
    if (!hasTokens()) {
      return TokenStatus.notExists;
    } else if (isAccessTokenExpired()) {
      return TokenStatus.expired;
    } else {
      return TokenStatus.valid;
    }
  }

  // 토큰 정보 디버그 출력
  void debugTokenInfo() {
    print('=== Token Debug Info ===');
    print('Has Access Token: ${getAccessToken() != null}');
    print('Has Refresh Token: ${getRefreshToken() != null}');
    print('Token Expiry: ${getTokenExpiry()}');
    print('Is Expired: ${isAccessTokenExpired()}');
    print('Is Valid: ${isTokenValid()}');
    print('User ID: ${getUserId()}');

    final accessToken = getAccessToken();
    if (accessToken != null) {
      final userInfo = extractUserInfoFromToken(accessToken);
      print('User Info: $userInfo');
    }
    print('========================');
  }
}

// 토큰 상태 열거형
enum TokenStatus {
  valid, // 토큰이 유효함
  expired, // 토큰이 만료됨
  notExists, // 토큰이 존재하지 않음
}

// 토큰 갱신 결과
class TokenRefreshResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  const TokenRefreshResult({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.error,
  });

  factory TokenRefreshResult.success({
    required String accessToken,
    String? refreshToken,
  }) {
    return TokenRefreshResult(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory TokenRefreshResult.failure(String error) {
    return TokenRefreshResult(success: false, error: error);
  }
}

// 토큰 매니저 확장 - 자동 갱신 기능
extension TokenManagerAutoRefresh on TokenManager {
  // 토큰 자동 갱신이 필요한지 확인
  bool needsRefresh() {
    final expiry = getTokenExpiry();
    if (expiry == null) return false;

    // 만료 10분 전에 갱신 시도
    final refreshThreshold = const Duration(minutes: 10);
    return DateTime.now().add(refreshThreshold).isAfter(expiry);
  }

  // 토큰 만료까지 남은 시간 계산
  Duration? getTimeUntilExpiry() {
    final expiry = getTokenExpiry();
    if (expiry == null) return null;

    final now = DateTime.now();
    return expiry.isAfter(now) ? expiry.difference(now) : Duration.zero;
  }

  // 토큰 만료 알림이 필요한지 확인
  bool shouldNotifyExpiry() {
    final timeUntilExpiry = getTimeUntilExpiry();
    if (timeUntilExpiry == null) return false;

    // 만료 5분 전에 알림
    return timeUntilExpiry.inMinutes <= 5 && timeUntilExpiry.inMinutes > 0;
  }
}
