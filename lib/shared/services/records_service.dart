import 'package:flutter/foundation.dart';
import '../models/record_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordsService {
  static RecordsService? _instance;

  // 싱글톤 패턴
  RecordsService._();

  static Future<RecordsService> getInstance() async {
    if (_instance == null) {
      _instance = RecordsService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    // 초기화 로직
    if (kDebugMode) {
      debugPrint('RecordsService 초기화됨');
    }
  }

  // === 기록 목록 조회 ===
  Future<List<CounselingRecord>> getRecords({RecordType? type}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');
      final firestore = await FirestoreService.getInstance();
      final querySnapshot =
          await firestore.recordsCollection
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      List<CounselingRecord> records =
          querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            // Firestore의 Timestamp -> String 변환
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            if (data['updatedAt'] is Timestamp) {
              data['updatedAt'] =
                  (data['updatedAt'] as Timestamp).toDate().toIso8601String();
            }
            if (data['sessionDate'] is Timestamp) {
              data['sessionDate'] =
                  (data['sessionDate'] as Timestamp).toDate().toIso8601String();
            }
            return CounselingRecord.fromJson(data);
          }).toList();

      if (type != null && type != RecordType.all) {
        records = records.where((record) => record.type == type).toList();
      }
      return records;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('기록 목록 조회 오류: $e');
      }
      rethrow;
    }
  }

  // === 단일 기록 조회 ===
  Future<CounselingRecord?> getRecord(String recordId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockRecords = _getMockRecords();

      try {
        return mockRecords.firstWhere((record) => record.id == recordId);
      } catch (e) {
        return null; // 찾을 수 없음
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('기록 조회 오류: $e');
      }
      rethrow;
    }
  }

  // === 새 기록 생성 ===
  Future<CounselingRecord?> createRecord(CreateRecordRequest request) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      final newRecord = CounselingRecord(
        id: 'record_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_123', // 현재 사용자 ID
        type: request.type,
        title: request.title,
        summary: request.summary,
        content: request.content ?? '',
        counselorId: request.counselorId,
        counselorName: request.counselorId != null ? '김상담' : null,
        sessionDate: request.sessionDate,
        durationMinutes: request.durationMinutes,
        rating: request.rating,
        feedback: request.feedback,
        tags: request.tags,
        status: RecordStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return newRecord;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('기록 생성 오류: $e');
      }
      rethrow;
    }
  }

  // === 기록 업데이트 ===
  Future<CounselingRecord?> updateRecord(
    String recordId,
    UpdateRecordRequest request,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));

      final existingRecord = await getRecord(recordId);
      if (existingRecord == null) return null;

      final updatedRecord = CounselingRecord(
        id: existingRecord.id,
        userId: existingRecord.userId,
        type: existingRecord.type,
        title: request.title ?? existingRecord.title,
        summary: request.summary ?? existingRecord.summary,
        content: request.content ?? existingRecord.content,
        counselorId: existingRecord.counselorId,
        counselorName: existingRecord.counselorName,
        sessionDate: existingRecord.sessionDate,
        durationMinutes: existingRecord.durationMinutes,
        rating: request.rating ?? existingRecord.rating,
        feedback: request.feedback ?? existingRecord.feedback,
        tags: request.tags ?? existingRecord.tags,
        status: request.status ?? existingRecord.status,
        createdAt: existingRecord.createdAt,
        updatedAt: DateTime.now(),
      );

      return updatedRecord;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('기록 업데이트 오류: $e');
      }
      rethrow;
    }
  }

  // === 기록 삭제 ===
  Future<bool> deleteRecord(String recordId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock에서는 항상 성공으로 처리
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('기록 삭제 오류: $e');
      }
      return false;
    }
  }

  // === 기록 통계 조회 ===
  Future<RecordStats> getRecordStats() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final records = await getRecords();

      return RecordStats(
        totalRecords: records.length,
        aiRecords: records.where((r) => r.type == RecordType.ai).length,
        counselorRecords:
            records.where((r) => r.type == RecordType.counselor).length,
        groupRecords: records.where((r) => r.type == RecordType.group).length,
        selfCheckRecords:
            records.where((r) => r.type == RecordType.selfCheck).length,
        averageRating:
            records.where((r) => r.rating != null).isEmpty
                ? 0.0
                : records
                        .where((r) => r.rating != null)
                        .map((r) => r.rating!)
                        .reduce((a, b) => a + b) /
                    records.where((r) => r.rating != null).length,
        totalDurationMinutes: records
            .map((r) => r.durationMinutes)
            .reduce((a, b) => a + b),
        lastSessionDate:
            records.isNotEmpty
                ? records
                    .map((r) => r.sessionDate)
                    .reduce((a, b) => a.isAfter(b) ? a : b)
                : null,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('통계 조회 오류: $e');
      }
      rethrow;
    }
  }

  // === Mock 데이터 생성 ===
  List<CounselingRecord> _getMockRecords() {
    final now = DateTime.now();

    return [
      CounselingRecord(
        id: 'record_1',
        userId: 'user_123',
        type: RecordType.ai,
        title: 'AI 상담 - 경기 전 불안감',
        summary: '내일 중요한 경기가 있어서 너무 긴장되고 불안해요. 실수할까봐 걱정이 많습니다.',
        content: '''오늘 AI 상담을 통해 경기 전 불안감에 대해 이야기했습니다.

주요 내용:
- 경기 전 긴장과 불안은 자연스러운 반응
- 호흡법과 시각화 기법 학습
- 긍정적 자기 대화의 중요성

다음 실천 사항:
1. 경기 1시간 전 호흡 명상 10분
2. 성공적인 경기 장면 시각화
3. "나는 충분히 준비했다" 반복하기

느낀 점:
불안감이 완전히 사라지지는 않았지만, 이를 관리할 수 있는 구체적인 방법을 배웠습니다.''',
        sessionDate: now.subtract(const Duration(days: 2)),
        durationMinutes: 45,
        rating: 4.5,
        feedback: '구체적인 방법을 알려줘서 도움이 되었어요.',
        tags: ['불안', '경기', '호흡법', '시각화'],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      CounselingRecord(
        id: 'record_2',
        userId: 'user_123',
        type: RecordType.counselor,
        title: '전문상담 - 번아웃 증후군',
        summary: '최근 운동에 대한 의욕이 사라지고 모든 것이 귀찮아요. 계속 이럴까봐 걱정됩니다.',
        content: '''전문 상담사와 번아웃 증후군에 대해 상담했습니다.

상담 내용:
- 번아웃의 원인과 증상 파악
- 개인적인 요인과 환경적 요인 분석
- 회복을 위한 단계적 계획 수립

상담사 조언:
- 완벽주의 성향 조절하기
- 적절한 휴식과 회복 시간 갖기
- 작은 목표부터 다시 시작하기

다음 계획:
1. 일주일 동안 완전한 휴식
2. 가벼운 산책부터 시작
3. 2주 후 재상담 예약''',
        counselorId: 'counselor_123',
        counselorName: '이지은 상담사',
        sessionDate: now.subtract(const Duration(days: 7)),
        durationMinutes: 60,
        rating: 5.0,
        feedback: '정말 도움이 되었습니다. 마음이 많이 편해졌어요.',
        tags: ['번아웃', '의욕상실', '회복', '휴식'],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      CounselingRecord(
        id: 'record_3',
        userId: 'user_123',
        type: RecordType.group,
        title: '그룹상담 - 팀워크 개선',
        summary: '팀 내 갈등과 소통 문제를 해결하기 위한 그룹 상담에 참여했습니다.',
        content: '''팀 전체가 참여한 그룹 상담 세션이었습니다.

참여자: 팀원 6명 + 상담사 1명

주요 활동:
- 각자의 관점 공유하기
- 갈등 상황 롤플레이
- 효과적인 소통 방법 학습
- 팀 규칙 함께 만들기

결과:
- 서로에 대한 이해도 증가
- 소통 방식 개선 약속
- 정기적인 팀 미팅 계획

개인적 소감:
다른 팀원들도 비슷한 고민을 하고 있다는 것을 알게 되어 위안이 되었습니다.''',
        counselorId: 'counselor_456',
        counselorName: '박철수 상담사',
        sessionDate: now.subtract(const Duration(days: 14)),
        durationMinutes: 90,
        rating: 4.0,
        feedback: '그룹으로 하니까 더 많은 것을 배울 수 있었어요.',
        tags: ['팀워크', '소통', '갈등해결', '그룹'],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
      CounselingRecord(
        id: 'record_4',
        userId: 'user_123',
        type: RecordType.selfCheck,
        title: '자가진단 - 스트레스 수준 검사',
        summary: '최근 스트레스 수준을 체크해보기 위해 자가진단을 실시했습니다.',
        content: '''스트레스 자가진단 결과입니다.

검사 항목:
- 신체적 스트레스 증상
- 정신적 스트레스 수준
- 스트레스 대처 방식
- 일상생활 영향도

결과 분석:
- 전체 점수: 65/100 (중간 수준)
- 신체 증상: 높음
- 정신적 스트레스: 중간
- 대처 능력: 보통

권장사항:
1. 규칙적인 운동으로 신체 증상 완화
2. 명상이나 요가로 정신적 안정 도모
3. 충분한 수면 시간 확보
4. 전문상담 고려해보기''',
        sessionDate: now.subtract(const Duration(days: 21)),
        durationMinutes: 30,
        rating: 3.5,
        feedback: '객관적으로 내 상태를 알 수 있어서 좋았어요.',
        tags: ['자가진단', '스트레스', '검사', '평가'],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 21)),
        updatedAt: now.subtract(const Duration(days: 21)),
      ),
    ];
  }
}
