import 'package:flutter/material.dart';
import '../../core/config/app_colors.dart';

// 상담 기록 모델
class CounselingRecord {
  final String id;
  final String userId;
  final RecordType type;
  final String title;
  final String summary;
  final String? content; // 상세 내용
  final String? counselorId;
  final String? counselorName;
  final DateTime sessionDate;
  final int durationMinutes;
  final double? rating; // 1-5점
  final String? feedback; // 사용자 피드백
  final List<String> tags;
  final List<RecordAttachment> attachments;
  final RecordStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CounselingRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.summary,
    this.content,
    this.counselorId,
    this.counselorName,
    required this.sessionDate,
    required this.durationMinutes,
    this.rating,
    this.feedback,
    this.tags = const [],
    this.attachments = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CounselingRecord.fromJson(Map<String, dynamic> json) {
    return CounselingRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: RecordType.fromString(json['type'] as String),
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String?,
      counselorId: json['counselorId'] as String?,
      counselorName: json['counselorName'] as String?,
      sessionDate: DateTime.parse(json['sessionDate'] as String),
      durationMinutes: json['durationMinutes'] as int,
      rating: (json['rating'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      attachments:
          (json['attachments'] as List? ?? [])
              .map(
                (item) =>
                    RecordAttachment.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      status: RecordStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'title': title,
      'summary': summary,
      'content': content,
      'counselorId': counselorId,
      'counselorName': counselorName,
      'sessionDate': sessionDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'rating': rating,
      'feedback': feedback,
      'tags': tags,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CounselingRecord copyWith({
    String? id,
    String? userId,
    RecordType? type,
    String? title,
    String? summary,
    String? content,
    String? counselorId,
    String? counselorName,
    DateTime? sessionDate,
    int? durationMinutes,
    double? rating,
    String? feedback,
    List<String>? tags,
    List<RecordAttachment>? attachments,
    RecordStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CounselingRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      counselorId: counselorId ?? this.counselorId,
      counselorName: counselorName ?? this.counselorName,
      sessionDate: sessionDate ?? this.sessionDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 날짜 텍스트 (MM/dd HH:mm)
  String get dateText {
    return '${sessionDate.month.toString().padLeft(2, '0')}/${sessionDate.day.toString().padLeft(2, '0')} ${sessionDate.hour.toString().padLeft(2, '0')}:${sessionDate.minute.toString().padLeft(2, '0')}';
  }

  // 상세 날짜 텍스트 (yyyy년 MM월 dd일 HH:mm)
  String get detailDateText {
    return '${sessionDate.year}년 ${sessionDate.month}월 ${sessionDate.day}일 ${sessionDate.hour.toString().padLeft(2, '0')}:${sessionDate.minute.toString().padLeft(2, '0')}';
  }

  // 기간 텍스트
  String get durationText => '${durationMinutes}분';

  // 평점 텍스트
  String get ratingText =>
      rating != null ? '${rating!.toStringAsFixed(1)}점' : '평점 없음';

  @override
  String toString() {
    return 'CounselingRecord(id: $id, title: $title, type: $type)';
  }
}

// 기록 유형
enum RecordType {
  all('all', '전체', Icons.list, AppColors.grey600),
  ai('ai', 'AI 상담', Icons.smart_toy, AppColors.info),
  counselor('counselor', '전문 상담', Icons.person, AppColors.success),
  group('group', '그룹 상담', Icons.group, AppColors.warning),
  selfCheck('self_check', '자가진단', Icons.psychology, AppColors.primary);

  const RecordType(this.value, this.displayName, this.icon, this.color);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  static RecordType fromString(String value) {
    return RecordType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RecordType.ai,
    );
  }

  @override
  String toString() => displayName;
}

// 기록 상태
enum RecordStatus {
  draft('draft', '작성중'),
  completed('completed', '완료'),
  archived('archived', '보관됨');

  const RecordStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static RecordStatus fromString(String value) {
    return RecordStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RecordStatus.completed,
    );
  }

  @override
  String toString() => displayName;
}

// 첨부파일
class RecordAttachment {
  final String id;
  final String recordId;
  final AttachmentType type;
  final String fileName;
  final String fileUrl;
  final int? fileSize; // bytes
  final DateTime uploadedAt;

  const RecordAttachment({
    required this.id,
    required this.recordId,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    required this.uploadedAt,
  });

  factory RecordAttachment.fromJson(Map<String, dynamic> json) {
    return RecordAttachment(
      id: json['id'] as String,
      recordId: json['recordId'] as String,
      type: AttachmentType.fromString(json['type'] as String),
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: json['fileSize'] as int?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordId': recordId,
      'type': type.value,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  // 파일 크기 텍스트
  String get fileSizeText {
    if (fileSize == null) return '';

    final bytes = fileSize!;
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}

// 첨부파일 유형
enum AttachmentType {
  image('image', '이미지', Icons.image),
  audio('audio', '오디오', Icons.audiotrack),
  document('document', '문서', Icons.description),
  video('video', '비디오', Icons.videocam);

  const AttachmentType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final IconData icon;

  static AttachmentType fromString(String value) {
    return AttachmentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AttachmentType.document,
    );
  }

  @override
  String toString() => displayName;
}

// 상담 기록 생성 요청
class CreateRecordRequest {
  final RecordType type;
  final String title;
  final String summary;
  final String? content;
  final String? counselorId;
  final DateTime sessionDate;
  final int durationMinutes;
  final double? rating;
  final String? feedback;
  final List<String> tags;

  const CreateRecordRequest({
    required this.type,
    required this.title,
    required this.summary,
    this.content,
    this.counselorId,
    required this.sessionDate,
    required this.durationMinutes,
    this.rating,
    this.feedback,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'title': title,
      'summary': summary,
      'content': content,
      'counselorId': counselorId,
      'sessionDate': sessionDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'rating': rating,
      'feedback': feedback,
      'tags': tags,
    };
  }
}

// 상담 기록 업데이트 요청
class UpdateRecordRequest {
  final String? title;
  final String? summary;
  final String? content;
  final double? rating;
  final String? feedback;
  final List<String>? tags;
  final RecordStatus? status;

  const UpdateRecordRequest({
    this.title,
    this.summary,
    this.content,
    this.rating,
    this.feedback,
    this.tags,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (title != null) data['title'] = title;
    if (summary != null) data['summary'] = summary;
    if (content != null) data['content'] = content;
    if (rating != null) data['rating'] = rating;
    if (feedback != null) data['feedback'] = feedback;
    if (tags != null) data['tags'] = tags;
    if (status != null) data['status'] = status!.value;

    return data;
  }
}

// 기록 통계
class RecordStats {
  final int totalRecords;
  final int aiRecords;
  final int counselorRecords;
  final int groupRecords;
  final int selfCheckRecords;
  final double averageRating;
  final int totalDurationMinutes;
  final DateTime? lastSessionDate;

  const RecordStats({
    required this.totalRecords,
    required this.aiRecords,
    required this.counselorRecords,
    required this.groupRecords,
    required this.selfCheckRecords,
    required this.averageRating,
    required this.totalDurationMinutes,
    this.lastSessionDate,
  });

  factory RecordStats.fromJson(Map<String, dynamic> json) {
    return RecordStats(
      totalRecords: json['totalRecords'] as int,
      aiRecords: json['aiRecords'] as int,
      counselorRecords: json['counselorRecords'] as int,
      groupRecords: json['groupRecords'] as int,
      selfCheckRecords: json['selfCheckRecords'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      totalDurationMinutes: json['totalDurationMinutes'] as int,
      lastSessionDate:
          json['lastSessionDate'] != null
              ? DateTime.parse(json['lastSessionDate'] as String)
              : null,
    );
  }

  // 총 상담 시간 텍스트
  String get totalDurationText {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  // 평균 평점 텍스트
  String get averageRatingText {
    return averageRating > 0 ? averageRating.toStringAsFixed(1) : '-';
  }
}
