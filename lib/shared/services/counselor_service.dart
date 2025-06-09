import 'package:flutter/foundation.dart';
import '../models/counselor_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_response.dart';
import '../../core/network/token_manager.dart';

class CounselorService {
  static CounselorService? _instance;
  late ApiClient _apiClient;
  late TokenManager _tokenManager;

  // 싱글톤 패턴
  CounselorService._();

  static Future<CounselorService> getInstance() async {
    if (_instance == null) {
      _instance = CounselorService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _apiClient = await ApiClient.getInstance();
    _tokenManager = await TokenManager.getInstance();
  }

  // === 상담사 목록 조회 ===
  Future<List<Counselor>> getCounselors({
    List<String>? specialties,
    CounselingMethod? method,
    double? minRating,
    int? maxPrice,
    bool? onlineOnly,
    String? sortBy, // rating, price, experience
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (specialties != null && specialties.isNotEmpty) {
        queryParams['specialties'] = specialties.join(',');
      }
      if (method != null) {
        queryParams['method'] = method.value;
      }
      if (minRating != null) {
        queryParams['minRating'] = minRating;
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice;
      }
      if (onlineOnly != null) {
        queryParams['onlineOnly'] = onlineOnly;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }

      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.counselors,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((json) => Counselor.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return _getMockCounselors(); // 개발용 목업 데이터
    } catch (e) {
      debugPrint('상담사 목록 조회 오류: $e');
      return _getMockCounselors(); // 에러 시 목업 데이터 반환
    }
  }

  // === 상담사 상세 정보 조회 ===
  Future<Counselor?> getCounselorDetail(String counselorId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiEndpoints.counselors}/$counselorId',
      );

      if (response.success && response.data != null) {
        return Counselor.fromJson(response.data!);
      }

      // 목업 데이터에서 찾기
      final mockCounselors = _getMockCounselors();
      return mockCounselors.firstWhere(
        (counselor) => counselor.id == counselorId,
        orElse: () => mockCounselors.first,
      );
    } catch (e) {
      debugPrint('상담사 상세 정보 조회 오류: $e');
      // 에러 시 목업 데이터의 첫 번째 항목 반환
      return _getMockCounselors().first;
    }
  }

  // === 상담사 검색 ===
  Future<List<Counselor>> searchCounselors(String query) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.counselors}/search',
        queryParameters: {'q': query},
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((json) => Counselor.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // 목업 데이터에서 검색
      final mockCounselors = _getMockCounselors();
      return mockCounselors
          .where(
            (counselor) =>
                counselor.name.toLowerCase().contains(query.toLowerCase()) ||
                counselor.specialties.any(
                  (specialty) =>
                      specialty.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    } catch (e) {
      debugPrint('상담사 검색 오류: $e');
      return [];
    }
  }

  // === 상담사 리뷰 조회 ===
  Future<List<CounselorReview>> getCounselorReviews(
    String counselorId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.counselors}/$counselorId/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.success && response.data != null) {
        return response.data!
            .map(
              (json) => CounselorReview.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      return _getMockReviews(counselorId);
    } catch (e) {
      debugPrint('상담사 리뷰 조회 오류: $e');
      return _getMockReviews(counselorId);
    }
  }

  // === 예약 가능한 시간 조회 ===
  Future<List<DateTime>> getAvailableSlots(
    String counselorId,
    DateTime date,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.counselors}/$counselorId/available-slots',
        queryParameters: {'date': date.toIso8601String().split('T')[0]},
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((slot) => DateTime.parse(slot as String))
            .toList();
      }

      return _getMockAvailableSlots(date);
    } catch (e) {
      debugPrint('예약 가능 시간 조회 오류: $e');
      return _getMockAvailableSlots(date);
    }
  }

  // === 예약 생성 ===
  Future<AppointmentResult> createAppointment({
    required String counselorId,
    required DateTime scheduledDate,
    required int durationMinutes,
    required CounselingMethod method,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.appointments,
        data: {
          'counselorId': counselorId,
          'scheduledDate': scheduledDate.toIso8601String(),
          'durationMinutes': durationMinutes,
          'method': method.value,
          'notes': notes,
        },
      );

      if (response.success && response.data != null) {
        final appointment = Appointment.fromJson(response.data!);
        return AppointmentResult.success(appointment);
      }

      // 목업 응답
      final appointment = _createMockAppointment(
        counselorId,
        scheduledDate,
        durationMinutes,
        method,
        notes,
      );
      return AppointmentResult.success(appointment);
    } catch (e) {
      debugPrint('예약 생성 오류: $e');
      return AppointmentResult.failure('예약 생성에 실패했습니다.');
    }
  }

  // === 내 예약 목록 조회 ===
  Future<List<Appointment>> getMyAppointments() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.appointments,
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return _getMockAppointments();
    } catch (e) {
      debugPrint('내 예약 목록 조회 오류: $e');
      return _getMockAppointments();
    }
  }

  // === 전문 분야 목록 조회 ===
  Future<List<String>> getSpecialties() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.counselors}/specialties',
      );

      if (response.success && response.data != null) {
        return response.data!.cast<String>();
      }

      return _getMockSpecialties();
    } catch (e) {
      debugPrint('전문 분야 목록 조회 오류: $e');
      return _getMockSpecialties();
    }
  }

  // === 예약 취소 ===
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${ApiEndpoints.appointments}/$appointmentId',
      );

      if (response.success) {
        return true;
      }

      // 목업 응답 - 항상 성공
      return true;
    } catch (e) {
      debugPrint('예약 취소 오류: $e');
      return false;
    }
  }

  // === 목업 데이터 생성 메서드들 ===
  List<Counselor> _getMockCounselors() {
    final now = DateTime.now();

    return [
      Counselor(
        id: 'counselor_1',
        name: '김민지',
        profileImageUrl: null,
        title: '임상심리사',
        specialties: ['스포츠 심리', '스트레스 관리', '불안 장애'],
        introduction:
            '10년 이상의 스포츠 심리 상담 경험을 가진 전문가입니다. 운동선수들의 멘탈 코칭과 경기력 향상을 위한 심리 훈련을 전문으로 합니다.',
        rating: 4.9,
        reviewCount: 127,
        experienceYears: 12,
        qualifications: ['임상심리사 1급', '스포츠심리상담사', '서울대 심리학과 박사'],
        isOnline: true,
        consultationCount: 234,
        price: const Price(
          consultationFee: 80000,
          packagePrice: 300000,
          packageSessions: 4,
        ),
        availableTimes: [
          const AvailableTime(
            dayOfWeek: '월',
            startTime: '09:00',
            endTime: '18:00',
            isAvailable: true,
          ),
          const AvailableTime(
            dayOfWeek: '화',
            startTime: '09:00',
            endTime: '18:00',
            isAvailable: true,
          ),
        ],
        languages: ['한국어', '영어'],
        preferredMethod: CounselingMethod.video,
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now,
      ),
      Counselor(
        id: 'counselor_2',
        name: '박준호',
        profileImageUrl: null,
        title: '스포츠심리상담사',
        specialties: ['경기력 향상', '집중력 훈련', '자신감'],
        introduction: '프로 운동선수들과 함께 일한 경험이 풍부한 스포츠 심리 전문가입니다.',
        rating: 4.8,
        reviewCount: 98,
        experienceYears: 8,
        qualifications: ['스포츠심리상담사', '정신건강임상심리사', '연세대 체육학과 석사'],
        isOnline: false,
        consultationCount: 156,
        price: const Price(
          consultationFee: 70000,
          packagePrice: 250000,
          packageSessions: 4,
        ),
        availableTimes: [
          const AvailableTime(
            dayOfWeek: '수',
            startTime: '10:00',
            endTime: '17:00',
            isAvailable: true,
          ),
        ],
        languages: ['한국어'],
        preferredMethod: CounselingMethod.faceToFace,
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
      ),
    ];
  }

  List<CounselorReview> _getMockReviews(String counselorId) {
    return [
      CounselorReview(
        id: 'review_1',
        counselorId: counselorId,
        userId: 'user_1',
        userName: '김**',
        rating: 5.0,
        content: '정말 도움이 많이 되었습니다. 경기 전 불안감이 많이 줄어들었어요.',
        tags: ['친절함', '전문성', '효과적'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      CounselorReview(
        id: 'review_2',
        counselorId: counselorId,
        userId: 'user_2',
        userName: '이**',
        rating: 4.5,
        content: '체계적인 상담으로 멘탈이 많이 강해졌습니다.',
        tags: ['체계적', '이해력'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  List<DateTime> _getMockAvailableSlots(DateTime date) {
    final slots = <DateTime>[];
    final startHour = 9;
    final endHour = 18;

    for (int hour = startHour; hour < endHour; hour++) {
      slots.add(DateTime(date.year, date.month, date.day, hour, 0));
      slots.add(DateTime(date.year, date.month, date.day, hour, 30));
    }

    return slots;
  }

  Appointment _createMockAppointment(
    String counselorId,
    DateTime scheduledDate,
    int durationMinutes,
    CounselingMethod method,
    String? notes,
  ) {
    return Appointment(
      id: 'appointment_${DateTime.now().millisecondsSinceEpoch}',
      counselorId: counselorId,
      userId: 'current_user',
      scheduledDate: scheduledDate,
      durationMinutes: durationMinutes,
      method: method,
      status: AppointmentStatus.pending,
      notes: notes,
      meetingLink:
          method == CounselingMethod.video
              ? 'https://meet.mentalfit.app/room123'
              : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<Appointment> _getMockAppointments() {
    final now = DateTime.now();

    return [
      Appointment(
        id: 'appointment_1',
        counselorId: 'counselor_1',
        userId: 'current_user',
        scheduledDate: now.add(const Duration(days: 3, hours: 14)),
        durationMinutes: 60,
        method: CounselingMethod.video,
        status: AppointmentStatus.confirmed,
        notes: '경기 전 불안감 상담 요청',
        meetingLink: 'https://meet.mentalfit.app/room123',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Appointment(
        id: 'appointment_2',
        counselorId: 'counselor_2',
        userId: 'current_user',
        scheduledDate: now.subtract(const Duration(days: 7)),
        durationMinutes: 60,
        method: CounselingMethod.faceToFace,
        status: AppointmentStatus.completed,
        notes: '스트레스 관리',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  List<String> _getMockSpecialties() {
    return [
      '스포츠 심리',
      '스트레스 관리',
      '불안 장애',
      '우울증',
      '공황장애',
      '경기력 향상',
      '집중력 훈련',
      '자신감',
      '정신건강',
      '트라우마',
      '수면 장애',
      '중독',
      '대인관계',
      '진로 상담',
      '학습 상담',
    ];
  }
}

// === 예약 결과 클래스 ===
class AppointmentResult {
  final bool success;
  final Appointment? appointment;
  final String? error;

  const AppointmentResult._({
    required this.success,
    this.appointment,
    this.error,
  });

  factory AppointmentResult.success(Appointment appointment) {
    return AppointmentResult._(success: true, appointment: appointment);
  }

  factory AppointmentResult.failure(String error) {
    return AppointmentResult._(success: false, error: error);
  }
}
