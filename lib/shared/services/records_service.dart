import 'dart:io';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/token_manager.dart';
import '../models/record_model.dart';

class RecordsService {
  static RecordsService? _instance;
  late ApiClient _apiClient;
  late TokenManager _tokenManager;

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
    _apiClient = await ApiClient.getInstance();
    _tokenManager = await TokenManager.getInstance();
  }

  // === 상담 기록 목록 조회 ===
  Future<List<CounselingRecord>> getRecords({
    RecordType? type,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type != RecordType.all) {
        queryParams['type'] = type.value;
      }
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiClient.get<List<dynamic>>(
        '/records', // API 엔드포인트
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        return response.data!
            .map(
              (item) => CounselingRecord.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      // Mock 데이터 반환
      return _getMockRecords();
    } catch (e) {
      print('기록 목록 조회 오류: $e');
      return _getMockRecords();
    }
  }

  // === 상담 기록 상세 조회 ===
  Future<CounselingRecord?> getRecord(String recordId) async {
    try {
      final response = await _apiClient.get<CounselingRecord>(
        '/records/$recordId', // API 엔드포인트
        fromJson: CounselingRecord.fromJson,
      );

      if (response.success) {
        return response.data;
      }

      // Mock 데이터에서 찾기
      final mockRecords = _getMockRecords();
      return mockRecords.firstWhere(
        (record) => record.id == recordId,
        orElse: () => mockRecords.first,
      );
    } catch (e) {
      print('기록 상세 조회 오류: $e');
      return null;
    }
  }

  // === 새 상담 기록 생성 ===
  Future<CounselingRecord?> createRecord(CreateRecordRequest request) async {
    try {
      final response = await _apiClient.post<CounselingRecord>(
        '/records', // API 엔드포인트
        data: request.toJson(),
        fromJson: CounselingRecord.fromJson,
      );

      if (response.success) {
        return response.data;
      }

      // Mock 데이터 생성
      return _createMockRecord(request);
    } catch (e) {
      print('기록 생성 오류: $e');
      return _createMockRecord(request);
    }
  }

  // === 상담 기록 수정 ===
  Future<CounselingRecord?> updateRecord(
    String recordId,
    UpdateRecordRequest request,
  ) async {
    try {
      final response = await _apiClient.patch<CounselingRecord>(
        '/records/$recordId', // API 엔드포인트
        data: request.toJson(),
        fromJson: CounselingRecord.fromJson,
      );

      return response.success ? response.data : null;
    } catch (e) {
      print('기록 수정 오류: $e');
      return null;
    }
  }

  // === 상담 기록 삭제 ===
  Future<bool> deleteRecord(String recordId) async {
    try {
      final response = await _apiClient.delete(
        '/records/$recordId', // API 엔드포인트
      );

      return response.success;
    } catch (e) {
      print('기록 삭제 오류: $e');
      return false;
    }
  }

  // === 첨부파일 업로드 ===
  Future<RecordAttachment?> uploadAttachment(String recordId, File file) async {
    try {
      final response = await _apiClient.uploadFile<RecordAttachment>(
        '/records/$recordId/attachments', // API 엔드포인트
        file.path,
        fieldName: 'attachment',
        fromJson: RecordAttachment.fromJson,
      );

      return response.success ? response.data : null;
    } catch (e) {
      print('첨부파일 업로드 오류: $e');
      return null;
    }
  }

  // === 첨부파일 삭제 ===
  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      final response = await _apiClient.delete(
        '/attachments/$attachmentId', // API 엔드포인트
      );

      return response.success;
    } catch (e) {
      print('첨부파일 삭제 오류: $e');
      return false;
    }
  }

  // === 기록 통계 조회 ===
  Future<RecordStats?> getRecordStats() async {
    try {
      final response = await _apiClient.get<RecordStats>(
        '/records/stats', // API 엔드포인트
        fromJson: RecordStats.fromJson,
      );

      if (response.success) {
        return response.data;
      }

      // Mock 통계 데이터
      return _getMockStats();
    } catch (e) {
      print('기록 통계 조회 오류: $e');
      return _getMockStats();
    }
  }

  // === Mock 데이터 메서드들 ===

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
• 경기 전 긴장과 불안은 자연스러운 반응
• 호흡법과 시각화 기법 학습
• 긍정적 자기 대화의 중요성

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
        tags: ['경기불안', '호흡법', '시각화'],
        attachments: [],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      CounselingRecord(
        id: 'record_2',
        userId: 'user_123',
        type: RecordType.counselor,
        title: '김상담님과의 상담 - 팀 내 갈등',
        summary: '팀 동료와의 갈등으로 인해 스트레스를 받고 있습니다.',
        content: '''김상담님과 함께 팀 내 갈등 상황에 대해 깊이 있게 대화했습니다.

상황 분석:
• 의사소통 방식의 차이가 주된 원인
• 서로의 입장을 이해하지 못함
• 경쟁 의식이 갈등을 심화시킴

해결 방안:
1. 먼저 대화 시도하기
2. 상대방 입장에서 생각해보기
3. 공통 목표(팀 승리) 인식하기

상담사 조언:
"갈등은 성장의 기회가 될 수 있습니다. 중요한 것은 문제를 회피하지 않고 건설적으로 해결하는 것입니다."

다음 주까지 실천할 것:
• 해당 동료와 개인적인 대화 시간 갖기
• 감정적 반응 대신 객관적 의견 표현하기''',
        counselorId: 'counselor_1',
        counselorName: '김상담',
        sessionDate: now.subtract(const Duration(days: 7)),
        durationMinutes: 60,
        rating: 5.0,
        feedback: '정말 도움이 많이 되었습니다. 구체적인 해결책을 제시해주셔서 감사해요.',
        tags: ['팀갈등', '의사소통', '대인관계'],
        attachments: [],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      CounselingRecord(
        id: 'record_3',
        userId: 'user_123',
        type: RecordType.ai,
        title: 'AI 상담 - 슬럼프 극복',
        summary: '최근 기록이 나오지 않아서 자신감이 떨어졌습니다.',
        content: '''슬럼프 상황에 대해 AI와 상담했습니다.

현재 상황:
• 개인 기록 정체
• 자신감 하락
• 훈련 의욕 감소

AI 분석:
모든 선수가 겪는 자연스러운 과정이며, 이를 통해 더 강해질 수 있다고 조언.

제안된 방법:
1. 목표를 작게 세분화하기
2. 과거 성공 경험 되돌아보기
3. 기본기 점검 및 강화
4. 충분한 휴식과 회복

실천 계획:
• 이번 주는 기본기 훈련에 집중
• 매일 작은 성취 기록하기
• 수면과 영양 관리 철저히''',
        sessionDate: now.subtract(const Duration(days: 14)),
        durationMinutes: 35,
        rating: 4.0,
        feedback: '위로가 되었고, 실용적인 조언을 얻었어요.',
        tags: ['슬럼프', '자신감', '목표설정'],
        attachments: [],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 14)),
      ),
      CounselingRecord(
        id: 'record_4',
        userId: 'user_123',
        type: RecordType.selfCheck,
        title: '자가진단 - 스트레스 수준 검사',
        summary: '최근 스트레스 수준과 심리 상태를 점검했습니다.',
        content: '''스트레스 수준 자가진단 결과

총점: 65/100 (중간 수준)

세부 영역:
• 신체적 스트레스: 55점
• 정서적 스트레스: 70점  
• 인지적 스트레스: 60점
• 행동적 스트레스: 65점

주요 스트레스 요인:
1. 경기 성과에 대한 압박감
2. 팀 내 경쟁 상황
3. 부상에 대한 우려

권장 사항:
• 정기적인 이완 훈련
• 전문가 상담 고려
• 충분한 수면과 휴식''',
        sessionDate: now.subtract(const Duration(days: 21)),
        durationMinutes: 20,
        rating: null,
        feedback: '현재 상태를 객관적으로 파악할 수 있어서 좋았어요.',
        tags: ['자가진단', '스트레스', '심리상태'],
        attachments: [],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 21)),
        updatedAt: now.subtract(const Duration(days: 21)),
      ),
    ];
  }

  CounselingRecord _createMockRecord(CreateRecordRequest request) {
    final now = DateTime.now();

    return CounselingRecord(
      id: 'record_${now.millisecondsSinceEpoch}',
      userId: 'user_123',
      type: request.type,
      title: request.title,
      summary: request.summary,
      content: request.content,
      counselorId: request.counselorId,
      counselorName: request.counselorId != null ? '상담사' : null,
      sessionDate: request.sessionDate,
      durationMinutes: request.durationMinutes,
      rating: request.rating,
      feedback: request.feedback,
      tags: request.tags,
      attachments: [],
      status: RecordStatus.completed,
      createdAt: now,
      updatedAt: now,
    );
  }

  RecordStats _getMockStats() {
    return const RecordStats(
      totalRecords: 12,
      aiRecords: 7,
      counselorRecords: 3,
      groupRecords: 1,
      selfCheckRecords: 1,
      averageRating: 4.3,
      totalDurationMinutes: 540, // 9시간
      lastSessionDate: null,
    );
  }
}
