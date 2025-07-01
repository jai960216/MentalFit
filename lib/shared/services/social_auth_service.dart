import 'package:flutter/foundation.dart';
import 'package:flutter_mentalfit/firebase_options.dart';
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

      // Google Sign-In 초기화 (iOS 시뮬레이터 지원)
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // iOS용 clientId - firebase_options.dart의 iosClientId 사용
        clientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
        // iOS 시뮬레이터에서 웹 기반 로그인 강제
        serverClientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
      );

      if (kDebugMode) {
        print('✅ SocialAuthService 초기화 완료');
        print('📱 iOS Client ID: ${DefaultFirebaseOptions.currentPlatform.iosClientId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SocialAuthService 초기화 실패: $e');
      }
      rethrow;
    }
  }

  // === 실제 Google 로그인 ===
  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('🔥 Google 로그인 시작...');
      }

      // Google 로그인 플로우
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Google 로그인이 취소되었습니다.');
      }

      if (kDebugMode) {
        print('✅ Google 계정 선택 완료: ${googleUser.email}');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return AuthResult.failure('Google 인증 토큰을 가져올 수 없습니다.');
      }

      if (kDebugMode) {
        print('✅ Google 토큰 획득 완료');
      }

      // Firebase 인증 자격증명 생성
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase Auth로 로그인
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        if (kDebugMode) {
          print('✅ Firebase Auth 로그인 완료: ${userCredential.user!.uid}');
        }

        // AuthService를 통해 사용자 정보 처리
        final appUser = await _authService.getCurrentUser();

        if (appUser != null) {
          if (kDebugMode) {
            print('✅ 기존 사용자 로그인 성공: ${appUser.email}');
          }
          return AuthResult.success(appUser);
        } else {
          if (kDebugMode) {
            print('🔧 새 사용자 - Firestore에 정보 생성 중...');
          }

          // 새 사용자인 경우 Firestore에 정보 생성
          final newUser = await _createFirestoreUser(userCredential.user!);
          if (kDebugMode) {
            print('✅ 새 사용자 생성 완료: ${newUser.email}');
          }
          return AuthResult.success(newUser);
        }
      }

      return AuthResult.failure('Firebase 인증에 실패했습니다.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth 오류: ${e.code} - ${e.message}');
      }
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google 로그인 오류: $e');
        print('❌ 오류 타입: ${e.runtimeType}');
      }

      // URL Scheme 관련 오류 처리
      if (e.toString().contains('SIGN_IN_FAILED') || 
          e.toString().contains('sign_in_failed') ||
          e.toString().contains('ApiException')) {
        return AuthResult.failure(
          'Google 로그인 설정 오류입니다.\n'
          'iOS URL Scheme 설정을 확인해주세요.\n'
          'Info.plist에 REVERSED_CLIENT_ID가 올바르게 설정되어 있는지 확인하세요.',
        );
      }

      return AuthResult.failure('Google 로그인 중 오류가 발생했습니다.');
    }
  }

  // === Apple 로그인 ===
  Future<AuthResult> signInWithApple() async {
    try {
      if (kDebugMode) {
        print('🔥 Apple 로그인 시작...');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      if (userCredential.user != null) {
        final appUser = await _authService.getCurrentUser();
        if (appUser != null) {
          return AuthResult.success(appUser);
        } else {
          final newUser = await _createFirestoreUser(userCredential.user!);
          return AuthResult.success(newUser);
        }
      }

      return AuthResult.failure('Apple 로그인에 실패했습니다.');
    } on SignInWithAppleAuthorizationException catch (e) {
      return AuthResult.failure(_getAppleAuthErrorMessage(e));
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Apple 로그인 오류: $e');
      }
      return AuthResult.failure('Apple 로그인 중 오류가 발생했습니다.');
    }
  }

  // === Firestore에 새 사용자 생성 ===
  Future<User> _createFirestoreUser(firebase_auth.User firebaseUser) async {
    final now = DateTime.now();
    final newUser = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? 'unknown@example.com',
      name: firebaseUser.displayName ?? 'User',
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
      if (kDebugMode) {
        print('✅ Firestore에 새 사용자 저장 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore 저장 오류 (계속 진행): $e');
      }
    }

    return newUser;
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
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'user-token-expired':
        return '인증이 만료되었습니다. 다시 로그인해주세요.';
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
      if (kDebugMode) {
        print('✅ Google 로그아웃 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google 로그아웃 오류: $e');
      }
    }
  }

  Future<void> signOutApple() async {
    // Apple 로그아웃은 클라이언트 측에서 처리할 수 없음
    // Firebase Auth 로그아웃으로 충분
  }

  Future<void> signOutAll() async {
    await Future.wait([signOutGoogle(), signOutApple()]);
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
      if (kDebugMode) {
        print('❌ Google 사용자 정보 조회 오류: $e');
      }
      return null;
    }
  }

  // === 가용성 확인 ===
  Future<bool> isGoogleAvailable() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google 가용성 확인 오류: $e');
      }
      return false;
    }
  }

  Future<bool> isAppleAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Apple 가용성 확인 오류: $e');
      }
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