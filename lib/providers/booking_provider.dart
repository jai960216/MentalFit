import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/counselor_model.dart';
import '../shared/services/counselor_service.dart';

// === 예약 가능 시간 Provider ===
final availableSlotsProvider = StateNotifierProvider.family<
  AvailableSlotsNotifier,
  AvailableSlotsState,
  String
>((ref, counselorId) {
  return AvailableSlotsNotifier(counselorId);
});

// === 예약 생성 Provider ===
final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier();
});

// === 내 예약 목록 Provider ===
final myAppointmentsProvider =
    StateNotifierProvider<MyAppointmentsNotifier, MyAppointmentsState>((ref) {
      return MyAppointmentsNotifier();
    });

// === 예약 가능 시간 상태 ===
class AvailableSlotsState {
  final List<DateTime> availableSlots;
  final DateTime selectedDate;
  final bool isLoading;
  final String? error;

  const AvailableSlotsState({
    this.availableSlots = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.error,
  });

  AvailableSlotsState copyWith({
    List<DateTime>? availableSlots,
    DateTime? selectedDate,
    bool? isLoading,
    String? error,
  }) {
    return AvailableSlotsState(
      availableSlots: availableSlots ?? this.availableSlots,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// === 예약 가능 시간 Notifier ===
class AvailableSlotsNotifier extends StateNotifier<AvailableSlotsState> {
  final String counselorId;
  CounselorService? _counselorService;

  AvailableSlotsNotifier(this.counselorId)
    : super(AvailableSlotsState(selectedDate: DateTime.now())) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _counselorService = await CounselorService.getInstance();
    await loadAvailableSlots(state.selectedDate);
  }

  // === 예약 가능 시간 로드 ===
  Future<void> loadAvailableSlots(DateTime date) async {
    if (_counselorService == null) return;

    state = state.copyWith(selectedDate: date, isLoading: true, error: null);

    try {
      final slots = await _counselorService!.getAvailableSlots(
        counselorId,
        date,
      );
      state = state.copyWith(availableSlots: slots, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 날짜 변경 ===
  Future<void> changeDate(DateTime newDate) async {
    await loadAvailableSlots(newDate);
  }
}

// === 예약 생성 상태 ===
class BookingState {
  final String? selectedCounselorId;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final CounselingMethod? selectedMethod;
  final int durationMinutes;
  final String? notes;
  final bool isCreating;
  final String? error;

  const BookingState({
    this.selectedCounselorId,
    this.selectedDate,
    this.selectedTime,
    this.selectedMethod,
    this.durationMinutes = 60,
    this.notes,
    this.isCreating = false,
    this.error,
  });

  BookingState copyWith({
    String? selectedCounselorId,
    DateTime? selectedDate,
    DateTime? selectedTime,
    CounselingMethod? selectedMethod,
    int? durationMinutes,
    String? notes,
    bool? isCreating,
    String? error,
  }) {
    return BookingState(
      selectedCounselorId: selectedCounselorId ?? this.selectedCounselorId,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      isCreating: isCreating ?? this.isCreating,
      error: error,
    );
  }

  // === 예약 가능 여부 ===
  bool get canBook {
    return selectedCounselorId != null &&
        selectedDate != null &&
        selectedTime != null &&
        selectedMethod != null;
  }
}

// === 예약 생성 Notifier ===
class BookingNotifier extends StateNotifier<BookingState> {
  CounselorService? _counselorService;

  BookingNotifier() : super(const BookingState()) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _counselorService = await CounselorService.getInstance();
  }

  // === 상담사 선택 ===
  void selectCounselor(String counselorId) {
    state = state.copyWith(selectedCounselorId: counselorId);
  }

  // === 날짜 선택 ===
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // === 시간 선택 ===
  void selectTime(DateTime time) {
    state = state.copyWith(selectedTime: time);
  }

  // === 상담 방식 선택 ===
  void selectMethod(CounselingMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  // === 소요 시간 설정 ===
  void setDuration(int minutes) {
    state = state.copyWith(durationMinutes: minutes);
  }

  // === 요청 사항 설정 ===
  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  // === 예약 생성 ===
  Future<bool> createBooking() async {
    if (!state.canBook || _counselorService == null) return false;

    state = state.copyWith(isCreating: true, error: null);

    try {
      final result = await _counselorService!.createAppointment(
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

      if (result.success) {
        state = state.copyWith(isCreating: false);
        // 예약 성공 후 상태 초기화
        reset();
        return true;
      } else {
        state = state.copyWith(
          isCreating: false,
          error: result.error ?? '예약 생성에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return false;
    }
  }

  // === 상태 초기화 ===
  void reset() {
    state = const BookingState();
  }
}

// === 내 예약 목록 상태 ===
class MyAppointmentsState {
  final List<Appointment> appointments;
  final bool isLoading;
  final String? error;

  const MyAppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  MyAppointmentsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return MyAppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // === 예약 상태별 필터링 ===
  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return appointments
        .where(
          (appointment) =>
              appointment.scheduledDate.isAfter(now) &&
              (appointment.status == AppointmentStatus.confirmed ||
                  appointment.status == AppointmentStatus.pending),
        )
        .toList();
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return appointments
        .where(
          (appointment) =>
              appointment.scheduledDate.isBefore(now) ||
              appointment.status == AppointmentStatus.completed,
        )
        .toList();
  }

  List<Appointment> get cancelledAppointments {
    return appointments
        .where(
          (appointment) =>
              appointment.status == AppointmentStatus.cancelled ||
              appointment.status == AppointmentStatus.noShow,
        )
        .toList();
  }
}

// === 내 예약 목록 Notifier ===
class MyAppointmentsNotifier extends StateNotifier<MyAppointmentsState> {
  CounselorService? _counselorService;

  MyAppointmentsNotifier() : super(const MyAppointmentsState()) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    _counselorService = await CounselorService.getInstance();
    await loadAppointments();
  }

  // === 예약 목록 로드 ===
  Future<void> loadAppointments() async {
    if (_counselorService == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final appointments = await _counselorService!.getMyAppointments();
      state = state.copyWith(appointments: appointments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // === 예약 새로고침 ===
  Future<void> refreshAppointments() async {
    await loadAppointments();
  }

  // === 예약 취소 (추후 구현) ===
  Future<bool> cancelAppointment(String appointmentId) async {
    // TODO: API 연동
    return false;
  }
}
