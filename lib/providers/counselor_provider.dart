import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/counselor_model.dart';
import '../shared/services/counselor_service.dart';
import 'counselor_filters_provider.dart' as filters;

// === 상담사 목록 Provider ===
final counselorsProvider =
    StateNotifierProvider<CounselorsNotifier, CounselorsState>((ref) {
      return CounselorsNotifier();
    });

// === 특정 상담사 상세 정보 Provider ===
final counselorDetailProvider = StateNotifierProvider.autoDispose
    .family<CounselorDetailNotifier, CounselorDetailState, String>((
      ref,
      counselorId,
    ) {
      return CounselorDetailNotifier(counselorId);
    });

// === 상담사 리뷰 Provider ===
final counselorReviewsProvider = StateNotifierProvider.family<
  CounselorReviewsNotifier,
  CounselorReviewsState,
  String
>((ref, counselorId) {
  return CounselorReviewsNotifier(counselorId);
});

// === 전문 분야 목록 Provider ===
final specialtiesProvider = FutureProvider<List<String>>((ref) async {
  final counselorService = await CounselorService.getInstance();
  return await counselorService.getSpecialties();
});

// === 상담사 목록 상태 ===
class CounselorsState {
  final List<Counselor> counselors;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreData;
  final String? error;
  final int currentPage;

  const CounselorsState({
    this.counselors = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreData = true,
    this.error,
    this.currentPage = 1,
  });

