import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/record_model.dart';
import '../shared/services/records_service.dart';

// 기록 목록 상태
class RecordsState {
  final List<CounselingRecord> records;
  final bool isLoading;
  final String? error;

  const RecordsState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  RecordsState copyWith({
    List<CounselingRecord>? records,
    bool? isLoading,
    String? error,
  }) {
    return RecordsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 기록 목록 관리
class RecordsNotifier extends StateNotifier<RecordsState> {
  RecordsNotifier() : super(const RecordsState());

  late RecordsService _recordsService;
  bool _initialized = false;

  Future<void> _initializeService() async {
    if (!_initialized) {
      _recordsService = await RecordsService.getInstance();
      _initialized = true;
    }
  }

  // === 기록 목록 로드 ===
  Future<void> loadRecords({RecordType? type, bool refresh = false}) async {
    if (!refresh && state.records.isNotEmpty) return;

    await _initializeService();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final records = await _recordsService.getRecords(type: type);
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 새 기록 추가 ===
  Future<bool> createRecord(CreateRecordRequest request) async {
    await _initializeService();

    try {
      final newRecord = await _recordsService.createRecord(request);
      if (newRecord != null) {
        final updatedRecords = [newRecord, ...state.records];
        state = state.copyWith(records: updatedRecords);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // === 기록 수정 ===
  Future<bool> updateRecord(
    String recordId,
    UpdateRecordRequest request,
  ) async {
    await _initializeService();

    try {
      final updatedRecord = await _recordsService.updateRecord(
        recordId,
        request,
      );
      if (updatedRecord != null) {
        final updatedRecords =
            state.records.map((record) {
              return record.id == recordId ? updatedRecord : record;
            }).toList();

        state = state.copyWith(records: updatedRecords);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // === 기록 삭제 ===
  Future<bool> deleteRecord(String recordId) async {
    await _initializeService();

    try {
      final success = await _recordsService.deleteRecord(recordId);
      if (success) {
        final updatedRecords =
            state.records.where((record) => record.id != recordId).toList();
        state = state.copyWith(records: updatedRecords);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // === 기록 검색 ===
  List<CounselingRecord> searchRecords(String query) {
    if (query.isEmpty) return state.records;

    return state.records.where((record) {
      return record.title.toLowerCase().contains(query.toLowerCase()) ||
          record.summary.toLowerCase().contains(query.toLowerCase()) ||
          record.tags.any(
            (tag) => tag.toLowerCase().contains(query.toLowerCase()),
          );
    }).toList();
  }

  // === 타입별 기록 필터링 ===
  List<CounselingRecord> getRecordsByType(RecordType type) {
    if (type == RecordType.all) return state.records;
    return state.records.where((record) => record.type == type).toList();
  }

  // === 에러 클리어 ===
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// 기록 상세 상태
class RecordDetailState {
  final CounselingRecord? record;
  final bool isLoading;
  final String? error;

  const RecordDetailState({this.record, this.isLoading = false, this.error});

  RecordDetailState copyWith({
    CounselingRecord? record,
    bool? isLoading,
    String? error,
  }) {
    return RecordDetailState(
      record: record ?? this.record,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 기록 상세 관리
class RecordDetailNotifier extends StateNotifier<RecordDetailState> {
  RecordDetailNotifier() : super(const RecordDetailState());

  late RecordsService _recordsService;
  bool _initialized = false;

  Future<void> _initializeService() async {
    if (!_initialized) {
      _recordsService = await RecordsService.getInstance();
      _initialized = true;
    }
  }

  // === 기록 상세 로드 ===
  Future<void> loadRecord(String recordId) async {
    await _initializeService();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final record = await _recordsService.getRecord(recordId);
      state = state.copyWith(record: record, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 기록 업데이트 ===
  Future<bool> updateRecord(UpdateRecordRequest request) async {
    if (state.record == null) return false;

    await _initializeService();

    try {
      final updatedRecord = await _recordsService.updateRecord(
        state.record!.id,
        request,
      );

      if (updatedRecord != null) {
        state = state.copyWith(record: updatedRecord);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // === 에러 클리어 ===
  void clearError() {
    state = state.copyWith(error: null);
  }

  // === 상태 리셋 ===
  void reset() {
    state = const RecordDetailState();
  }
}

// 기록 통계 상태
class RecordStatsState {
  final RecordStats? stats;
  final bool isLoading;
  final String? error;

  const RecordStatsState({this.stats, this.isLoading = false, this.error});

  RecordStatsState copyWith({
    RecordStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return RecordStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 기록 통계 관리
class RecordStatsNotifier extends StateNotifier<RecordStatsState> {
  RecordStatsNotifier() : super(const RecordStatsState());

  late RecordsService _recordsService;
  bool _initialized = false;

  Future<void> _initializeService() async {
    if (!_initialized) {
      _recordsService = await RecordsService.getInstance();
      _initialized = true;
    }
  }

  // === 통계 로드 ===
  Future<void> loadStats() async {
    await _initializeService();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _recordsService.getRecordStats();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 에러 클리어 ===
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === Provider 정의 ===

// 기록 목록 Provider
final recordsProvider = StateNotifierProvider<RecordsNotifier, RecordsState>((
  ref,
) {
  return RecordsNotifier();
});

// 기록 상세 Provider
final recordDetailProvider = StateNotifierProvider.family<
  RecordDetailNotifier,
  RecordDetailState,
  String
>((ref, recordId) {
  final notifier = RecordDetailNotifier();
  notifier.loadRecord(recordId);
  return notifier;
});

// 기록 통계 Provider
final recordStatsProvider =
    StateNotifierProvider<RecordStatsNotifier, RecordStatsState>((ref) {
      final notifier = RecordStatsNotifier();
      notifier.loadStats();
      return notifier;
    });

// === 편의용 Provider들 ===

// 타입별 기록 필터링 Provider
final recordsByTypeProvider =
    Provider.family<List<CounselingRecord>, RecordType>((ref, type) {
      final recordsState = ref.watch(recordsProvider);

      if (type == RecordType.all) {
        return recordsState.records;
      }

      return recordsState.records
          .where((record) => record.type == type)
          .toList();
    });

// 최근 기록 Provider (최대 5개)
final recentRecordsProvider = Provider<List<CounselingRecord>>((ref) {
  final recordsState = ref.watch(recordsProvider);
  final sortedRecords = [...recordsState.records];
  sortedRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sortedRecords.take(5).toList();
});

// 높은 평점 기록 Provider (4점 이상)
final highRatedRecordsProvider = Provider<List<CounselingRecord>>((ref) {
  final recordsState = ref.watch(recordsProvider);
  return recordsState.records
      .where((record) => record.rating != null && record.rating! >= 4.0)
      .toList();
});

// 즐겨찾기 태그 Provider (가장 많이 사용된 태그)
final popularTagsProvider = Provider<List<String>>((ref) {
  final recordsState = ref.watch(recordsProvider);
  final tagCounts = <String, int>{};

  for (final record in recordsState.records) {
    for (final tag in record.tags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
  }

  final sortedTags =
      tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  return sortedTags.take(10).map((e) => e.key).toList();
});

// 월별 상담 횟수 Provider
final monthlyRecordsProvider = Provider<Map<String, int>>((ref) {
  final recordsState = ref.watch(recordsProvider);
  final monthlyCount = <String, int>{};

  for (final record in recordsState.records) {
    final monthKey =
        '${record.sessionDate.year}-${record.sessionDate.month.toString().padLeft(2, '0')}';
    monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
  }

  return monthlyCount;
});

// 상담사별 만족도 Provider
final counselorRatingsProvider = Provider<Map<String, double>>((ref) {
  final recordsState = ref.watch(recordsProvider);
  final counselorRatings = <String, List<double>>{};

  for (final record in recordsState.records) {
    if (record.counselorName != null && record.rating != null) {
      counselorRatings.putIfAbsent(record.counselorName!, () => []);
      counselorRatings[record.counselorName!]!.add(record.rating!);
    }
  }

  final avgRatings = <String, double>{};
  counselorRatings.forEach((counselor, ratings) {
    avgRatings[counselor] = ratings.reduce((a, b) => a + b) / ratings.length;
  });

  return avgRatings;
});

// 검색 결과 Provider
final searchRecordsProvider = Provider.family<List<CounselingRecord>, String>((
  ref,
  query,
) {
  final recordsState = ref.watch(recordsProvider);

  if (query.isEmpty) return recordsState.records;

  return recordsState.records.where((record) {
    return record.title.toLowerCase().contains(query.toLowerCase()) ||
        record.summary.toLowerCase().contains(query.toLowerCase()) ||
        record.tags.any(
          (tag) => tag.toLowerCase().contains(query.toLowerCase()),
        );
  }).toList();
});

// 기간별 기록 Provider
final recordsByDateRangeProvider =
    Provider.family<List<CounselingRecord>, DateRange>((ref, dateRange) {
      final recordsState = ref.watch(recordsProvider);

      return recordsState.records.where((record) {
        return record.sessionDate.isAfter(
              dateRange.start.subtract(const Duration(days: 1)),
            ) &&
            record.sessionDate.isBefore(
              dateRange.end.add(const Duration(days: 1)),
            );
      }).toList();
    });

// 평점별 기록 Provider
final recordsByRatingProvider = Provider.family<List<CounselingRecord>, double>(
  (ref, minRating) {
    final recordsState = ref.watch(recordsProvider);

    return recordsState.records
        .where((record) => record.rating != null && record.rating! >= minRating)
        .toList();
  },
);

// 상담사별 기록 Provider
final recordsByCounselorProvider =
    Provider.family<List<CounselingRecord>, String>((ref, counselorName) {
      final recordsState = ref.watch(recordsProvider);

      return recordsState.records
          .where((record) => record.counselorName == counselorName)
          .toList();
    });

// 태그별 기록 Provider
final recordsByTagProvider = Provider.family<List<CounselingRecord>, String>((
  ref,
  tag,
) {
  final recordsState = ref.watch(recordsProvider);

  return recordsState.records
      .where((record) => record.tags.contains(tag))
      .toList();
});

// 진행률 계산 Provider (이번 달 목표 대비)
final monthlyProgressProvider = Provider<double>((ref) {
  final recordsState = ref.watch(recordsProvider);
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);
  final nextMonth = DateTime(now.year, now.month + 1);

  final thisMonthRecords =
      recordsState.records.where((record) {
        return record.sessionDate.isAfter(
              thisMonth.subtract(const Duration(days: 1)),
            ) &&
            record.sessionDate.isBefore(nextMonth);
      }).length;

  const monthlyGoal = 4; // 월 4회 목표
  return (thisMonthRecords / monthlyGoal).clamp(0.0, 1.0);
});

// === 헬퍼 클래스들 ===

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  // 이번 주
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return DateRange(start: weekStart, end: weekEnd);
  }

  // 이번 달
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(
      now.year,
      now.month + 1,
    ).subtract(const Duration(days: 1));
    return DateRange(start: monthStart, end: monthEnd);
  }

  // 최근 30일
  factory DateRange.last30Days() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    return DateRange(start: start, end: now);
  }
}
