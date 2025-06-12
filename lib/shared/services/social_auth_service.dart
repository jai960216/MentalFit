import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'auth_service.dart';

class SocialAuthService {
  static SocialAuthService? _instance;
  late AuthService _authService;
  late GoogleSignIn _googleSignIn;

  SocialAuthService._();

  static Future<SocialAuthService> getInstance() async {
    if (_instance == null) {
      _instance = SocialAuthService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _authService = await AuthService.getInstance();
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  }

  // === Google 로그인 ===
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Google 로그인이 취소되었습니다.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        return AuthResult.failure('Google 토큰을 가져올 수 없습니다.');
      }

      return await _authService.socialLogin(
        type: SocialLoginType.google,
        accessToken: accessToken,
      );
    } catch (e) {
      if (kDebugMode) {
        return await _mockGoogleLogin();
      }
      return AuthResult.failure('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === Kakao 로그인 ===
  Future<AuthResult> signInWithKakao() async {
    try {
      // KakaoTalk 설치 여부 확인 - 올바른 방법
      bool kakaoTalkInstalled = await isKakaoTalkInstalled();

      OAuthToken token;
      if (kakaoTalkInstalled) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      return await _authService.socialLogin(
        type: SocialLoginType.kakao,
        accessToken: token.accessToken,
      );
    } catch (e) {
      if (kDebugMode) {
        return await _mockKakaoLogin();
      }
      return AuthResult.failure('Kakao 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === 로그아웃 ===
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google 로그아웃 오류: $e');
    }
  }

  Future<void> signOutKakao() async {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      debugPrint('Kakao 로그아웃 오류: $e');
    }
  }

  Future<void> signOutAll() async {
    await Future.wait([signOutGoogle(), signOutKakao()]);
  }

  // === 가능 여부 확인 ===
  Future<bool> isGoogleAvailable() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  Future<bool> isKakaoAvailable() async {
    try {
      return await isKakaoTalkInstalled();
    } catch (e) {
      return false;
    }
  }

  // === Mock 메서드들 ===
  Future<AuthResult> _mockGoogleLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    return await _authService.socialLogin(
      type: SocialLoginType.google,
      accessToken: 'mock_google_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<AuthResult> _mockKakaoLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    return await _authService.socialLogin(
      type: SocialLoginType.kakao,
      accessToken: 'mock_kakao_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

class SocialUserInfo {
  final String id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final SocialLoginType provider;

  const SocialUserInfo({
    required this.id,
    this.name,
    this.email,
    this.photoUrl,
    required this.provider,
  });
}
