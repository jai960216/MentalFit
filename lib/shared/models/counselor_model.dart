class Counselor {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String title; // 직책/자격
  final List<String> specialties; // 전문 분야
  final String introduction; // 소개
  final double rating; // 평점 (1-5)
  final int reviewCount; // 리뷰 수
  final int experienceYears; // 경력 연수
  final List<String> qualifications; // 자격증/학력
  final bool isOnline; // 온라인 상태
  final int consultationCount; // 상담 횟수
  final Price price; // 가격 정보
  final List<AvailableTime> availableTimes; // 가능한 시간
  final List<String> languages; // 사용 언어
  final CounselingMethod preferredMethod; // 선호 상담 방식
  final DateTime createdAt;
  final DateTime updatedAt;

  const Counselor({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.title,
    required this.specialties,
    required this.introduction,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.qualifications,
    required this.isOnline,
    required this.consultationCount,
    required this.price,
    required this.availableTimes,
    required this.languages,
    required this.preferredMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Counselor.fromJson(Map<String, dynamic> json) {
    return Counselor(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      title: json['title'] as String,
      specialties: List<String>.from(json['specialties'] as List),
      introduction: json['introduction'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      experienceYears: json['experienceYears'] as int,
      qualifications: List<String>.from(json['qualifications'] as List),
      isOnline: json['isOnline'] as bool,
      consultationCount: json['consultationCount'] as int,
      price: Price.fromJson(json['price'] as Map<String, dynamic>),
      availableTimes:
          (json['availableTimes'] as List)
              .map(
                (item) => AvailableTime.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      languages: List<String>.from(json['languages'] as List),
      preferredMethod: CounselingMethod.fromString(
        json['preferredMethod'] as String,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'title': title,
      'specialties': specialties,
      'introduction': introduction,
      'rating': rating,
      'reviewCount': reviewCount,
      'experienceYears': experienceYears,
      'qualifications': qualifications,
      'isOnline': isOnline,
      'consultationCount': consultationCount,
      'price': price.toJson(),
      'availableTimes': availableTimes.map((time) => time.toJson()).toList(),
      'languages': languages,
      'preferredMethod': preferredMethod.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Counselor copyWith({
    String? id,
    String? name,
    String? profileImageUrl,
    String? title,
    List<String>? specialties,
    String? introduction,
    double? rating,
    int? reviewCount,
    int? experienceYears,
    List<String>? qualifications,
    bool? isOnline,
    int? consultationCount,
    Price? price,
    List<AvailableTime>? availableTimes,
    List<String>? languages,
    CounselingMethod? preferredMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Counselor(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      title: title ?? this.title,
      specialties: specialties ?? this.specialties,
      introduction: introduction ?? this.introduction,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears ?? this.experienceYears,
      qualifications: qualifications ?? this.qualifications,
      isOnline: isOnline ?? this.isOnline,
      consultationCount: consultationCount ?? this.consultationCount,
      price: price ?? this.price,
      availableTimes: availableTimes ?? this.availableTimes,
      languages: languages ?? this.languages,
      preferredMethod: preferredMethod ?? this.preferredMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 평점 텍스트
  String get ratingText {
    return rating.toStringAsFixed(1);
  }

  // 경력 텍스트
  String get experienceText {
    return '$experienceYears년 경력';
  }

  // 상담 횟수 텍스트
  String get consultationText {
    if (consultationCount >= 1000) {
      return '${(consultationCount / 1000).toStringAsFixed(1)}k+ 상담';
    }
    return '$consultationCount+ 상담';
  }

  // 전문 분야 요약 (최대 3개)
  String get specialtiesText {
    if (specialties.isEmpty) return '';
    if (specialties.length <= 3) {
      return specialties.join(', ');
    }
    return '${specialties.take(3).join(', ')} 외 ${specialties.length - 3}개';
  }

  @override
  String toString() {
    return 'Counselor(id: $id, name: $name, rating: $rating)';
  }
}

// 가격 정보
class Price {
  final int consultationFee; // 1회 상담료
  final int? packagePrice; // 패키지 가격
  final int? packageSessions; // 패키지 회차
  final String currency; // 통화

  const Price({
    required this.consultationFee,
    this.packagePrice,
    this.packageSessions,
    this.currency = 'KRW',
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      consultationFee: json['consultationFee'] as int,
      packagePrice: json['packagePrice'] as int?,
      packageSessions: json['packageSessions'] as int?,
      currency: json['currency'] as String? ?? 'KRW',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultationFee': consultationFee,
      'packagePrice': packagePrice,
      'packageSessions': packageSessions,
      'currency': currency,
    };
  }

  // 상담료 텍스트
  String get consultationFeeText {
    return '${_formatPrice(consultationFee)}원/회';
  }

  // 패키지 가격 텍스트
  String? get packagePriceText {
    if (packagePrice == null || packageSessions == null) return null;
    return '${_formatPrice(packagePrice!)}원/${packageSessions}회';
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      final man = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) {
        return '${man}만';
      } else {
        return '${man}만 ${remainder}';
      }
    }
    return price.toString();
  }
}

// 가능한 시간
class AvailableTime {
  final String dayOfWeek; // 요일 (월,화,수,목,금,토,일)
  final String startTime; // 시작 시간 (HH:mm)
  final String endTime; // 종료 시간 (HH:mm)
  final bool isAvailable; // 가능 여부

  const AvailableTime({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory AvailableTime.fromJson(Map<String, dynamic> json) {
    return AvailableTime(
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isAvailable: json['isAvailable'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }

  // 시간 텍스트
  String get timeText {
    return '$startTime - $endTime';
  }
}

// 상담 방식
enum CounselingMethod {
  faceToFace('face_to_face', '대면'),
  video('video', '화상'),
  voice('voice', '음성'),
  chat('chat', '채팅'),
  all('all', '전체');

  const CounselingMethod(this.value, this.displayName);

  final String value;
  final String displayName;

  static CounselingMethod fromString(String value) {
    return CounselingMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => CounselingMethod.all,
    );
  }

  @override
  String toString() => displayName;
}

// 상담사 리뷰
class CounselorReview {
  final String id;
  final String counselorId;
  final String userId;
  final String userName;
  final double rating;
  final String content;
  final List<String>? tags; // 추천 태그
  final DateTime createdAt;

  const CounselorReview({
    required this.id,
    required this.counselorId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.content,
    this.tags,
    required this.createdAt,
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
    };
  }

  String get ratingText => rating.toStringAsFixed(1);

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inMinutes}분 전';
    }
  }
}

// 예약 정보
class Appointment {
  final String id;
  final String counselorId;
  final String userId;
  final DateTime scheduledDate;
  final int durationMinutes;
  final CounselingMethod method;
  final AppointmentStatus status;
  final String? notes; // 상담 요청 사항
  final String? meetingLink; // 화상 상담 링크
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
      method: CounselingMethod.fromString(json['method'] as String),
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
      'method': method.value,
      'status': status.value,
      'notes': notes,
      'meetingLink': meetingLink,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get durationText => '${durationMinutes}분';

  String get dateTimeText {
    return '${scheduledDate.month}/${scheduledDate.day} ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
  }
}

// 예약 상태
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
