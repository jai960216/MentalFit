import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Firestore 데이터베이스 서비스
/// Firebase Auth와 연동하여 사용자 데이터를 관리합니다.
class FirestoreService {
  static FirestoreService? _instance;
  late FirebaseFirestore _firestore;

  // 싱글톤 패턴
  FirestoreService._();

  static Future<FirestoreService> getInstance() async {
    if (_instance == null) {
      _instance = FirestoreService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _firestore = FirebaseFirestore.instance;
    debugPrint('✅ FirestoreService 초기화 완료');
  }

  // === 컬렉션 참조 ===
  CollectionReference get _usersCollection => _firestore.collection('users');

  CollectionReference get _bookingsCollection =>
      _firestore.collection('bookings');

  CollectionReference get _recordsCollection =>
      _firestore.collection('records');

  CollectionReference get _selfCheckResultsCollection =>
      _firestore.collection('self_check_results');

  // === 사용자 관련 메서드 ===

  /// 사용자 저장 (재시도 로직 포함)
  Future<bool> saveUser(User user) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final userDoc = _firestore.collection('users').doc(user.id);

        // 사용자 데이터를 Map으로 변환
        final userData = {
          'email': user.email,
          'name': user.name,
          'userType': user.userType.value,
          'isOnboardingCompleted': user.isOnboardingCompleted ?? false,
          'profileImageUrl': user.profileImageUrl,
          'birthDate': user.birthDate,
          'sport': user.sport,
          'goal': user.goal,
          'createdAt': user.createdAt,
          'updatedAt': DateTime.now(),
        };

        // Firestore에 저장
        await userDoc.set(userData, SetOptions(merge: true));

        // 저장 확인
        final savedDoc = await userDoc.get();
        if (savedDoc.exists) {
          debugPrint('✅ Firestore 사용자 저장 성공: ${user.email}');
          return true;
        } else {
          throw Exception('저장 후 문서 확인 실패');
        }
      } catch (e) {
        retryCount++;
        debugPrint('❌ Firestore 저장 시도 $retryCount 실패: $e');

        if (retryCount >= maxRetries) {
          debugPrint('❌ Firestore 저장 최종 실패: $e');
          return false;
        }

        // 재시도 전 잠시 대기
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    return false;
  }

  /// 사용자 조회
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return User.fromJson({
          'id': userId,
          ...data,
          // Timestamp를 DateTime으로 변환
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
          'updatedAt':
              (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
        });
      }

