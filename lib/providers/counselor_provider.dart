import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/counselor_model.dart';
import '../shared/services/counselor_service.dart';

// === 상담사 목록 Provider ===
final counselorsProvider =
    StateNotifierProvider<CounselorsNotifier, CounselorsState>((ref) {
      return CounselorsNotifier();
    });

// === 특정 상담사 상세 정보 Provider ===
final counselorDetailProvider = StateNotifierProvider.family<
  CounselorDetailNotifier,
  CounselorDetailState,
  String
>((ref, counselorId) {
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

// === 상담사 검색 Provider ===
final counselorSearchProvider =
    StateNotifierProvider<CounselorSearchNotifier, CounselorSearchState>((ref) {
      return CounselorSearchNotifier();
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
        page: 1,
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
        page: state.currentPage + 1,
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
      final reviews = await _counselorService!.getCounselorReviews(
        counselorId,
        page: 1,
      );

      state = state.copyWith(
        reviews: reviews,
        isLoading: false,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
  final List<Counselor> searchResults;
  final bool isSearching;
  final String searchQuery;
  final String? error;

  const CounselorSearchState({
    this.searchResults = const [],
    this.isSearching = false,
    this.searchQuery = '',
    this.error,
  });

  CounselorSearchState copyWith({
    List<Counselor>? searchResults,
    bool? isSearching,
    String? searchQuery,
    String? error,
  }) {
    return CounselorSearchState(
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

// === 상담사 검색 Notifier ===
class CounselorSearchNotifier extends StateNotifier<CounselorSearchState> {
  CounselorService? _counselorService;

  CounselorSearchNotifier() : super(const CounselorSearchState()) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _counselorService = await CounselorService.getInstance();
  }

  // === 상담사 검색 ===
  Future<void> searchCounselors(String query) async {
    if (_counselorService == null || query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], searchQuery: query);
      return;
    }

    state = state.copyWith(isSearching: true, searchQuery: query, error: null);

    try {
      final results = await _counselorService!.searchCounselors(query);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  // === 검색 결과 초기화 ===
  void clearSearch() {
    state = const CounselorSearchState();
  }
}
