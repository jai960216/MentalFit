import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/models/counselor_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/counselor_provider.dart';

class BookingCalendarScreen extends ConsumerStatefulWidget {
  final String counselorId;

  const BookingCalendarScreen({super.key, required this.counselorId});

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends ConsumerState<BookingCalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;
  CounselingMethod _selectedMethod = CounselingMethod.video;

  final List<String> _timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '19:00',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAvailableSlots();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  Future<void> _loadAvailableSlots() async {
    // availableSlotsProvider를 사용하여 예약 가능 시간 로드
    ref
        .read(availableSlotsProvider(widget.counselorId).notifier)
        .loadAvailableSlots(DateTime.now());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final counselorDetailState = ref.watch(
      counselorDetailProvider(widget.counselorId),
    );
    final counselor = counselorDetailState.counselor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('예약하기'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // === 상담사 정보 헤더 ===
            if (counselor != null) _buildCounselorHeader(counselor),

            // === 메인 컨텐츠 ===
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // === 상담 방식 선택 ===
                    _buildMethodSelection(),

                    // === 달력 ===
                    _buildCalendar(),

                    // === 시간 선택 ===
                    if (_selectedDay != null) _buildTimeSlotSelection(),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            // === 예약하기 버튼 ===
            _buildBookingButton(),
          ],
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildCounselorHeader(Counselor counselor) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 상담사 프로필 이미지
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image:
                  counselor.profileImageUrl != null
                      ? DecorationImage(
                        image: NetworkImage(counselor.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
              color:
                  counselor.profileImageUrl == null ? AppColors.grey200 : null,
            ),
            child:
                counselor.profileImageUrl == null
                    ? Icon(
                      Icons.person,
                      size: 30.sp,
                      color: AppColors.textSecondary,
                    )
                    : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counselor.name,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  counselor.specialties.join(', '),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      '₩${counselor.price.consultationFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      ' / 회',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상담 방식',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildMethodOption(
                  CounselingMethod.video,
                  '화상 상담',
                  Icons.videocam,
                  '편안한 공간에서',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMethodOption(
                  CounselingMethod.chat,
                  '채팅 상담',
                  Icons.chat,
                  '텍스트로 소통',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(
    CounselingMethod method,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '날짜 선택',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildSimpleCalendar(),
        ],
      ),
    );
  }

  Widget _buildSimpleCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Column(
      children: [
        // 요일 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              ['일', '월', '화', '수', '목', '금', '토']
                  .map(
                    (day) => Text(
                      day,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                  .toList(),
        ),
        SizedBox(height: 12.h),
        // 날짜 그리드
        ...List.generate(
          (daysInMonth / 7).ceil(),
          (weekIndex) => _buildWeekRow(weekIndex, now),
        ),
      ],
    );
  }

  Widget _buildWeekRow(int weekIndex, DateTime now) {
    final startDay = weekIndex * 7 + 1;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (dayIndex) {
          final day = startDay + dayIndex;
          if (day > daysInMonth) {
            return SizedBox(width: 32.w, height: 32.w);
          }

          final date = DateTime(now.year, now.month, day);
          final isSelected = _selectedDay?.day == day;
          final isPast = date.isBefore(
            DateTime.now().subtract(const Duration(days: 1)),
          );

          return GestureDetector(
            onTap:
                isPast
                    ? null
                    : () {
                      setState(() {
                        _selectedDay = date;
                        _selectedTimeSlot = null; // 날짜 변경시 시간 초기화
                      });
                    },
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isPast
                            ? AppColors.grey300
                            : isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeSlotSelection() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시간 선택',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                _timeSlots.map((timeSlot) {
                  final isSelected = _selectedTimeSlot == timeSlot;
                  final isAvailable = _isTimeSlotAvailable(timeSlot);

                  return GestureDetector(
                    onTap:
                        isAvailable
                            ? () {
                              setState(() {
                                _selectedTimeSlot = timeSlot;
                              });
                            }
                            : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary
                                : isAvailable
                                ? AppColors.grey50
                                : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.grey200,
                        ),
                      ),
                      child: Text(
                        timeSlot,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected
                                  ? Colors.white
                                  : isAvailable
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    final bookingState = ref.watch(bookingProvider);
    final canBook = _selectedDay != null && _selectedTimeSlot != null;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedDay != null && _selectedTimeSlot != null)
            Container(
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${_selectedDay!.month}월 ${_selectedDay!.day}일 $_selectedTimeSlot',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          CustomButton(
            text: '예약하기',
            onPressed: canBook ? _handleBooking : null,
            isLoading: bookingState.isCreating,
            icon: Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  // === 헬퍼 메서드들 ===

  bool _isTimeSlotAvailable(String timeSlot) {
    // TODO: 실제 예약 가능 여부 확인 로직
    // 현재는 모든 시간대를 사용 가능으로 처리
    return true;
  }

  Future<void> _handleBooking() async {
    if (_selectedDay == null || _selectedTimeSlot == null) return;

    // BookingNotifier의 메서드 사용
    ref.read(bookingProvider.notifier).selectCounselor(widget.counselorId);
    ref.read(bookingProvider.notifier).selectDate(_selectedDay!);
    ref.read(bookingProvider.notifier).selectMethod(_selectedMethod);

    // 시간 슬롯을 DateTime으로 변환
    final timeParts = _selectedTimeSlot!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final selectedDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      hour,
      minute,
    );
    ref.read(bookingProvider.notifier).selectTime(selectedDateTime);

    final success = await ref.read(bookingProvider.notifier).createBooking();

    if (success && mounted) {
      // 예약 성공 시 확정 화면으로 이동 (수정된 라우트 사용)
      context.go(AppRoutes.getBookingConfirmRoute(widget.counselorId));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