      debugPrint('❌ Firestore에서 사용자를 찾을 수 없음: $userId');
      return null;
    } catch (e) {
      debugPrint('❌ Firestore 사용자 조회 오류: $e');
      return null;
    }
  }

  /// 사용자 삭제
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      debugPrint('✅ Firestore 사용자 삭제 성공: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore 사용자 삭제 실패: $e');
      return false;
    }
  }

  /// 온보딩 상태 업데이트
  Future<bool> updateOnboardingStatus(String userId, bool isCompleted) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnboardingCompleted': isCompleted,
        'updatedAt': DateTime.now(),
      });
      debugPrint('✅ Firestore 온보딩 상태 업데이트 성공: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore 온보딩 상태 업데이트 실패: $e');
      return false;
    }
  }

  /// 사용자 프로필 업데이트
  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // 업데이트 시간 추가
      updates['updatedAt'] = DateTime.now();

      await _usersCollection.doc(userId).update(updates);

      debugPrint('✅ 사용자 프로필 업데이트 완료: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ 사용자 프로필 업데이트 실패: $e');
      return false;
    }
  }

  // === 실시간 데이터 스트림 ===

  /// 사용자 정보 실시간 스트림
  Stream<User?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Timestamp를 DateTime으로 변환
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] =
                (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] =
                (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }

          // birthDate 처리 - Timestamp면 String으로, 이미 String이면 그대로
          if (data['birthDate'] is Timestamp) {
            data['birthDate'] =
                (data['birthDate'] as Timestamp)
                    .toDate()
                    .toIso8601String()
                    .split('T')[0];
          } else if (data['birthDate'] is String) {
            // 이미 String이면 그대로 사용 (YYYY-MM-DD 형식 유지)
            data['birthDate'] = data['birthDate'];
          }

          return User.fromJson({'id': userId, ...data});
        } catch (e) {
          debugPrint('❌ 사용자 스트림 파싱 오류: $e');
          return null;
        }
      }
      return null;
    });
  }

  // === 자가진단 결과 관련 ===

  /// 자가진단 결과 저장
  Future<bool> saveSelfCheckResult(
    String userId,
    Map<String, dynamic> result,
  ) async {
    try {
      result['userId'] = userId;
      result['createdAt'] = Timestamp.now();
      result['updatedAt'] = Timestamp.now();

      await _selfCheckResultsCollection.add(result);

      debugPrint('✅ 자가진단 결과 저장 완료: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ 자가진단 결과 저장 실패: $e');
      return false;
    }
  }

  /// 사용자의 자가진단 결과 목록 조회
  Future<List<Map<String, dynamic>>> getSelfCheckResults(String userId) async {
    try {
      final querySnapshot =
          await _selfCheckResultsCollection
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ 자가진단 결과 조회 실패: $e');
      return [];
    }
  }

  // === 예약 관련 ===

  /// 예약 정보 저장
  Future<bool> saveBooking(String userId, Map<String, dynamic> booking) async {
    try {
      booking['userId'] = userId;
      booking['createdAt'] = Timestamp.now();
      booking['updatedAt'] = Timestamp.now();

      await _bookingsCollection.add(booking);

      debugPrint('✅ 예약 정보 저장 완료: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ 예약 정보 저장 실패: $e');
      return false;
    }
  }

  // === 상담 기록 관련 ===

  /// 상담 기록 저장
  Future<bool> saveRecord(String userId, Map<String, dynamic> record) async {
    try {
      record['userId'] = userId;
      record['createdAt'] = Timestamp.now();
      record['updatedAt'] = Timestamp.now();

      await _recordsCollection.add(record);

      debugPrint('✅ 상담 기록 저장 완료: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ 상담 기록 저장 실패: $e');
      return false;
    }
  }

  // === 배치 작업 ===

  /// 배치 쓰기 시작
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// 트랜잭션 실행
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    return await _firestore.runTransaction(updateFunction);
  }

  // === 유틸리티 메서드 ===

  /// 컬렉션 존재 여부 확인
  Future<bool> collectionExists(String collectionPath) async {
    try {
      final snapshot =
          await _firestore.collection(collectionPath).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ 컬렉션 존재 확인 실패: $e');
      return false;
    }
  }

  /// 문서 존재 여부 확인
  Future<bool> documentExists(String collectionPath, String documentId) async {
    try {
      final doc =
          await _firestore.collection(collectionPath).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ 문서 존재 확인 실패: $e');
      return false;
    }
  }

  /// 연결 상태 확인
  Future<bool> checkConnection() async {
    try {
      // Firestore 연결 테스트
      await _firestore.collection('_connection_test').doc('test').get();
      return true;
    } catch (e) {
      debugPrint('❌ Firestore 연결 실패: $e');
      return false;
    }
  }

  /// 사용자 정보 업데이트
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      // updatedAt 필드 자동 업데이트
      data['updatedAt'] = DateTime.now();

      await userDoc.update(data);
      debugPrint('✅ Firestore 사용자 정보 업데이트 성공: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore 사용자 정보 업데이트 실패: $e');
      return false;
    }
  }

  /// 사용자 존재 여부 확인
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Firestore 사용자 존재 여부 확인 실패: $e');
      return false;
    }
  }

  /// 연결 해제 (필요시)
  Future<void> dispose() async {
    // Firestore는 자동으로 연결을 관리하므로 특별한 정리 작업 불필요
    debugPrint('✅ FirestoreService 정리 완료');
  }
}
