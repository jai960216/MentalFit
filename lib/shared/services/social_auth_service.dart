import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class SocialAuthService {
  static SocialAuthService? _instance;
  late AuthService _authService;

  // 싱글톤 패턴
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
  }

  // === Google 로그인 ===
  Future<AuthResult> signInWithGoogle() async {
    try {
      // TODO: 실제 Google 로그인 구현
      // google_sign_in 패키지 사용 예정

      // 현재는 Mock 데이터로 시뮬레이션
      if (kDebugMode) {
        return await _mockGoogleLogin();
      }

      // 실제 구현 시 아래 코드 사용:
      /*
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
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
      */

      return AuthResult.failure('Google 로그인 기능이 구현되지 않았습니다.');
    } catch (e) {
      return AuthResult.failure('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === Kakao 로그인 ===
  Future<AuthResult> signInWithKakao() async {
    try {
      // TODO: 실제 Kakao 로그인 구현
      // kakao_flutter_sdk 패키지 사용 예정

      // 현재는 Mock 데이터로 시뮬레이션
      if (kDebugMode) {
        return await _mockKakaoLogin();
      }

      // 실제 구현 시 아래 코드 사용:
      /*
      import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

      bool isKakaoTalkInstalled = await isKakaoTalkInstalled();
      
      OAuthToken token;
      if (isKakaoTalkInstalled) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      return await _authService.socialLogin(
        type: SocialLoginType.kakao,
        accessToken: token.accessToken,
      );
      */

      return AuthResult.failure('Kakao 로그인 기능이 구현되지 않았습니다.');
    } catch (e) {
      return AuthResult.failure('Kakao 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === Google 로그아웃 ===
  Future<void> signOutGoogle() async {
    try {
      // TODO: Google 로그아웃 구현
      /*
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      */
    } catch (e) {
      debugPrint('Google 로그아웃 오류: $e');
    }
  }

  // === Kakao 로그아웃 ===
  Future<void> signOutKakao() async {
    try {
      // TODO: Kakao 로그아웃 구현
      /*
      await UserApi.instance.logout();
      */
    } catch (e) {
      debugPrint('Kakao 로그아웃 오류: $e');
    }
  }

  // === 모든 소셜 로그인 로그아웃 ===
  Future<void> signOutAll() async {
    await Future.wait([signOutGoogle(), signOutKakao()]);
  }

  // === Mock 로그인 (개발용) ===
  Future<AuthResult> _mockGoogleLogin() async {
    await Future.delayed(const Duration(seconds: 2)); // 네트워크 지연 시뮬레이션

    return await _authService.socialLogin(
      type: SocialLoginType.google,
      accessToken: 'mock_google_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<AuthResult> _mockKakaoLogin() async {
    await Future.delayed(const Duration(seconds: 2)); // 네트워크 지연 시뮬레이션

    return await _authService.socialLogin(
      type: SocialLoginType.kakao,
      accessToken: 'mock_kakao_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // === 사용자 정보 조회 (소셜 플랫폼별) ===
  Future<SocialUserInfo?> getGoogleUserInfo() async {
    try {
      // TODO: Google 사용자 정보 조회
      /*
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      
      if (currentUser != null) {
        return SocialUserInfo(
          id: currentUser.id,
          name: currentUser.displayName,
          email: currentUser.email,
          photoUrl: currentUser.photoUrl,
          provider: SocialLoginType.google,
        );
      }
      */
      return null;
    } catch (e) {
      debugPrint('Google 사용자 정보 조회 오류: $e');
      return null;
    }
  }

  Future<SocialUserInfo?> getKakaoUserInfo() async {
    try {
      // TODO: Kakao 사용자 정보 조회
      /*
      User user = await UserApi.instance.me();
      
      return SocialUserInfo(
        id: user.id.toString(),
        name: user.kakaoAccount?.profile?.nickname,
        email: user.kakaoAccount?.email,
        photoUrl: user.kakaoAccount?.profile?.profileImageUrl,
        provider: SocialLoginType.kakao,
      );
      */
      return null;
    } catch (e) {
      debugPrint('Kakao 사용자 정보 조회 오류: $e');
      return null;
    }
  }

  // === 소셜 로그인 가능 여부 확인 ===
  Future<bool> isGoogleAvailable() async {
    try {
      // Google Play Services 확인 등
      return true; // 임시로 true 반환
    } catch (e) {
      return false;
    }
  }

  Future<bool> isKakaoAvailable() async {
    try {
      // KakaoTalk 설치 여부 확인 등
      return true; // 임시로 true 반환
    } catch (e) {
      return false;
    }
  }
}

// === 소셜 사용자 정보 클래스 ===
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider.name,
    };
  }

  @override
  String toString() {
    return 'SocialUserInfo(id: $id, name: $name, email: $email, provider: $provider)';
  }
}

// === 소셜 로그인 설정 ===
class SocialAuthConfig {
  // Google 설정
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const List<String> googleScopes = ['email', 'profile'];

  // Kakao 설정
  static const String kakaoAppKey = 'YOUR_KAKAO_APP_KEY';

  // 개발 모드 설정
  static const bool enableMockLogin = kDebugMode;
}
