import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/counselor_model.dart';
import '../shared/services/counselor_service.dart';

// === 상담사 필터 Provider ===
final counselorFiltersProvider =
    StateNotifierProvider<CounselorFiltersNotifier, CounselorFilters>((ref) {
      return CounselorFiltersNotifier();
    });

// === 전문 분야 목록 Provider ===
final specialtiesProvider = FutureProvider<List<String>>((ref) async {
  final counselorService = await CounselorService.getInstance();
  return await counselorService.getSpecialties();
});

// === 필터 상태 ===
class CounselorFilters {
  final List<String> selectedSpecialties;
  final CounselingMethod? selectedMethod;
  final double? minRating;
  final int? maxPrice;
  final bool onlineOnly;
  final String sortBy; // rating, price, experience

  const CounselorFilters({
    this.selectedSpecialties = const [],
    this.selectedMethod,
    this.minRating,
    this.maxPrice,
    this.onlineOnly = false,
    this.sortBy = 'rating',
  });

  CounselorFilters copyWith({
    List<String>? selectedSpecialties,
    CounselingMethod? selectedMethod,
    double? minRating,
    int? maxPrice,
    bool? onlineOnly,
    String? sortBy,
  }) {
    return CounselorFilters(
      selectedSpecialties: selectedSpecialties ?? this.selectedSpecialties,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  // === 필터 초기화 ===
  CounselorFilters clear() {
    return const CounselorFilters();
  }

  // === 필터 적용 여부 ===
  bool get hasActiveFilters {
    return selectedSpecialties.isNotEmpty ||
        selectedMethod != null ||
        minRating != null ||
        maxPrice != null ||
        onlineOnly ||
        sortBy != 'rating';
  }

  // === 필터 개수 ===
  int get activeFilterCount {
    int count = 0;
    if (selectedSpecialties.isNotEmpty) count++;
    if (selectedMethod != null) count++;
    if (minRating != null) count++;
    if (maxPrice != null) count++;
    if (onlineOnly) count++;
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounselorFilters &&
        other.selectedSpecialties.length == selectedSpecialties.length &&
        other.selectedSpecialties.every(
          (element) => selectedSpecialties.contains(element),
        ) &&
        other.selectedMethod == selectedMethod &&
        other.minRating == minRating &&
        other.maxPrice == maxPrice &&
        other.onlineOnly == onlineOnly &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      selectedSpecialties,
      selectedMethod,
      minRating,
      maxPrice,
      onlineOnly,
      sortBy,
    );
  }
}

// === 필터 Notifier ===
class CounselorFiltersNotifier extends StateNotifier<CounselorFilters> {
  CounselorFiltersNotifier() : super(const CounselorFilters());

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

  // === 전문 분야 다중 선택 ===
  void setSpecialties(List<String> specialties) {
    state = state.copyWith(selectedSpecialties: specialties);
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

  // === 온라인 전용 토글 ===
  void toggleOnlineOnly() {
    state = state.copyWith(onlineOnly: !state.onlineOnly);
  }

  // === 온라인 전용 설정 ===
  void setOnlineOnly(bool onlineOnly) {
    state = state.copyWith(onlineOnly: onlineOnly);
  }

  // === 정렬 방식 설정 ===
  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  // === 모든 필터 초기화 ===
  void clearAllFilters() {
    state = const CounselorFilters();
  }

  // === 필터 적용 ===
  void applyFilters({
    List<String>? specialties,
    CounselingMethod? method,
    double? minRating,
    int? maxPrice,
    bool? onlineOnly,
    String? sortBy,
  }) {
    state = state.copyWith(
      selectedSpecialties: specialties,
      selectedMethod: method,
      minRating: minRating,
      maxPrice: maxPrice,
      onlineOnly: onlineOnly,
      sortBy: sortBy,
    );
  }

  // === 특정 전문 분야만 선택 ===
  void selectOnlySpecialty(String specialty) {
    state = state.copyWith(selectedSpecialties: [specialty]);
  }

  // === 전문 분야 모두 해제 ===
  void clearSpecialties() {
    state = state.copyWith(selectedSpecialties: []);
  }
}
