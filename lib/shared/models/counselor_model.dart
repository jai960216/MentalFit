import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// === 상담 방식 ===
enum CounselingMethod {
  online,
  offline,
  all;

  String get displayName {
    switch (this) {
      case CounselingMethod.online:
        return '온라인 상담';
      case CounselingMethod.offline:
        return '오프라인 상담';
      case CounselingMethod.all:
        return '온/오프라인 모두 가능';
    }
  }

  IconData get icon {
    switch (this) {
      case CounselingMethod.online:
        return Icons.video_camera_front;
      case CounselingMethod.offline:
        return Icons.people;
      case CounselingMethod.all:
        return Icons.all_inclusive;
    }
  }
}

// === 예약 상태 ===
enum AppointmentStatus {
  pending('pending', '대기중'),
  confirmed('confirmed', '확정'),
  completed('completed', '완료'),
  cancelled('cancelled', '취소됨'),
  noShow('no_show', '노쇼');

  const AppointmentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AppointmentStatus.pending,
    );
  }

  @override
  String toString() => displayName;
}

// === 상담사 등록 요청 상태 ===
enum CounselorRequestStatus {
  pending('pending', '대기중'),
  approved('approved', '승인됨'),
  rejected('rejected', '거부됨');

  const CounselorRequestStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static CounselorRequestStatus fromString(String value) {
    return CounselorRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CounselorRequestStatus.pending,
    );
  }

  @override
  String toString() => displayName;
}

