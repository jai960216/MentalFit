import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart' as app_user;

/// Firebase Auth 기반 인증 서비스
/// 기존 REST API + TokenManager 방식을 Firebase Auth로 완전 교체
class AuthService {
  static AuthService? _instance;

  late firebase_auth.FirebaseAuth _auth;
  late FirebaseFirestore _firestore;

  // 싱글톤 패턴 (기존 인터페이스 유지)
  AuthService._();

  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      _instance = AuthService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _auth = firebase_auth.FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    // 인증 상태 변화 리스너 설정
    _setupAuthStateListener();
  }

  /// === 인증 상태 변화 리스너 ===
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        debugPrint('✅ Firebase 사용자 로그인됨: ${firebaseUser.uid}');
      } else {
        debugPrint('❌ Firebase 사용자 로그아웃됨');
      }
    });
  }

  /// === 이메일/비밀번호 로그인 ===
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Firebase Auth 로그인
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Firestore에서 사용자 정보 가져오기
        final appUser = await _getUserFromFirestore(credential.user!.uid);

        if (appUser != null) {
          return AuthResult.success(appUser);
        } else {
          // Firestore에 사용자 정보가 없으면 생성
          final newUser = await _createUserInFirestore(credential.user!);
          return AuthResult.success(newUser);
        }
      }

      return AuthResult.failure('로그인에 실패했습니다.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('로그인 오류: $e');
      return AuthResult.failure('로그인 중 오류가 발생했습니다: $e');
    }
  }

  /// === 이메일/비밀번호 회원가입 ===
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required app_user.UserType userType,
  }) async {
    try {
      // Firebase Auth 회원가입
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        try {
          // 사용자 표시명 업데이트
          await credential.user!.updateDisplayName(name);

          // Firestore에 사용자 정보 저장
          final appUser = await _createUserInFirestore(
            credential.user!,
            name: name,
            userType: userType,
          );

          // Firestore 저장 확인
          final savedUser = await _getUserFromFirestore(credential.user!.uid);
          if (savedUser == null) {
            throw Exception('Firestore에 사용자 정보 저장 실패');
          }

          return AuthResult.success(appUser);
        } catch (e) {
          // Firestore 저장 실패 시 Firebase Auth 사용자 삭제
          await credential.user!.delete();
          throw Exception('사용자 정보 저장 실패: $e');
        }
      }

      return AuthResult.failure('회원가입에 실패했습니다.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      return AuthResult.failure('회원가입 중 오류가 발생했습니다: $e');
    }
  }

  /// === 소셜 로그인 (Firebase Auth Credential 사용) ===
  Future<AuthResult> socialLogin({
    required SocialLoginType type,
    required String accessToken,
  }) async {
    try {
      firebase_auth.AuthCredential credential;

      switch (type) {
        case SocialLoginType.google:
          // Google OAuth Credential 생성
          credential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: accessToken,
          );
          break;
        case SocialLoginType.kakao:
          // Kakao는 Firebase에서 직접 지원하지 않으므로 Custom Token 방식 사용
          // 또는 익명 로그인 후 Firestore에 Kakao 정보 저장
          final userCredential = await _auth.signInAnonymously();
          if (userCredential.user != null) {
            final appUser = await _createUserInFirestore(
              userCredential.user!,
              name: 'Kakao 사용자',
              socialProvider: 'kakao',
              socialId: accessToken, // 임시로 사용
            );
            return AuthResult.success(appUser);
          }
          return AuthResult.failure('Kakao 로그인에 실패했습니다.');
      }

      // Firebase Auth 소셜 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Firestore에서 또는 새로 생성
        final appUser =
            await _getUserFromFirestore(userCredential.user!.uid) ??
            await _createUserInFirestore(userCredential.user!);

        return AuthResult.success(appUser);
      }

      return AuthResult.failure('소셜 로그인에 실패했습니다.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('소셜 로그인 오류: $e');
      return AuthResult.failure('소셜 로그인 중 오류가 발생했습니다: $e');
    }
  }

  /// === 현재 로그인된 사용자 정보 가져오기 ===
  Future<app_user.User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      return await _getUserFromFirestore(firebaseUser.uid);
    } catch (e) {
      debugPrint('현재 사용자 정보 가져오기 실패: $e');
      return null;
    }
  }

  /// === 자동 로그인 체크 ===
  Future<app_user.User?> checkAutoLogin() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      // 토큰 유효성 자동 체크 (Firebase가 알아서 처리)
      await firebaseUser.reload();

      return await getCurrentUser();
    } catch (e) {
      debugPrint('자동 로그인 체크 실패: $e');
      return null;
    }
  }

  /// === 로그아웃 ===
  Future<bool> logout() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      debugPrint('로그아웃 실패: $e');
      return false;
    }
  }

  /// === 비밀번호 재설정 ===
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('비밀번호 재설정 실패: ${_getAuthErrorMessage(e)}');
      return false;
    } catch (e) {
      debugPrint('비밀번호 재설정 실패: $e');
      return false;
    }
  }

  /// === 호환성을 위한 별칭 ===
  Future<bool> requestPasswordReset(String email) async {
    return await resetPassword(email);
  }

  /// === 프로필 업데이트 ===
  Future<app_user.User?> updateProfile({
    String? name,
    String? profileImageUrl,
    String? birthDate,
    String? sport,
    String? goal,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      // Firestore 업데이트 데이터 준비
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
        // Firebase Auth 프로필 이미지 업데이트
        await firebaseUser.updatePhotoURL(profileImageUrl);
      }
      if (birthDate != null) updateData['birthDate'] = birthDate;
      if (sport != null) updateData['sport'] = sport;
      if (goal != null) updateData['goal'] = goal;

      // Firebase Auth 프로필 업데이트
      if (name != null) {
        await firebaseUser.updateDisplayName(name);
      }

      // Firestore 문서 업데이트
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .update(updateData);

      // 업데이트된 사용자 정보 반환
      final updatedUser = await getCurrentUser();
      if (updatedUser != null) {
        debugPrint('✅ 프로필 업데이트 성공: ${updatedUser.name}');
      }
      return updatedUser;
    } catch (e) {
      debugPrint('❌ 프로필 업데이트 실패: $e');
      return null;
    }
  }

  /// === 비밀번호 변경 ===
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null || firebaseUser.email == null) {
        return false;
      }

      // 현재 비밀번호로 재인증
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );

      await firebaseUser.reauthenticateWithCredential(credential);

      // 새 비밀번호로 변경
      await firebaseUser.updatePassword(newPassword);

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('비밀번호 변경 실패: ${_getAuthErrorMessage(e)}');
      return false;
    } catch (e) {
      debugPrint('비밀번호 변경 실패: $e');
      return false;
    }
  }

  /// === 계정 삭제 ===
  Future<bool> deleteAccount(String password) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return false;

      // 이메일 계정인 경우 재인증
      if (firebaseUser.email != null) {
        final credential = firebase_auth.EmailAuthProvider.credential(
          email: firebaseUser.email!,
          password: password,
        );
        await firebaseUser.reauthenticateWithCredential(credential);
      }

      // Firestore에서 사용자 데이터 삭제
      await _firestore.collection('users').doc(firebaseUser.uid).delete();

      // Firebase Auth에서 계정 삭제
      await firebaseUser.delete();

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('계정 삭제 실패: ${_getAuthErrorMessage(e)}');
      return false;
    } catch (e) {
      debugPrint('계정 삭제 실패: $e');
      return false;
    }
  }

  /// === Firestore 관련 헬퍼 메서드들 ===

  /// Firestore에서 사용자 정보 가져오기
  Future<app_user.User?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return app_user.User.fromJson({
          'id': uid,
          ...data,
          // Timestamp를 DateTime으로 변환
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
          'updatedAt':
              (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
        });
      }

      // Firestore에 정보가 없으면 Firebase Auth의 currentUser 정보로 임시 User 객체 반환
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == uid) {
        return app_user.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '사용자',
          userType: app_user.UserType.general,
          isOnboardingCompleted: false,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
          profileImageUrl: firebaseUser.photoURL,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Firestore 사용자 정보 가져오기 실패: $e');
      return null;
    }
  }

  /// Firestore에 사용자 정보 생성
  Future<app_user.User> _createUserInFirestore(
    firebase_auth.User firebaseUser, {
    String? name,
    app_user.UserType? userType,
    String? email,
    String? profileImageUrl,
    String? socialProvider,
    String? socialId,
  }) async {
    final now = Timestamp.now();

    final userData = {
      'email': email ?? firebaseUser.email ?? '',
      'name': name ?? firebaseUser.displayName ?? '사용자',
      'userType': (userType ?? app_user.UserType.general).value,
      'isOnboardingCompleted': false,
      'createdAt': now,
      'updatedAt': now,
      'profileImageUrl': profileImageUrl ?? firebaseUser.photoURL,
      'socialProvider': socialProvider,
      'socialId': socialId,
    };

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

    return app_user.User(
      id: firebaseUser.uid,
      email: userData['email'] as String,
      name: userData['name'] as String,
      userType: userType ?? app_user.UserType.general,
      isOnboardingCompleted: false,
      createdAt: now.toDate(),
      updatedAt: now.toDate(),
      profileImageUrl: userData['profileImageUrl'] as String?,
    );
  }

  /// Firebase Auth 에러 메시지 한국어 변환
  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 간단합니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 시도로 인해 일시적으로 차단되었습니다.';
      case 'requires-recent-login':
        return '보안을 위해 다시 로그인해주세요.';
      default:
        return e.message ?? '인증 오류가 발생했습니다.';
    }
  }

  /// === 개발용 메서드들 ===

  /// 현재 Firebase 사용자 UID 가져오기
  String? get currentUserUid => _auth.currentUser?.uid;

  /// Firebase Auth 상태 스트림
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// 이메일 인증 발송
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('이메일 인증 발송 실패: $e');
      return false;
    }
  }
}

/// === 인증 결과 클래스 (기존 인터페이스 유지) ===
class AuthResult {
  final bool success;
  final app_user.User? user;
  final String? error;

  const AuthResult._(this.success, this.user, this.error);

  factory AuthResult.success(app_user.User user) {
    return AuthResult._(true, user, null);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(false, null, error);
  }
}

/// === 소셜 로그인 타입 (기존 인터페이스 유지) ===
enum SocialLoginType { google, kakao }

/// === 인증 상태 (기존 인터페이스 유지) ===
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }
