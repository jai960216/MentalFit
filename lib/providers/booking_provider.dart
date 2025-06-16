import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/counselor_model.dart';
import '../shared/services/counselor_service.dart';

// === 🔥 Firebase 연동 Provider들 ===

// === 예약 생성 Provider ===
final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier();
});

// === 예약 가능 시간 Provider (상담사별) ===
final availableSlotsProvider = StateNotifierProvider.family<
  AvailableSlotsNotifier,
  AvailableSlotsState,
  String
>((ref, counselorId) {
  return AvailableSlotsNotifier(counselorId);
});

// === 내 예약 목록 Provider ===
final myAppointmentsProvider =
    StateNotifierProvider<MyAppointmentsNotifier, MyAppointmentsState>((ref) {
      return MyAppointmentsNotifier();
    });

// === 실시간 예약 스트림 Provider ===
final myAppointmentsStreamProvider = StreamProvider<List<Appointment>>((
  ref,
) async* {
  // Firebase 실시간 스트림은 추후 구현 예정
  // 현재는 1분마다 폴링으로 대체
  while (true) {
    try {
      final service = await CounselorService.getInstance();
      final appointments = await service.getMyAppointments();
      yield appointments;
    } catch (e) {
      debugPrint('⚠️ 실시간 예약 스트림 오류: $e');
    }
    await Future.delayed(const Duration(minutes: 1));
  }
});

// === 상태 클래스들 ===

// === 예약 생성 상태 ===
class BookingState {
  final String? selectedCounselorId;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final CounselingMethod? selectedMethod;
  final int durationMinutes;
  final String? notes;
  final bool isCreating;
  final bool isValidating;
  final String? error;
  final String? validationError;
  final Appointment? createdAppointment;

  const BookingState({
    this.selectedCounselorId,
    this.selectedDate,
    this.selectedTime,
    this.selectedMethod,
    this.durationMinutes = 60,
    this.notes,
    this.isCreating = false,
    this.isValidating = false,
    this.error,
    this.validationError,
    this.createdAppointment,
  });

  BookingState copyWith({
    String? selectedCounselorId,
    DateTime? selectedDate,
    DateTime? selectedTime,
    CounselingMethod? selectedMethod,
    int? durationMinutes,
    String? notes,
    bool? isCreating,
    bool? isValidating,
    String? error,
    String? validationError,
    Appointment? createdAppointment,
  }) {
    return BookingState(
      selectedCounselorId: selectedCounselorId ?? this.selectedCounselorId,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      isCreating: isCreating ?? this.isCreating,
      isValidating: isValidating ?? this.isValidating,
      error: error,
      validationError: validationError,
      createdAppointment: createdAppointment ?? this.createdAppointment,
    );
  }

  bool get canBook {
    return selectedCounselorId != null &&
        selectedDate != null &&
        selectedTime != null &&
        selectedMethod != null &&
        !isCreating &&
        !isValidating &&
        validationError == null;
  }

  @override
  String toString() {
    return 'BookingState(selectedCounselorId: $selectedCounselorId, selectedDate: $selectedDate, selectedTime: $selectedTime, selectedMethod: $selectedMethod, durationMinutes: $durationMinutes, notes: $notes, isCreating: $isCreating, isValidating: $isValidating, error: $error, validationError: $validationError)';
  }
}

// === 예약 가능 시간 상태 ===
class AvailableSlotsState {
  final List<DateTime> availableSlots;
  final DateTime selectedDate;
  final bool isLoading;
  final bool isRealTimeUpdating;
  final String? error;
  final DateTime? lastUpdated;

  const AvailableSlotsState({
    this.availableSlots = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.isRealTimeUpdating = false,
    this.error,
    this.lastUpdated,
  });

  AvailableSlotsState copyWith({
    List<DateTime>? availableSlots,
    DateTime? selectedDate,
    bool? isLoading,
    bool? isRealTimeUpdating,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AvailableSlotsState(
      availableSlots: availableSlots ?? this.availableSlots,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      isRealTimeUpdating: isRealTimeUpdating ?? this.isRealTimeUpdating,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get needsUpdate {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inSeconds > 30;
  }
}

// === 내 예약 목록 상태 ===
class MyAppointmentsState {
  final List<Appointment> appointments;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;

  const MyAppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
  });

  MyAppointmentsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
  }) {
    return MyAppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // 예약 상태별 필터링
  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return appointments
        .where(
          (apt) =>
              (apt.status == AppointmentStatus.confirmed ||
                  apt.status == AppointmentStatus.pending) &&
              apt.scheduledDate.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return appointments
        .where(
          (apt) =>
              apt.status == AppointmentStatus.completed ||
              (apt.scheduledDate.isBefore(now) &&
                  apt.status != AppointmentStatus.cancelled),
        )
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  }

  List<Appointment> get cancelledAppointments {
    return appointments
        .where((apt) => apt.status == AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  }
}

// === Notifier 클래스들 ===

// === 예약 생성 Notifier ===
class BookingNotifier extends StateNotifier<BookingState> {
  CounselorService? _service;
  Timer? _validationTimer;
  void Function()? _onBookingCreated;

  BookingNotifier() : super(const BookingState()) {
    _initializeService();
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      _service = await CounselorService.getInstance();
      debugPrint('✅ BookingNotifier 초기화 완료');
    } catch (e) {
      debugPrint('❌ BookingNotifier 초기화 실패: $e');
      state = state.copyWith(error: '초기화 실패: $e');
    }
  }

  void setOnBookingCreatedCallback(void Function()? callback) {
    _onBookingCreated = callback;
  }

  void selectCounselor(String counselorId) {
    state = state.copyWith(
      selectedCounselorId: counselorId,
      validationError: null,
    );
    _scheduleValidation();
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, validationError: null);
    _scheduleValidation();
  }

  void selectTime(DateTime time) {
    state = state.copyWith(selectedTime: time, validationError: null);
    _scheduleValidation();
  }

  void selectMethod(CounselingMethod method) {
    state = state.copyWith(selectedMethod: method, validationError: null);
  }

  void setDuration(int minutes) {
    state = state.copyWith(durationMinutes: minutes, validationError: null);
    _scheduleValidation();
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void _scheduleValidation() {
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(milliseconds: 500), () {
      _validateBookingAvailability();
    });
  }

  Future<void> _validateBookingAvailability() async {
    if (!_hasRequiredFields() || _service == null) return;

    state = state.copyWith(isValidating: true, validationError: null);

    try {
      final availableSlots = await _service!.getAvailableSlots(
        state.selectedCounselorId!,
        state.selectedDate!,
      );

      final selectedDateTime = DateTime(
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
        state.selectedTime!.hour,
        state.selectedTime!.minute,
      );

      final isStillAvailable = availableSlots.any(
        (slot) =>
            slot.year == selectedDateTime.year &&
            slot.month == selectedDateTime.month &&
            slot.day == selectedDateTime.day &&
            slot.hour == selectedDateTime.hour &&
            slot.minute == selectedDateTime.minute,
      );

      state = state.copyWith(
        isValidating: false,
        validationError: isStillAvailable ? null : '선택한 시간이 더 이상 예약 가능하지 않습니다.',
      );

      debugPrint('🔍 예약 가능성 검증: ${isStillAvailable ? "가능" : "불가능"}');
    } catch (e) {
      debugPrint('⚠️ 예약 검증 오류: $e');
      state = state.copyWith(
        isValidating: false,
        validationError: '예약 가능성을 확인할 수 없습니다.',
      );
    }
  }

  Future<bool> createBooking() async {
    debugPrint(
      '🔎 [디버그] 예약 생성 시도: ${state.selectedCounselorId}, ${state.selectedDate}, ${state.selectedTime}, ${state.selectedMethod}',
    );
    if (!state.canBook || _service == null) {
      debugPrint('❌ 예약 생성 불가: canBook=${state.canBook}, state=$state');
      return false;
    }

    state = state.copyWith(isCreating: true, error: null);

    try {
      // 예약 가능 시간 재검증
      await _validateBookingAvailability();

      if (state.validationError != null) {
        state = state.copyWith(isCreating: false, error: state.validationError);
        return false;
      }

      final result = await _service!.createAppointment(
        counselorId: state.selectedCounselorId!,
        scheduledDate: DateTime(
          state.selectedDate!.year,
          state.selectedDate!.month,
          state.selectedDate!.day,
          state.selectedTime!.hour,
          state.selectedTime!.minute,
        ),
        durationMinutes: state.durationMinutes,
        method: state.selectedMethod!,
        notes: state.notes,
      );

      if (result.success && result.data != null) {
        state = state.copyWith(
          isCreating: false,
          createdAppointment: result.data,
        );

        debugPrint('✅ 예약 생성 성공: ${result.data!.id}');

        // 콜백 실행
        if (_onBookingCreated != null) {
          try {
            _onBookingCreated!();
            debugPrint('🔄 예약 생성 후 콜백 실행 완료');
          } catch (e) {
            debugPrint('⚠️ 콜백 실행 오류: $e');
          }
        }

        return true;
      } else {
        state = state.copyWith(
          isCreating: false,
          error: result.error ?? '예약 생성에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ 예약 생성 중 예외 발생: $e');
      state = state.copyWith(
        isCreating: false,
        error: '예약 처리 중 오류가 발생했습니다: $e',
      );
      return false;
    }
  }

  void reset() {
    _validationTimer?.cancel();
    state = const BookingState();
    debugPrint('🔄 예약 상태 초기화');
  }

  bool _hasRequiredFields() {
    return state.selectedCounselorId != null &&
        state.selectedDate != null &&
        state.selectedTime != null &&
        state.selectedMethod != null;
  }
}

