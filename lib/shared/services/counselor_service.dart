import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/counselor_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔥 Firebase Firestore 연동 상담사 서비스 (실제 운영용)
class CounselorService {
  static CounselorService? _instance;
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  late CollectionReference<Map<String, dynamic>> _counselorsRef;
  late CollectionReference<Map<String, dynamic>> _appointmentsRef;
  late CollectionReference<Map<String, dynamic>> _reviewsRef;

  // === public 생성자 ===
  CounselorService() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _counselorsRef = _firestore.collection('counselors');
    _appointmentsRef = _firestore.collection('appointments');
    _reviewsRef = _firestore.collection('reviews');
  }

  static Future<CounselorService> getInstance() async {
    if (_instance == null) {
      _instance = CounselorService();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    try {
      debugPrint('✅ CounselorService Firebase 연동 완료');
    } catch (e) {
      debugPrint('❌ CounselorService 초기화 실패: $e');
      rethrow;
    }
  }

  // === 🔥 상담사 목록 조회 (실제 Firebase 데이터만 사용) ===
  Future<List<Counselor>> getCounselors({
    List<String>? specialties,
    CounselingMethod? method,
    double? minRating,
    int? maxPrice,
    bool? onlineOnly,
    String? sortBy = 'rating',
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      debugPrint('🔍 상담사 목록 조회 시작');
      debugPrint(
        '필터: specialties=$specialties, method=$method, minRating=$minRating, maxPrice=$maxPrice, onlineOnly=$onlineOnly',
      );

      Query<Map<String, dynamic>> query = _counselorsRef;

      // === 필터링 조건 적용 ===
      if (specialties != null && specialties.isNotEmpty) {
        query = query.where('specialties', arrayContainsAny: specialties);
      }

      if (method != null) {
        query = query.where(
          'preferredMethod',
          isEqualTo: method.toString().split('.').last,
        );
      }

      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      if (maxPrice != null) {
        query = query.where(
          'price.consultationFee',
          isLessThanOrEqualTo: maxPrice,
        );
      }

      if (onlineOnly == true) {
        query = query.where('isOnline', isEqualTo: true);
      }

      // === 정렬 ===
      switch (sortBy) {
        case 'rating':
          query = query.orderBy('rating', descending: true);
          break;
        case 'experience':
          query = query.orderBy('experienceYears', descending: true);
          break;
        case 'consultation_count':
          query = query.orderBy('consultationCount', descending: true);
          break;
        case 'price_low':
          query = query.orderBy('price.consultationFee', descending: false);
          break;
        case 'price_high':
          query = query.orderBy('price.consultationFee', descending: true);
          break;
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        default:
          query = query.orderBy('rating', descending: true);
      }

      // === 페이지네이션 ===
      query = query.limit(limit);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ 조건에 맞는 상담사가 없습니다');
        return [];
      }

      final counselors = <Counselor>[];
      for (final doc in snapshot.docs) {
        try {
          counselors.add(Counselor.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ 상담사 데이터 파싱 오류: ${doc.id} - $e');
        }
      }

      debugPrint('✅ 상담사 ${counselors.length}명 조회 완료');
      return counselors;
    } catch (e) {
      debugPrint('❌ 상담사 목록 조회 오류: $e');
      // 실제 운영에서는 빈 리스트 반환
      return [];
    }
  }

  // === 🔥 상담사 상세 정보 조회 ===
  Future<Counselor?> getCounselorDetail(String counselorId) async {
    try {
      debugPrint('🔍 상담사 상세 정보 조회: $counselorId');

      final doc = await _counselorsRef.doc(counselorId).get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('⚠️ 상담사 정보를 찾을 수 없습니다: $counselorId');
        return null;
      }

      final counselor = Counselor.fromFirestore(doc);
      debugPrint('✅ 상담사 상세 정보 조회 완료: ${counselor.name}');

      return counselor;
    } catch (e) {
      debugPrint('❌ 상담사 상세 정보 조회 오류: $e');
      return null;
    }
  }

  // === 🔥 예약 가능한 시간 조회 ===
  Future<List<DateTime>> getAvailableSlots(
    String counselorId,
    DateTime date,
  ) async {
    try {
      debugPrint('🔍 예약 가능 시간 조회: $counselorId, $date');

      // 1. 상담사 기본 가능 시간 조회
      final counselor = await getCounselorDetail(counselorId);
      if (counselor == null) {
        debugPrint('⚠️ 상담사 정보를 찾을 수 없습니다');
        return [];
      }

      // 2. 해당 날짜의 요일 확인
      final weekday = _getKoreanWeekday(date.weekday);
      final availableTime =
          counselor.availableTimes
              .where((time) => time.dayOfWeek == weekday && time.isAvailable)
              .firstOrNull;

      if (availableTime == null) {
        debugPrint('⚠️ 해당 요일($weekday)에는 상담 불가');
        return [];
      }

      // 3. 기본 시간 슬롯 생성 (1시간 단위)
      final availableSlots = <DateTime>[];
      final startTime = _parseTime(availableTime.startTime);
      final endTime = _parseTime(availableTime.endTime);

      for (int hour = startTime; hour < endTime; hour++) {
        final slot = DateTime(date.year, date.month, date.day, hour, 0);
        // 현재 시간 이후의 슬롯만 추가
        if (slot.isAfter(DateTime.now())) {
          availableSlots.add(slot);
        }
      }

      // 4. 이미 예약된 시간 제외
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final existingAppointments =
          await _appointmentsRef
              .where('counselorId', isEqualTo: counselorId)
              .where(
                'scheduledDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'scheduledDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .where('status', whereIn: ['confirmed', 'pending'])
              .get();

      final bookedTimes =
          existingAppointments.docs
              .map((doc) => (doc.data()['scheduledDate'] as Timestamp).toDate())
              .toSet();

      final finalSlots =
          availableSlots
              .where(
                (slot) =>
                    !bookedTimes.any(
                      (booked) =>
                          booked.year == slot.year &&
                          booked.month == slot.month &&
                          booked.day == slot.day &&
                          booked.hour == slot.hour,
                    ),
              )
              .toList();

      debugPrint('✅ 예약 가능한 시간 ${finalSlots.length}개 조회 완료');
      return finalSlots;
    } catch (e) {
      debugPrint('❌ 예약 가능 시간 조회 오류: $e');
      return [];
    }
  }

  // === 🔥 예약 생성 ===
  Future<ApiResponse<Appointment>> createAppointment({
    required String counselorId,
    required DateTime scheduledDate,
    required int durationMinutes,
    required CounselingMethod method,
    String? notes,
  }) async {
    try {
      debugPrint('🔍 예약 생성 시작: $counselorId, $scheduledDate');

      // 1. 로그인 상태 확인
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ 로그인 상태가 아닙니다');
        return ApiResponse.failure('로그인이 필요합니다.');
      }

      // 2. 상담사 존재 여부 확인
      final counselor = await getCounselorDetail(counselorId);
      if (counselor == null) {
        debugPrint('❌ 상담사를 찾을 수 없습니다: $counselorId');
        return ApiResponse.failure('상담사 정보를 찾을 수 없습니다.');
      }

      // 3. 예약 가능 시간 확인
      final availableSlots = await getAvailableSlots(
        counselorId,
        scheduledDate,
      );
      if (availableSlots.isEmpty) {
        debugPrint('❌ 해당 시간에 예약이 불가능합니다: $scheduledDate');
        return ApiResponse.failure('선택한 시간에 예약이 불가능합니다.');
      }

      // 4. 중복 예약 확인
      final conflictCheck =
          await _appointmentsRef
              .where('counselorId', isEqualTo: counselorId)
              .where(
                'scheduledDate',
                isEqualTo: Timestamp.fromDate(scheduledDate),
              )
              .where('status', whereIn: ['confirmed', 'pending'])
              .get();

      if (conflictCheck.docs.isNotEmpty) {
        debugPrint('❌ 이미 예약된 시간입니다: $scheduledDate');
        return ApiResponse.failure('선택한 시간에 이미 예약이 있습니다.');
      }

      // 5. 예약 데이터 생성
      final now = DateTime.now();
      final appointmentData = {
        'counselorId': counselorId,
        'userId': currentUser.uid,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'durationMinutes': durationMinutes,
        'method': method.toString().split('.').last,
        'status': 'pending',
        'notes': notes,
        'meetingLink': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'scheduledYear': scheduledDate.year,
        'scheduledMonth': scheduledDate.month,
        'scheduledDay': scheduledDate.day,
        'scheduledHour': scheduledDate.hour,
      };

      debugPrint('📝 예약 데이터 생성: $appointmentData');

      // 6. Firestore에 저장
      final docRef = await _appointmentsRef.add(appointmentData);
      debugPrint('✅ 예약 데이터 저장 완료: ${docRef.id}');

      // 7. 저장된 데이터 조회 및 변환
      final savedDoc = await docRef.get();
      if (!savedDoc.exists) {
        debugPrint('❌ 저장된 예약 데이터를 찾을 수 없습니다: ${docRef.id}');
        return ApiResponse.failure('예약 데이터 저장에 실패했습니다.');
      }

      final appointment = Appointment.fromFirestore(savedDoc);
      debugPrint('✅ 예약 생성 완료: ${appointment.id}');

      return ApiResponse.success(appointment);
    } catch (e) {
      debugPrint('❌ 예약 생성 오류: $e');
      return ApiResponse.failure('예약 생성에 실패했습니다: $e');
    }
  }

  // === 🔥 내 예약 목록 조회 ===
  Future<List<Appointment>> getMyAppointments() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ 로그인 상태가 아닙니다');
        return [];
      }

      debugPrint('🔍 내 예약 목록 조회: ${currentUser.uid}');
      final snapshot =
          await _appointmentsRef
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('scheduledDate', descending: true)
              .get();

      final appointments = <Appointment>[];
      for (final doc in snapshot.docs) {
        try {
          appointments.add(Appointment.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ 예약 데이터 파싱 오류: $e');
        }
      }

      debugPrint('✅ 예약 ${appointments.length}개 조회 완료');
      return appointments;
    } catch (e) {
      debugPrint('❌ 예약 목록 조회 오류: $e');
      return [];
    }
  }

  // === 🔥 예약 취소 ===
  Future<ApiResponse<bool>> cancelAppointment(String appointmentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return ApiResponse.failure('로그인이 필요합니다.');
      }

      debugPrint('🔍 예약 취소: $appointmentId');

      // 예약 정보 확인
      final doc = await _appointmentsRef.doc(appointmentId).get();
      if (!doc.exists) {
        return ApiResponse.failure('예약 정보를 찾을 수 없습니다.');
      }

      final data = doc.data()!;
      if (data['userId'] != currentUser.uid) {
        return ApiResponse.failure('본인의 예약만 취소할 수 있습니다.');
      }

      if (data['status'] == 'cancelled') {
        return ApiResponse.failure('이미 취소된 예약입니다.');
      }

      // 취소 시간 제한 확인 (2시간 전까지)
      final scheduledDate = (data['scheduledDate'] as Timestamp).toDate();
      final now = DateTime.now();
      final timeDifference = scheduledDate.difference(now);

      if (timeDifference.inHours < 2) {
        return ApiResponse.failure('예약 시간 2시간 전까지만 취소 가능합니다.');
      }

      // 상태 업데이트
      await _appointmentsRef.doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(now),
        'cancelledAt': Timestamp.fromDate(now),
      });

      debugPrint('✅ 예약 취소 완료: $appointmentId');
      return ApiResponse.success(true);
    } catch (e) {
      debugPrint('❌ 예약 취소 오류: $e');
      return ApiResponse.failure('예약 취소에 실패했습니다: $e');
    }
  }

  // === 🔥 예약 완료 ===
  Future<ApiResponse<bool>> completeAppointment(String appointmentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return ApiResponse.failure('로그인이 필요합니다.');
      }

      debugPrint('🔍 예약 완료 처리: $appointmentId');

      // 예약 정보 확인
      final doc = await _appointmentsRef.doc(appointmentId).get();
      if (!doc.exists) {
        return ApiResponse.failure('예약 정보를 찾을 수 없습니다.');
      }

      final data = doc.data()!;
      if (data['userId'] != currentUser.uid) {
        return ApiResponse.failure('본인의 예약만 완료 처리할 수 있습니다.');
      }

      if (data['status'] == 'completed') {
        return ApiResponse.failure('이미 완료된 예약입니다.');
      }

      // 상태 업데이트
      final now = DateTime.now();
      await _appointmentsRef.doc(appointmentId).update({
        'status': 'completed',
        'updatedAt': Timestamp.fromDate(now),
        'completedAt': Timestamp.fromDate(now),
      });

      debugPrint('✅ 예약 완료 처리: $appointmentId');
      return ApiResponse.success(true);
    } catch (e) {
      debugPrint('❌ 예약 완료 처리 오류: $e');
      return ApiResponse.failure('예약 완료 처리에 실패했습니다: $e');
    }
  }

  // === 🔥 상담사 검색 ===
  Future<List<Counselor>> searchCounselors(String query) async {
    try {
      debugPrint('🔍 상담사 검색: $query');

      if (query.isEmpty) {
        return getCounselors();
      }

      // 검색 키워드를 소문자로 변환
      final searchQuery = query.toLowerCase();

      // 이름으로 검색
      final nameResults =
          await _counselorsRef
              .where('searchKeywords', arrayContains: searchQuery)
              .limit(10)
              .get();

      final counselors = <Counselor>[];
      for (final doc in nameResults.docs) {
        try {
          counselors.add(Counselor.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ 검색 결과 파싱 오류: $e');
        }
      }

      debugPrint('✅ 검색 결과 ${counselors.length}명');
      return counselors;
    } catch (e) {
      debugPrint('❌ 상담사 검색 오류: $e');
      return [];
    }
  }

  // === 🔥 상담사 리뷰 조회 ===
  Future<List<CounselorReview>> getCounselorReviews(
    String counselorId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔍 상담사 리뷰 조회: $counselorId (페이지: $page)');

      final query = _reviewsRef
          .where('counselorId', isEqualTo: counselorId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ 리뷰가 없습니다: $counselorId');
        return [];
      }

      final reviews = <CounselorReview>[];
      for (final doc in snapshot.docs) {
        try {
          reviews.add(CounselorReview.fromFirestore(doc));
        } catch (e) {
          debugPrint('⚠️ 리뷰 데이터 파싱 오류: $e');
        }
      }

      debugPrint('✅ 리뷰 ${reviews.length}개 조회 완료');
      return reviews;
    } catch (e) {
      debugPrint('❌ 리뷰 조회 오류: $e');
      return [];
    }
  }

  // === 🔥 전문 분야 목록 조회 ===
  Future<List<String>> getSpecialties() async {
    try {
      debugPrint('🔍 전문 분야 목록 조회');

      // 모든 상담사의 전문 분야를 수집
      final snapshot = await _counselorsRef.get();

      final specialtiesSet = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final specialties = List<String>.from(
          data['specialties'] as List? ?? [],
        );
        specialtiesSet.addAll(specialties);
      }

      final specialtiesList = specialtiesSet.toList()..sort();
      debugPrint('✅ 전문 분야 ${specialtiesList.length}개 조회 완료');

      return specialtiesList;
    } catch (e) {
      debugPrint('❌ 전문 분야 조회 오류: $e');
      // 기본 전문 분야 목록 반환
      return [
        '스포츠 심리',
        '스트레스 관리',
        '불안 장애',
        '우울증',
        '수면 장애',
        '인지 행동 치료',
        '정신분석',
        '가족 상담',
        '경기력 향상',
        '집중력 훈련',
        '자신감',
        '분노 조절',
        '대인관계',
        '진로 상담',
        '학습 동기',
      ];
    }
  }

  // === 🔥 실시간 상담사 목록 스트림 ===
  Stream<List<Counselor>> getCounselorsStream() {
    return _counselorsRef
        .orderBy('rating', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final counselors = <Counselor>[];
          for (final doc in snapshot.docs) {
            try {
              counselors.add(Counselor.fromFirestore(doc));
            } catch (e) {
              debugPrint('⚠️ 스트림 데이터 파싱 오류: $e');
            }
          }
          return counselors;
        });
  }

  // === 유틸리티 메서드들 ===
  String _getKoreanWeekday(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }

  int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]);
  }

  // === 상담사 등록 ===
  Future<void> registerCounselor(Counselor counselor) async {
    final docRef = _counselorsRef.doc();
    final data = counselor.toFirestore();
    data['id'] = docRef.id;
    await docRef.set(data);
  }

  // === 상담사 수정 ===
  Future<void> updateCounselor(Counselor counselor) async {
    await _counselorsRef.doc(counselor.id).update(counselor.toFirestore());
  }

  // === 상담사 삭제 ===
  Future<void> deleteCounselor(String id) async {
    await _counselorsRef.doc(id).delete();
  }
}

// === API 응답 래퍼 클래스 ===
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  const ApiResponse._({required this.success, this.data, this.error});

  factory ApiResponse.success(T data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.failure(String error) {
    return ApiResponse._(success: false, error: error);
  }
}

final counselorServiceProvider = Provider<CounselorService>((ref) {
  return CounselorService();
});
