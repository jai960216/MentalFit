import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'auth_service.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// 실제 Firebase + Google Sign-In 연동 서비스
class SocialAuthService {
  static SocialAuthService? _instance;
  late AuthService _authService;
  late GoogleSignIn _googleSignIn;
  late firebase_auth.FirebaseAuth _firebaseAuth;

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
    try {
      _authService = await AuthService.getInstance();
      _firebaseAuth = firebase_auth.FirebaseAuth.instance;

      // ✅ 수정: Google Sign-In 초기화 (clientId 제거 - google-services.json 자동 사용)
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // clientId를 제거하여 google-services.json의 설정을 자동으로 사용
      );

      debugPrint('✅ SocialAuthService 실제 Firebase 연동 완료');
    } catch (e) {
      debugPrint('❌ SocialAuthService 초기화 실패: $e');
      rethrow;
    }
  }

  // === 실제 Google 로그인 ===
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔥 실제 Google 로그인 시작...');

      // Google 로그인 플로우
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google 로그인이 취소되었습니다');
        return AuthResult.failure('Google 로그인이 취소되었습니다.');
      }

      debugPrint('✅ Google 계정 선택 완료: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Google 토큰을 가져올 수 없습니다');
        return AuthResult.failure('Google 토큰을 가져올 수 없습니다.');
      }

      debugPrint('✅ Google 토큰 획득 완료');

      // Firebase 인증 자격증명 생성
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('✅ Firebase 인증 자격증명 생성 완료');

      // Firebase Auth로 로그인
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        debugPrint('✅ Firebase Auth 로그인 완료: ${userCredential.user!.uid}');

        // AuthService를 통해 사용자 정보 처리
        final appUser = await _authService.getCurrentUser();

        if (appUser != null) {
          debugPrint('✅ 기존 사용자 로그인 성공: ${appUser.email}');
          return AuthResult.success(appUser);
        } else {
          debugPrint('🔧 새 사용자 - Firestore에 정보 생성 중...');

          // 새 사용자인 경우 Firestore에 정보 생성
          final newUser = await _createFirestoreUser(userCredential.user!);
          debugPrint('✅ 새 사용자 생성 완료: ${newUser.email}');
          return AuthResult.success(newUser);
        }
      }

      debugPrint('❌ Firebase Auth 로그인 실패');
      return AuthResult.failure('Google 로그인에 실패했습니다.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth 오류: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Google 로그인 오류: $e');
      debugPrint('❌ 오류 상세 정보: ${e.runtimeType}');

      // ApiException: 10 (DEVELOPER_ERROR) 처리
      if (e.toString().contains('ApiException: 10')) {
        debugPrint('🚨 DEVELOPER_ERROR (ApiException: 10) 발생!');
        debugPrint('🚨 해결방법:');
        debugPrint('🚨 1. Firebase Console → Authentication → Google 활성화');
        debugPrint('🚨 2. Android Studio에서 SHA-1 키 생성 및 등록');
        debugPrint('🚨 3. 새로운 google-services.json 다운로드');
        debugPrint('🚨 4. AndroidManifest.xml에 enableOnBackInvokedCallback 추가');

        // ✅ 개발 중에는 Mock 로그인으로 대체
        if (kDebugMode) {
          debugPrint('🔧 개발 모드에서 Mock 로그인으로 대체합니다...');
          return await _fallbackMockLogin();
        }

        return AuthResult.failure(
          'Google 로그인 설정이 완료되지 않았습니다.\n'
          'Firebase Console에서 Google 인증을 활성화하고\n'
          'SHA-1 키를 등록해주세요.',
        );
      }

      return AuthResult.failure('Google 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === Kakao 로그인 (Mock) ===
  Future<AuthResult> signInWithKakao() async {
    try {
      debugPrint('🔧 Kakao Mock 로그인 시작...');
      await Future.delayed(const Duration(seconds: 1));

      final mockUser = await _createMockUser(
        provider: 'kakao',
        email: 'mock.kakao.user@kakao.com',
        name: 'Mock Kakao User',
      );

      debugPrint('✅ Kakao Mock 로그인 성공');
      return AuthResult.success(mockUser);
    } catch (e) {
      debugPrint('❌ Kakao 로그인 오류: $e');
      return AuthResult.failure('Kakao 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === Apple 로그인 ===
  Future<AuthResult> signInWithApple() async {
    try {
      debugPrint('🔥 Apple 로그인 시작...');

      // Apple 로그인 요청
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('✅ Apple 인증 완료');

      // Firebase 인증 자격증명 생성
      final oauthCredential = firebase_auth.OAuthProvider(
        'apple.com',
      ).credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      debugPrint('✅ Firebase 인증 자격증명 생성 완료');

      // Firebase Auth로 로그인
      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      if (userCredential.user != null) {
        debugPrint('✅ Firebase Auth 로그인 완료: ${userCredential.user!.uid}');

        // AuthService를 통해 사용자 정보 처리
        final appUser = await _authService.getCurrentUser();

        if (appUser != null) {
          debugPrint('✅ 기존 사용자 로그인 성공: ${appUser.email}');
          return AuthResult.success(appUser);
        } else {
          debugPrint('🔧 새 사용자 - Firestore에 정보 생성 중...');

          // 새 사용자인 경우 Firestore에 정보 생성
          final newUser = await _createFirestoreUser(userCredential.user!);
          debugPrint('✅ 새 사용자 생성 완료: ${newUser.email}');
          return AuthResult.success(newUser);
        }
      }

      debugPrint('❌ Firebase Auth 로그인 실패');
      return AuthResult.failure('Apple 로그인에 실패했습니다.');
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('❌ Apple 로그인 오류: ${e.code} - ${e.message}');
      return AuthResult.failure(_getAppleAuthErrorMessage(e));
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth 오류: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Apple 로그인 오류: $e');
      return AuthResult.failure('Apple 로그인 중 오류가 발생했습니다: $e');
    }
  }

  // === Firestore에 새 사용자 생성 ===
  Future<User> _createFirestoreUser(firebase_auth.User firebaseUser) async {
    final now = DateTime.now();
    final newUser = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? 'unknown@gmail.com',
      name: firebaseUser.displayName ?? 'Google User',
      userType: UserType.general,
      isOnboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
      profileImageUrl: firebaseUser.photoURL,
      birthDate: null,
      sport: null,
      goal: null,
    );

    // Firestore에 저장
    try {
      final firestoreService = await FirestoreService.getInstance();
      await firestoreService.saveUser(newUser);
      debugPrint('✅ Firestore에 새 사용자 저장 완료');
    } catch (e) {
      debugPrint('❌ Firestore 저장 오류 (계속 진행): $e');
    }

    return newUser;
  }

  // === Google Sign-In 설정 오류시 Fallback Mock 로그인 ===
  Future<AuthResult> _fallbackMockLogin() async {
    try {
      debugPrint('🔧 Fallback Mock Google 로그인 실행...');
      debugPrint('🔧 Google Console 설정을 확인해주세요:');
      debugPrint('🔧 1. OAuth 2.0 클라이언트 ID 생성');
      debugPrint('🔧 2. SHA-1 키 등록 확인');
      debugPrint('🔧 3. google-services.json 업데이트');

      await Future.delayed(const Duration(seconds: 1));

      final mockUser = await _createMockUser(
        provider: 'google',
        email: 'mock.google.user@gmail.com',
        name: 'Mock Google User (설정 오류로 인한 Fallback)',
      );

      debugPrint('✅ Fallback Mock 로그인 성공');
      return AuthResult.success(mockUser);
    } catch (e) {
      debugPrint('❌ Fallback Mock 로그인 오류: $e');
      return AuthResult.failure('Mock 로그인 오류: $e');
    }
  }

  // === Mock 사용자 생성 ===
  Future<User> _createMockUser({
    required String provider,
    required String email,
    required String name,
  }) async {
    final now = DateTime.now();
    final mockUser = User(
      id: 'mock_${provider}_${now.millisecondsSinceEpoch}',
      email: email,
      name: name,
      userType: UserType.general,
      isOnboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
      profileImageUrl: null,
      birthDate: null,
      sport: null,
      goal: null,
    );

    // Mock 사용자도 Firestore에 저장 시도
    try {
      final firestoreService = await FirestoreService.getInstance();
      await firestoreService.saveUser(mockUser);
      debugPrint('✅ Mock 사용자 Firestore 저장 완료');
    } catch (e) {
      debugPrint('❌ Mock 사용자 Firestore 저장 오류 (계속 진행): $e');
    }

    return mockUser;
  }

  // === Firebase Auth 에러 메시지 한국어 변환 ===
  String _getFirebaseAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return '다른 로그인 방법으로 이미 가입된 계정입니다.';
      case 'invalid-credential':
        return '인증 정보가 올바르지 않습니다.';
      case 'operation-not-allowed':
        return '해당 로그인 방법이 비활성화되어 있습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'user-not-found':
        return '사용자를 찾을 수 없습니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return e.message ?? 'Google 로그인 중 오류가 발생했습니다.';
    }
  }

  // === Apple 로그인 에러 메시지 변환 ===
  String _getAppleAuthErrorMessage(SignInWithAppleAuthorizationException e) {
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        return 'Apple 로그인이 취소되었습니다.';
      case AuthorizationErrorCode.invalidResponse:
        return 'Apple 로그인 응답이 올바르지 않습니다.';
      case AuthorizationErrorCode.notHandled:
        return 'Apple 로그인 처리가 되지 않았습니다.';
      case AuthorizationErrorCode.notInteractive:
        return 'Apple 로그인 상호작용이 불가능합니다.';
      case AuthorizationErrorCode.unknown:
        return '알 수 없는 Apple 로그인 오류가 발생했습니다.';
      default:
        return e.message ?? 'Apple 로그인 중 오류가 발생했습니다.';
    }
  }

  // === 로그아웃 ===
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ Google 로그아웃 완료');
    } catch (e) {
      debugPrint('❌ Google 로그아웃 오류: $e');
    }
  }

  Future<void> signOutKakao() async {
    try {
      debugPrint('✅ Kakao 로그아웃 완료 (Mock)');
    } catch (e) {
      debugPrint('❌ Kakao 로그아웃 오류: $e');
    }
  }

  Future<void> signOutApple() async {
    try {
      // Apple 로그아웃은 클라이언트 측에서 처리할 수 없음
      // Firebase Auth 로그아웃으로 충분
      debugPrint('✅ Apple 로그아웃 완료');
    } catch (e) {
      debugPrint('❌ Apple 로그아웃 오류: $e');
    }
  }

  Future<void> signOutAll() async {
    await Future.wait([signOutGoogle(), signOutKakao(), signOutApple()]);
    debugPrint('✅ 모든 소셜 로그인 로그아웃 완료');
  }

  // === 사용자 정보 조회 ===
  Future<SocialUserInfo?> getGoogleUserInfo() async {
    try {
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        return SocialUserInfo(
          id: currentUser.id,
          name: currentUser.displayName,
          email: currentUser.email,
          photoUrl: currentUser.photoUrl,
          provider: SocialLoginType.google,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Google 사용자 정보 조회 오류: $e');
      return null;
    }
  }

  Future<SocialUserInfo?> getKakaoUserInfo() async {
    return null; // Mock에서는 null 반환
  }

  // === 가용성 확인 ===
  Future<bool> isGoogleAvailable() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      debugPrint('❌ Google 가용성 확인 오류: $e');
      return false;
    }
  }

  Future<bool> isKakaoAvailable() async {
    return true; // Mock에서는 항상 true
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

  factory SocialUserInfo.fromJson(Map<String, dynamic> json) {
    return SocialUserInfo(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      provider: SocialLoginType.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => SocialLoginType.google,
      ),
    );
  }

  @override
  String toString() {
    return 'SocialUserInfo(id: $id, name: $name, email: $email, provider: ${provider.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialUserInfo &&
        other.id == id &&
        other.provider == provider;
  }

  @override
  int get hashCode => Object.hash(id, provider);
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

  // 지원되는 소셜 로그인 플랫폼
  static const List<SocialLoginType> supportedPlatforms = [
    SocialLoginType.google,
    SocialLoginType.kakao,
  ];

  // 플랫폼별 활성화 여부
  static const Map<SocialLoginType, bool> platformEnabled = {
    SocialLoginType.google: true,
    SocialLoginType.kakao: true,
  };

  // 디버그 설정
  static const bool enableDebugLogs = kDebugMode;
}