// === 상담사 모델 (Firebase 호환) ===
class Counselor {
  final String id;
  final String userId;
  final String name;
  final String? profileImageUrl;
  final String title;
  final String introduction;
  final double rating;
  final int reviewCount;
  final List<String> specialties;
  final int experienceYears;
  final List<String> qualifications;
  final Price price;
  final List<AvailableTime> availableTimes;
  final List<String> languages;
  final CounselingMethod preferredMethod;
  final bool isOnline;
  final int consultationCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Counselor({
    required this.id,
    required this.userId,
    required this.name,
    this.profileImageUrl,
    required this.title,
    required this.introduction,
    required this.rating,
    required this.reviewCount,
    required this.specialties,
    required this.experienceYears,
    required this.qualifications,
    required this.price,
    required this.availableTimes,
    required this.languages,
    required this.preferredMethod,
    this.isOnline = false,
    this.consultationCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // === 기존 JSON 호환성 (API 연동용) ===
  factory Counselor.fromJson(Map<String, dynamic> json) {
    return Counselor(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      title: json['title'] as String,
      introduction: json['introduction'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      specialties: List<String>.from(json['specialties'] as List),
      experienceYears: json['experienceYears'] as int,
      qualifications: List<String>.from(json['qualifications'] as List),
      price: Price.fromJson(json['price'] as Map<String, dynamic>),
      availableTimes:
          (json['availableTimes'] as List)
              .map(
                (item) => AvailableTime.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      languages: List<String>.from(json['languages'] as List),
      preferredMethod: CounselingMethod.values.firstWhere(
        (e) => e.toString() == 'CounselingMethod.${json['preferredMethod']}',
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'title': title,
      'introduction': introduction,
      'rating': rating,
      'reviewCount': reviewCount,
      'experienceYears': experienceYears,
      'qualifications': qualifications,
      'price': price.toJson(),
      'availableTimes': availableTimes.map((time) => time.toJson()).toList(),
      'languages': languages,
      'preferredMethod': preferredMethod.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // === 🔥 Firebase Firestore 호환 메서드들 ===
  factory Counselor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (data == null) {
      throw Exception('상담사 데이터가 없습니다: ${doc.id}');
    }
    return Counselor.fromFirestoreData(data, doc.id);
  }

  factory Counselor.fromFirestoreData(Map<String, dynamic> data, String docId) {
    try {
      return Counselor(
        id: docId,
        userId: data['userId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        profileImageUrl: data['profileImageUrl'] as String?,
        title: data['title'] as String? ?? '',
        introduction: data['introduction'] as String? ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: data['reviewCount'] as int? ?? 0,
        specialties: List<String>.from(data['specialties'] as List? ?? []),
        experienceYears: data['experienceYears'] as int? ?? 0,
        qualifications: List<String>.from(
          data['qualifications'] as List? ?? [],
        ),
        price:
            data['price'] != null
                ? Price.fromFirestoreData(data['price'] as Map<String, dynamic>)
                : const Price(consultationFee: 0),
        availableTimes:
            (data['availableTimes'] as List? ?? [])
                .map(
                  (item) => AvailableTime.fromFirestoreData(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList(),
        languages: List<String>.from(data['languages'] as List? ?? ['한국어']),
        preferredMethod: CounselingMethod.values.firstWhere(
          (e) => e.toString() == 'CounselingMethod.${data['preferredMethod']}',
        ),
        isOnline: data['isOnline'] ?? false,
        consultationCount: data['consultationCount'] as int? ?? 0,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint('상담사 데이터 파싱 오류: $e\n$stack');
      throw Exception('상담사 데이터 파싱 오류: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'title': title,
      'introduction': introduction,
      'rating': rating,
      'reviewCount': reviewCount,
      'experienceYears': experienceYears,
      'qualifications': qualifications,
      'price': price.toFirestore(),
      'availableTimes':
          availableTimes.map((time) => time.toFirestore()).toList(),
      'languages': languages,
      'preferredMethod': preferredMethod.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      // 검색용 키워드 생성
      'searchKeywords': _generateSearchKeywords(),
    };
  }

  static DateTime _parseFirestoreTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now();
    }
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[];
    keywords.add(name.toLowerCase());
    keywords.addAll(specialties.map((s) => s.toLowerCase()));
    keywords.addAll(qualifications.map((q) => q.toLowerCase()));
    return keywords;
  }

  // 편의 메서드들
  String get ratingText => rating.toStringAsFixed(1);
  String get experienceText => '$experienceYears년 경력';
  String get consultationText {
    if (consultationCount >= 1000) {
      return '${(consultationCount / 1000).toStringAsFixed(1)}k+ 상담';
    }
    return '$consultationCount+ 상담';
  }

  String get specialtiesText {
    if (specialties.isEmpty) return '';
    if (specialties.length <= 3) {
      return specialties.join(', ');
    }
    return '${specialties.take(3).join(', ')} 외 ${specialties.length - 3}개';
  }

  @override
  String toString() => 'Counselor(id: $id, name: $name, rating: $rating)';
}

// === 가격 정보 (Firebase 호환) ===
class Price {
  final int consultationFee;
  final int? packageFee;
  final int? groupFee;

  const Price({required this.consultationFee, this.packageFee, this.groupFee});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      consultationFee: json['consultationFee'] as int,
      packageFee: json['packageFee'] as int?,
      groupFee: json['groupFee'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultationFee': consultationFee,
      'packageFee': packageFee,
      'groupFee': groupFee,
    };
  }

  factory Price.fromFirestoreData(Map<String, dynamic> data) {
    return Price(
      consultationFee: data['consultationFee'] as int? ?? 0,
      packageFee: data['packageFee'] as int?,
      groupFee: data['groupFee'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'consultationFee': consultationFee,
      'packageFee': packageFee,
      'groupFee': groupFee,
    };
  }

  String get consultationFeeText =>
      '${consultationFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

  @override
  String toString() => consultationFeeText;
}

// === 가능한 시간 (Firebase 호환) ===
class AvailableTime {
  final String day; // e.g., '월', '화'
  final String startTime; // e.g., '09:00'
  final String endTime; // e.g., '18:00'

  AvailableTime({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory AvailableTime.fromMap(Map<String, dynamic> map) {
    return AvailableTime(
      day: map['day'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'day': day, 'startTime': startTime, 'endTime': endTime};
  }

  factory AvailableTime.fromJson(Map<String, dynamic> json) {
    return AvailableTime(
      day: json['day'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'startTime': startTime, 'endTime': endTime};
  }

  factory AvailableTime.fromFirestoreData(Map<String, dynamic> data) {
    return AvailableTime(
      day: data['day'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '09:00',
      endTime: data['endTime'] as String? ?? '18:00',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'day': day, 'startTime': startTime, 'endTime': endTime};
  }

  String get timeText => '$startTime - $endTime';

  @override
  String toString() => '$day $timeText';
}

// === 예약 모델 (Firebase 호환) ===
class Appointment {
  final String id;
  final String counselorId;
  final String userId;
  final DateTime scheduledDate;
  final int durationMinutes;
  final CounselingMethod method;
  final AppointmentStatus status;
  final String? notes;
  final String? meetingLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    required this.id,
    required this.counselorId,
    required this.userId,
    required this.scheduledDate,
    required this.durationMinutes,
    required this.method,
    required this.status,
    this.notes,
    this.meetingLink,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      counselorId: json['counselorId'] as String,
      userId: json['userId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      durationMinutes: json['durationMinutes'] as int,
      method: CounselingMethod.values.firstWhere(
        (e) => e.toString() == 'CounselingMethod.${json['method']}',
      ),
      status: AppointmentStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      meetingLink: json['meetingLink'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'counselorId': counselorId,
      'userId': userId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'method': method.toString().split('.').last,
      'status': status.value,
      'notes': notes,
      'meetingLink': meetingLink,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Appointment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('예약 데이터가 없습니다: ${doc.id}');
    }
    return Appointment.fromFirestoreData(data, doc.id);
  }

  factory Appointment.fromFirestoreData(
    Map<String, dynamic> data,
    String docId,
  ) {
    try {
      return Appointment(
        id: docId,
        counselorId: data['counselorId'] as String? ?? '',
        userId: data['userId'] as String? ?? '',
        scheduledDate: Counselor._parseFirestoreTimestamp(
          data['scheduledDate'],
        ),
        durationMinutes: data['durationMinutes'] as int? ?? 60,
        method: CounselingMethod.values.firstWhere(
          (e) => e.toString() == 'CounselingMethod.${data['method']}',
        ),
        status: AppointmentStatus.fromString(
          data['status'] as String? ?? 'pending',
        ),
        notes: data['notes'] as String?,
        meetingLink: data['meetingLink'] as String?,
        createdAt: Counselor._parseFirestoreTimestamp(data['createdAt']),
        updatedAt: Counselor._parseFirestoreTimestamp(data['updatedAt']),
      );
    } catch (e) {
      throw Exception('예약 데이터 파싱 오류: $e');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'counselorId': counselorId,
      'userId': userId,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'durationMinutes': durationMinutes,
      'method': method.toString().split('.').last,
      'status': status.value,
      'notes': notes,
      'meetingLink': meetingLink,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'scheduledYear': scheduledDate.year,
      'scheduledMonth': scheduledDate.month,
      'scheduledDay': scheduledDate.day,
      'scheduledHour': scheduledDate.hour,
    };
  }

  String get durationText => '${durationMinutes}분';
  String get dateTimeText {
    return '${scheduledDate.month}/${scheduledDate.day} ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'Appointment(id: $id, counselorId: $counselorId, date: $dateTimeText)';
}

// === 상담사 리뷰 (Firebase 호환) ===
class CounselorReview {
  final String id;
  final String counselorId;
  final String userId;
  final String userName;
  final double rating;
  final String content;
  final List<String>? tags;
  final DateTime createdAt;
  final String appointmentId;

  const CounselorReview({
    required this.id,
    required this.counselorId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.content,
    this.tags,
    required this.createdAt,
    required this.appointmentId,
  });

  factory CounselorReview.fromJson(Map<String, dynamic> json) {
    return CounselorReview(
      id: json['id'] as String,
      counselorId: json['counselorId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      rating: (json['rating'] as num).toDouble(),
      content: json['content'] as String,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      appointmentId: json['appointmentId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'counselorId': counselorId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'content': content,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'appointmentId': appointmentId,
    };
  }

  factory CounselorReview.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('리뷰 데이터가 없습니다: ${doc.id}');
    }
    return CounselorReview.fromFirestoreData(data, doc.id);
  }

  factory CounselorReview.fromFirestoreData(
    Map<String, dynamic> data,
    String docId,
  ) {
    return CounselorReview(
      id: docId,
      counselorId: data['counselorId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      rating: (data['rating'] as num).toDouble(),
      content: data['content'] as String,
      tags:
          data['tags'] != null ? List<String>.from(data['tags'] as List) : null,
      createdAt: Counselor._parseFirestoreTimestamp(data['createdAt']),
      appointmentId: data['appointmentId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'counselorId': counselorId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'content': content,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'appointmentId': appointmentId,
    };
  }

  String get ratingText => rating.toStringAsFixed(1);

  @override
  String toString() =>
      'CounselorReview(id: $id, rating: $rating, content: ${content.substring(0, content.length > 20 ? 20 : content.length)})';
}

// === 상담사 등록 요청 모델 ===
class CounselorRequest {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String title;
  final List<String> specialties;
  final String introduction;
  final int experienceYears;
  final List<String> qualifications;
  final Price price;
  final List<AvailableTime> availableTimes;
  final List<String> languages;
  final CounselingMethod preferredMethod;
  final CounselorRequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CounselorRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.title,
    required this.specialties,
    required this.introduction,
    required this.experienceYears,
    required this.qualifications,
    required this.price,
    required this.availableTimes,
    required this.languages,
    required this.preferredMethod,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CounselorRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('상담사 요청 데이터가 없습니다: ${doc.id}');
    }
    return CounselorRequest.fromFirestoreData(data, doc.id);
  }

  factory CounselorRequest.fromFirestoreData(
    Map<String, dynamic> data,
    String docId,
  ) {
    return CounselorRequest(
      id: docId,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userProfileImageUrl: data['userProfileImageUrl'] as String?,
      title: data['title'] as String? ?? '',
      specialties: List<String>.from(data['specialties'] as List? ?? []),
      introduction: data['introduction'] as String? ?? '',
      experienceYears: data['experienceYears'] as int? ?? 0,
      qualifications: List<String>.from(data['qualifications']),
      price: Price.fromJson(data['price'] as Map<String, dynamic>),
      availableTimes:
          (data['availableTimes'] as List)
              .map(
                (time) => AvailableTime.fromMap(time as Map<String, dynamic>),
              )
              .toList(),
      languages: List<String>.from(data['languages']),
      preferredMethod: CounselingMethod.values.firstWhere(
        (e) => e.toString() == 'CounselingMethod.${data['preferredMethod']}',
        orElse: () => CounselingMethod.all,
      ),
      status: CounselorRequestStatus.fromString(
        data['status'] as String? ?? 'pending',
      ),
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: _parseFirestoreTimestamp(data['createdAt']),
      updatedAt: _parseFirestoreTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'title': title,
      'specialties': specialties,
      'introduction': introduction,
      'experienceYears': experienceYears,
      'qualifications': qualifications,
      'price': price.toJson(),
      'availableTimes': availableTimes.map((time) => time.toMap()).toList(),
      'languages': languages,
      'preferredMethod': preferredMethod.name,
      'status': status.value,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CounselorRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? title,
    List<String>? specialties,
    String? introduction,
    int? experienceYears,
    List<String>? qualifications,
    Price? price,
    List<AvailableTime>? availableTimes,
    List<String>? languages,
    CounselingMethod? preferredMethod,
    CounselorRequestStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CounselorRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      title: title ?? this.title,
      specialties: specialties ?? this.specialties,
      introduction: introduction ?? this.introduction,
      experienceYears: experienceYears ?? this.experienceYears,
      qualifications: qualifications ?? this.qualifications,
      price: price ?? this.price,
      availableTimes: availableTimes ?? this.availableTimes,
      languages: languages ?? this.languages,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'CounselorRequest(id: $id, userName: $userName, status: $status)';

  static DateTime _parseFirestoreTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now();
    }
  }
}