  CounselorsState copyWith({
    List<Counselor>? counselors,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreData,
    String? error,
    int? currentPage,
  }) {
    return CounselorsState(
      counselors: counselors ?? this.counselors,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// === 상담사 목록 Notifier ===
class CounselorsNotifier extends StateNotifier<CounselorsState> {
  CounselorService? _counselorService;

  CounselorsNotifier() : super(const CounselorsState()) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _counselorService = await CounselorService.getInstance();
    await loadCounselors();
  }

  // === 상담사 목록 로드 ===
  Future<void> loadCounselors({
    List<String>? specialties,
    CounselingMethod? method,
    double? minRating,
    int? maxPrice,
    bool? onlineOnly,
    String? sortBy,
    bool refresh = false,
  }) async {
    if (_counselorService == null) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMoreData: true,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final counselors = await _counselorService!.getCounselors(
        specialties: specialties,
        method: method,
        minRating: minRating,
        maxPrice: maxPrice,
        onlineOnly: onlineOnly,
        sortBy: sortBy ?? 'rating',
        limit: 20,
      );

      state = state.copyWith(
        counselors: counselors,
        isLoading: false,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 더 많은 상담사 로드 (페이지네이션) ===
  Future<void> loadMoreCounselors({
    List<String>? specialties,
    CounselingMethod? method,
    double? minRating,
    int? maxPrice,
    bool? onlineOnly,
    String? sortBy,
  }) async {
    if (_counselorService == null || state.isLoadingMore || !state.hasMoreData)
      return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final moreCounselors = await _counselorService!.getCounselors(
        specialties: specialties,
        method: method,
        minRating: minRating,
        maxPrice: maxPrice,
        onlineOnly: onlineOnly,
        sortBy: sortBy ?? 'rating',
        limit: 20,
      );

      if (moreCounselors.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMoreData: false);
      } else {
        state = state.copyWith(
          counselors: [...state.counselors, ...moreCounselors],
          isLoadingMore: false,
          currentPage: state.currentPage + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // === 목록 새로고침 ===
  Future<void> refreshCounselors() async {
    await loadCounselors(refresh: true);
  }
}

// === 상담사 상세 정보 상태 ===
class CounselorDetailState {
  final Counselor? counselor;
  final bool isLoading;
  final String? error;
  final bool isFavorite;

  const CounselorDetailState({
    this.counselor,
    this.isLoading = false,
    this.error,
    this.isFavorite = false,
  });

  CounselorDetailState copyWith({
    Counselor? counselor,
    bool? isLoading,
    String? error,
    bool? isFavorite,
  }) {
    return CounselorDetailState(
      counselor: counselor ?? this.counselor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// === 상담사 상세 정보 Notifier ===
class CounselorDetailNotifier extends StateNotifier<CounselorDetailState> {
  final String counselorId;
  CounselorService? _counselorService;

  CounselorDetailNotifier(this.counselorId)
    : super(const CounselorDetailState()) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _counselorService = await CounselorService.getInstance();
    await loadCounselorDetail();
  }

  // === 상담사 상세 정보 로드 ===
  Future<void> loadCounselorDetail() async {
    if (_counselorService == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final counselor = await _counselorService!.getCounselorDetail(
        counselorId,
      );
      state = state.copyWith(counselor: counselor, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 즐겨찾기 토글 ===
  void toggleFavorite() {
    state = state.copyWith(isFavorite: !state.isFavorite);
    // TODO: 서버에 즐겨찾기 상태 저장
  }
}

// === 상담사 리뷰 상태 ===
class CounselorReviewsState {
  final List<CounselorReview> reviews;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreData;
  final String? error;
  final int currentPage;

  const CounselorReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreData = true,
    this.error,
    this.currentPage = 1,
  });

  CounselorReviewsState copyWith({
    List<CounselorReview>? reviews,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreData,
    String? error,
    int? currentPage,
  }) {
    return CounselorReviewsState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// === 상담사 리뷰 Notifier ===
class CounselorReviewsNotifier extends StateNotifier<CounselorReviewsState> {
  final String counselorId;
  CounselorService? _counselorService;

  CounselorReviewsNotifier(this.counselorId)
    : super(const CounselorReviewsState()) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _counselorService = await CounselorService.getInstance();
    await loadReviews();
  }

  // === 리뷰 로드 ===
  Future<void> loadReviews() async {
    if (_counselorService == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final reviews = await _counselorService!.getCounselorReviews(counselorId);
      state = state.copyWith(reviews: reviews, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 리뷰 등록 후 목록 새로고침
  Future<void> refreshReviews() async {
    await loadReviews();
  }

  // === 더 많은 리뷰 로드 ===
  Future<void> loadMoreReviews() async {
    if (_counselorService == null || state.isLoadingMore || !state.hasMoreData)
      return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final moreReviews = await _counselorService!.getCounselorReviews(
        counselorId,
        page: state.currentPage + 1,
      );

      if (moreReviews.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMoreData: false);
      } else {
        state = state.copyWith(
          reviews: [...state.reviews, ...moreReviews],
          isLoadingMore: false,
          currentPage: state.currentPage + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

// === 상담사 검색 상태 ===
class CounselorSearchState {
  final String searchQuery;
  final List<String> selectedSpecialties;
  final CounselingMethod? selectedMethod;
  final double? minRating;
  final int? maxPrice;
  final bool? onlineOnly;
  final List<Counselor> searchResults;
  final bool isSearching;
  final String? searchError;

  const CounselorSearchState({
    this.searchQuery = '',
    this.selectedSpecialties = const [],
    this.selectedMethod,
    this.minRating,
    this.maxPrice,
    this.onlineOnly,
    this.searchResults = const [],
    this.isSearching = false,
    this.searchError,
  });

  CounselorSearchState copyWith({
    String? searchQuery,
    List<String>? selectedSpecialties,
    CounselingMethod? selectedMethod,
    double? minRating,
    int? maxPrice,
    bool? onlineOnly,
    List<Counselor>? searchResults,
    bool? isSearching,
    String? searchError,
  }) {
    return CounselorSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecialties: selectedSpecialties ?? this.selectedSpecialties,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchError: searchError,
    );
  }
}

// === 상담사 검색 Notifier ===
class CounselorSearchNotifier extends StateNotifier<CounselorSearchState> {
  CounselorService? _service;
  Timer? _searchTimer;

  CounselorSearchNotifier() : super(const CounselorSearchState()) {
    _initializeService();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      _service = await CounselorService.getInstance();
      debugPrint('✅ CounselorSearchNotifier 초기화 완료');
    } catch (e) {
      debugPrint('❌ CounselorSearchNotifier 초기화 실패: $e');
      state = state.copyWith(searchError: '검색 서비스 초기화 실패: $e');
    }
  }

  // === 검색 실행 ===
  void performSearch(String query) {
    state = state.copyWith(searchQuery: query, searchError: null);
    _scheduleSearch();
  }

  // === 전문 분야 토글 ===
  void toggleSpecialty(String specialty) {
    final currentSpecialties = List<String>.from(state.selectedSpecialties);
    if (currentSpecialties.contains(specialty)) {
      currentSpecialties.remove(specialty);
    } else {
      currentSpecialties.add(specialty);
    }
    state = state.copyWith(selectedSpecialties: currentSpecialties);
  }

  // === 상담 방식 설정 ===
  void setMethod(CounselingMethod? method) {
    state = state.copyWith(selectedMethod: method);
  }

  // === 최소 평점 설정 ===
  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating);
  }

  // === 최대 가격 설정 ===
  void setMaxPrice(int? price) {
    state = state.copyWith(maxPrice: price);
  }

  // === 온라인 전용 설정 ===
  void setOnlineOnly(bool? onlineOnly) {
    state = state.copyWith(onlineOnly: onlineOnly);
  }

  // === 필터 초기화 ===
  void clearFilters() {
    state = state.copyWith(
      selectedSpecialties: [],
      selectedMethod: null,
      minRating: null,
      maxPrice: null,
      onlineOnly: null,
    );
  }

  // === 검색 초기화 ===
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      searchError: null,
    );
  }

  // === 검색 스케줄링 (디바운싱) ===
  void _scheduleSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  // === 실제 검색 실행 ===
  Future<void> _performSearch() async {
    if (_service == null) return;

    if (state.searchQuery.isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, searchError: null);

    try {
      final results = await _service!.searchCounselors(state.searchQuery);
      state = state.copyWith(searchResults: results, isSearching: false);
      debugPrint('🔍 검색 완료: ${results.length}명');
    } catch (e) {
      debugPrint('❌ 검색 오류: $e');
      state = state.copyWith(
        isSearching: false,
        searchError: '검색 중 오류가 발생했습니다: $e',
      );
    }
  }
}

class CounselorState {
  final List<Counselor> counselors;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final String? lastDocumentId;
  final int pageSize;

  const CounselorState({
    this.counselors = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.lastDocumentId,
    this.pageSize = 10,
  });

  CounselorState copyWith({
    List<Counselor>? counselors,
    bool? isLoading,
    String? error,
    bool? hasMore,
    String? lastDocumentId,
    int? pageSize,
  }) {
    return CounselorState(
      counselors: counselors ?? this.counselors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class CounselorNotifier extends StateNotifier<CounselorState> {
  final CounselorService _service;
  bool _isLoadingMore = false;

  CounselorNotifier(this._service) : super(const CounselorState());

  Future<void> loadCounselors({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        counselors: [],
        isLoading: true,
        error: null,
        hasMore: true,
        lastDocumentId: null,
      );
    } else if (state.isLoading || !state.hasMore) {
      return;
    }

    try {
      final counselors = await _service.getCounselors();
      final hasMore = counselors.length == state.pageSize;
      final lastId = hasMore ? counselors.last.id : null;

      state = state.copyWith(
        counselors: refresh ? counselors : [...state.counselors, ...counselors],
        isLoading: false,
        hasMore: hasMore,
        lastDocumentId: lastId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '상담사 목록을 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasMore) return;

    _isLoadingMore = true;
    await loadCounselors();
    _isLoadingMore = false;
  }

  Future<void> refresh() async {
    await loadCounselors(refresh: true);
  }

  Future<bool> updateCounselor(Counselor counselor) async {
    try {
      await _service.updateCounselor(counselor);
      await loadCounselors(refresh: true); // 목록 새로고침
      return true;
    } catch (e) {
      state = state.copyWith(error: '상담사 정보 수정 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  Future<bool> deleteCounselor(String id) async {
    try {
      await _service.deleteCounselor(id);
      await loadCounselors(refresh: true); // 목록 새로고침
      return true;
    } catch (e) {
      state = state.copyWith(error: '상담사 삭제 중 오류가 발생했습니다: $e');
      return false;
    }
  }
}

final counselorServiceProvider = Provider<CounselorService>((ref) {
  return CounselorService();
});

final counselorProvider =
    StateNotifierProvider<CounselorNotifier, CounselorState>((ref) {
      final service = ref.watch(counselorServiceProvider);
      return CounselorNotifier(service);
    });

// === 필터링된 상담사 목록 Provider ===
final filteredCounselorsProvider = Provider<List<Counselor>>((ref) {
  final counselorsState = ref.watch(counselorsProvider);
  final filtersState = ref.watch(filters.counselorFiltersProvider);

  if (counselorsState.counselors.isEmpty) {
    return [];
  }

  // 필터링 로직
  List<Counselor> filtered = List.from(counselorsState.counselors);

  // 검색어 필터
  final searchQuery = ref.watch(counselorSearchQueryProvider);
  if (searchQuery.isNotEmpty) {
    filtered =
        filtered.where((c) {
          return c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              c.introduction.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              c.specialties.any(
                (specialty) =>
                    specialty.toLowerCase().contains(searchQuery.toLowerCase()),
              );
        }).toList();
  }

  // 전문 분야 필터
  if (filtersState.selectedSpecialties.isNotEmpty) {
    filtered =
        filtered.where((c) {
          return filtersState.selectedSpecialties.any(
            (selectedSpecialty) => c.specialties.contains(selectedSpecialty),
          );
        }).toList();
  }

  // 상담 방식 필터
  if (filtersState.selectedMethod != null) {
    filtered =
        filtered.where((c) {
          return c.preferredMethod == filtersState.selectedMethod;
        }).toList();
  }

  // 최소 평점 필터
  if (filtersState.minRating != null) {
    filtered =
        filtered.where((c) {
          return c.rating >= filtersState.minRating!;
        }).toList();
  }

  // 최대 가격 필터
  if (filtersState.maxPrice != null) {
    filtered =
        filtered.where((c) {
          return c.price.consultationFee <= filtersState.maxPrice!;
        }).toList();
  }

  // 온라인 전용 필터
  if (filtersState.onlineOnly) {
    filtered =
        filtered.where((c) {
          return c.isOnline;
        }).toList();
  }

  // 정렬 로직
  switch (filtersState.sortBy) {
    case 'rating':
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case 'price':
      filtered.sort(
        (a, b) => a.price.consultationFee.compareTo(b.price.consultationFee),
      );
      break;
    case 'experience':
      filtered.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
      break;
    case 'name':
      filtered.sort((a, b) => a.name.compareTo(b.name));
      break;
    default:
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
  }

  return filtered;
});

// === 검색어 Provider ===
final counselorSearchQueryProvider = StateProvider<String>((ref) => '');
