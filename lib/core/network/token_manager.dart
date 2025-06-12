import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  // SharedPreferences 키들 (일단 보안 스토리지 없이)
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';

  static TokenManager? _instance;
  late SharedPreferences _prefs;

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
  Future<void> saveAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);

    // JWT 토큰에서 만료 시간 추출 및 저장
    final expiryTime = _extractExpiryFromToken(token);
    if (expiryTime != null) {
      await _prefs.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch);
    }
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

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
  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  DateTime? getTokenExpiry() {
    final expiryMillis = _prefs.getInt(_tokenExpiryKey);
    return expiryMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(expiryMillis)
        : null;
  }

  // === 토큰 상태 확인 ===
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  bool isAccessTokenExpired() {
    final expiry = getTokenExpiry();
    if (expiry == null) return true;

    final bufferTime = const Duration(minutes: 5);
    return DateTime.now().add(bufferTime).isAfter(expiry);
  }

  Future<bool> isTokenValid() async {
    final hasTokens = await this.hasTokens();
    if (!hasTokens) return false;
    return !isAccessTokenExpired();
  }

  // === 토큰 삭제 ===
  Future<void> clearTokens() async {
    await Future.wait([
      _prefs.remove(_accessTokenKey),
      _prefs.remove(_refreshTokenKey),
      _prefs.remove(_tokenExpiryKey),
      _prefs.remove(_userIdKey),
    ]);
  }

  // === JWT 유틸리티 ===
  DateTime? _extractExpiryFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;

      final exp = payloadMap['exp'] as int?;
      return exp != null
          ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          : null;
    } catch (e) {
      debugPrint('JWT 만료 시간 추출 오류: $e');
      return null;
    }
  }

  Future<String?> getAuthorizationHeader() async {
    final token = await getAccessToken();
    return token != null ? 'Bearer $token' : null;
  }

  // === 디버그 ===
  Future<void> debugTokenInfo() async {
    if (!kDebugMode) return;

    print('=== Token Debug Info ===');
    print('Has Access Token: ${await getAccessToken() != null}');
    print('Has Refresh Token: ${await getRefreshToken() != null}');
    print('Token Expiry: ${getTokenExpiry()}');
    print('Is Expired: ${isAccessTokenExpired()}');
    print('Is Valid: ${await isTokenValid()}');
    print('User ID: ${getUserId()}');
    print('========================');
  }
}

enum TokenStatus { valid, expired, notExists }