// === 예약 가능 시간 Notifier ===
class AvailableSlotsNotifier extends StateNotifier<AvailableSlotsState> {
  final String counselorId;
  CounselorService? _service;
  Timer? _refreshTimer;

  AvailableSlotsNotifier(this.counselorId)
    : super(AvailableSlotsState(selectedDate: DateTime.now())) {
    _initializeService();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      _service = await CounselorService.getInstance();
      await loadAvailableSlots(state.selectedDate);
      _startRealTimeUpdates();
      debugPrint('✅ AvailableSlotsNotifier 초기화: $counselorId');
    } catch (e) {
      debugPrint('❌ AvailableSlotsNotifier 초기화 실패: $e');
      state = state.copyWith(error: '초기화 실패: $e');
    }
  }

  void _startRealTimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.needsUpdate && !state.isLoading) {
        _refreshAvailableSlots();
      }
    });
  }

  Future<void> loadAvailableSlots(DateTime date) async {
    if (_service == null) return;

    state = state.copyWith(selectedDate: date, isLoading: true, error: null);

    try {
      final slots = await _service!.getAvailableSlots(counselorId, date);
      state = state.copyWith(
        availableSlots: slots,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      debugPrint('✅ 예약 가능 시간 ${slots.length}개 로드');
    } catch (e) {
      debugPrint('❌ 예약 가능 시간 로드 오류: $e');
      state = state.copyWith(isLoading: false, error: '시간 로드 실패: $e');
    }
  }

  Future<void> _refreshAvailableSlots() async {
    if (_service == null || state.isLoading) return;

    state = state.copyWith(isRealTimeUpdating: true);

    try {
      final slots = await _service!.getAvailableSlots(
        counselorId,
        state.selectedDate,
      );

      if (!_slotsEqual(state.availableSlots, slots)) {
        state = state.copyWith(
          availableSlots: slots,
          isRealTimeUpdating: false,
          lastUpdated: DateTime.now(),
        );
        debugPrint('🔄 실시간 업데이트: 예약 상황 변경');
      } else {
        state = state.copyWith(
          isRealTimeUpdating: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ 실시간 업데이트 오류: $e');
      state = state.copyWith(isRealTimeUpdating: false);
    }
  }

  Future<void> changeDate(DateTime newDate) async =>
      loadAvailableSlots(newDate);

  Future<void> refresh() async => loadAvailableSlots(state.selectedDate);

  bool _slotsEqual(List<DateTime> slots1, List<DateTime> slots2) {
    if (slots1.length != slots2.length) return false;
    for (int i = 0; i < slots1.length; i++) {
      if (slots1[i] != slots2[i]) return false;
    }
    return true;
  }
}

// === 내 예약 목록 Notifier ===
class MyAppointmentsNotifier extends StateNotifier<MyAppointmentsState> {
  CounselorService? _service;
  Timer? _backgroundUpdateTimer;

  MyAppointmentsNotifier() : super(const MyAppointmentsState()) {
    _initializeService();
  }

  @override
  void dispose() {
    _backgroundUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      _service = await CounselorService.getInstance();
      await loadAppointments();
      _startBackgroundUpdates();
      debugPrint('✅ MyAppointmentsNotifier 초기화 완료');
    } catch (e) {
      debugPrint('❌ MyAppointmentsNotifier 초기화 실패: $e');
      state = state.copyWith(error: '초기화 실패: $e');
    }
  }

  void _startBackgroundUpdates() {
    _backgroundUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!state.isLoading && !state.isRefreshing) {
        _backgroundRefresh();
      }
    });
  }

  Future<void> loadAppointments() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      debugPrint('📅 예약 목록 로딩 시작...');

      final service = await CounselorService.getInstance();
      final appointments = await service.getMyAppointments();
      debugPrint('📅 로드된 예약 수: ${appointments.length}');

      if (appointments.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          appointments: [],
          lastUpdated: DateTime.now(),
        );
        debugPrint('📅 예약이 없습니다.');
        return;
      }

      if (_appointmentsEqual(state.appointments, appointments)) {
        state = state.copyWith(isLoading: false, lastUpdated: DateTime.now());
        debugPrint('📅 예약 데이터 동일, 상태 갱신 생략');
        return;
      }

      state = state.copyWith(
        isLoading: false,
        appointments: appointments,
        lastUpdated: DateTime.now(),
      );
      debugPrint('📅 예약 목록 로딩 완료');
    } catch (e) {
      debugPrint('⚠️ 예약 목록 로딩 실패: $e');
      state = state.copyWith(
        isLoading: false,
        error: '예약 목록을 불러오는데 실패했습니다.',
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> refreshAppointments() async {
    if (_service == null || state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final appointments = await _service!.getMyAppointments();
      state = state.copyWith(
        appointments: appointments,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      );
      debugPrint('🔄 내 예약 목록 새로고침 완료');
    } catch (e) {
      debugPrint('⚠️ 내 예약 새로고침 오류: $e');
      state = state.copyWith(isRefreshing: false, error: '새로고침에 실패했습니다: $e');
    }
  }

  Future<void> _backgroundRefresh() async {
    if (_service == null) return;

    try {
      final appointments = await _service!.getMyAppointments();

      // 데이터가 변경된 경우에만 상태 업데이트
      if (!_appointmentsEqual(state.appointments, appointments)) {
        state = state.copyWith(
          appointments: appointments,
          lastUpdated: DateTime.now(),
        );
        debugPrint('🔄 백그라운드 업데이트: 예약 목록 변경됨');
      }
    } catch (e) {
      debugPrint('⚠️ 백그라운드 업데이트 오류: $e');
    }
  }

  bool _appointmentsEqual(List<Appointment> list1, List<Appointment> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].status != list2[i].status ||
          list1[i].scheduledDate != list2[i].scheduledDate) {
        return false;
      }
    }
    return true;
  }
}

// === 상담사 검색 상태 및 Provider ===
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

  void performSearch(String query) {
    state = state.copyWith(searchQuery: query, searchError: null);
    _scheduleSearch();
  }

  void toggleSpecialty(String specialty) {
    final currentSpecialties = List<String>.from(state.selectedSpecialties);
    if (currentSpecialties.contains(specialty)) {
      currentSpecialties.remove(specialty);
    } else {
      currentSpecialties.add(specialty);
    }
    state = state.copyWith(selectedSpecialties: currentSpecialties);
  }

  void setMethod(CounselingMethod? method) {
    state = state.copyWith(selectedMethod: method);
  }

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating);
  }

  void setMaxPrice(int? price) {
    state = state.copyWith(maxPrice: price);
  }

  void setOnlineOnly(bool? onlineOnly) {
    state = state.copyWith(onlineOnly: onlineOnly);
  }

  void clearFilters() {
    state = const CounselorSearchState();
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      searchError: null,
    );
  }

  void _scheduleSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

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

// === 상담사 검색 Provider ===
final counselorSearchProvider =
    StateNotifierProvider<CounselorSearchNotifier, CounselorSearchState>((ref) {
      return CounselorSearchNotifier();
    });
