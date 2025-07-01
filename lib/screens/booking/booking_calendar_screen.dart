import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
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
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _selectedTime;
  CounselingMethod _selectedMethod = CounselingMethod.online;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    _setupBookingCallback();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();
  }

  Future<void> _loadInitialData() async {
    // 상담사 정보 로드
    ref
        .read(counselorDetailProvider(widget.counselorId).notifier)
        .loadCounselorDetail();

    // 오늘 날짜의 예약 가능 시간 로드
    ref
        .read(availableSlotsProvider(widget.counselorId).notifier)
        .loadAvailableSlots(DateTime.now());
  }

  void _setupBookingCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).setOnBookingCreatedCallback(() {
        ref.read(myAppointmentsProvider.notifier).loadAppointments();
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer(
          builder: (context, ref, child) {
            final counselorState = ref.watch(
              counselorDetailProvider(widget.counselorId),
            );

            if (counselorState.isLoading) {
              debugPrint('상담사 정보 로딩 중...');
              return _buildLoadingState();
            }

            if (counselorState.error != null) {
              debugPrint('상담사 정보 에러: \\${counselorState.error}');
              return _buildErrorState(counselorState.error!);
            }

            if (counselorState.counselor == null) {
              debugPrint('상담사 정보 없음');
              return _buildNotFoundState();
            }

            return Column(
              children: [
                _buildCounselorHeader(counselorState.counselor!),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCalendarSection(),
                        if (_selectedDay != null) _buildTimeSlots(),
                        if (_selectedDay != null && _selectedTime != null)
                          _buildMethodSelection(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBookingButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('예약하기'),
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showHelpDialog,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16.h),
          Text(
            '상담사 정보를 불러오는 중...',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              '상담사 정보를 불러올 수 없습니다',
              style: TextStyle(fontSize: 16.sp, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: '다시 시도',
              onPressed: _loadInitialData,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              '상담사 정보를 찾을 수 없습니다',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24.h),
            CustomButton(text: '상담사 목록으로', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildCounselorHeader(Counselor counselor) {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: AppColors.grey200,
            backgroundImage:
                counselor.profileImageUrl != null
                    ? NetworkImage(counselor.profileImageUrl!)
                    : null,
            child:
                counselor.profileImageUrl == null
                    ? Icon(Icons.person, size: 32.sp, color: AppColors.grey400)
                    : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      counselor.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (counselor.isOnline)
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  counselor.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.star, size: 16.sp, color: AppColors.warning),
                    SizedBox(width: 4.w),
                    Text(
                      counselor.ratingText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '(${counselor.reviewCount})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(counselor.price.consultationFee / 10000).toInt()}만원',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '1회 상담',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예약 날짜 선택',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          TableCalendar<DateTime>(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            onDaySelected: _onDaySelected,
            onPageChanged:
                (focusedDay) => setState(() => _focusedDay = focusedDay),
            enabledDayPredicate:
                (day) =>
                    !day.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: AppColors.error),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppColors.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _getEventsForDay(DateTime day) {
    // 예약 가능한 날짜에 마커 표시
    // 이 부분은 실제로는 상담사의 availableTimes를 체크해야 함
    final weekday = _getKoreanWeekday(day.weekday);
    final counselorState = ref.read(
      counselorDetailProvider(widget.counselorId),
    );

    if (counselorState.counselor != null) {
      final hasAvailableTime = counselorState.counselor!.availableTimes.any(
        (time) => time.day == weekday,
      );
      return hasAvailableTime ? [day] : [];
    }

    return [];
  }

  Widget _buildTimeSlots() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예약 시간 선택',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Consumer(
            builder: (context, ref, child) {
              final slotsState = ref.watch(
                availableSlotsProvider(widget.counselorId),
              );

              if (slotsState.isLoading) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.h),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (slotsState.error != null) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.h),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        SizedBox(height: 8.h),
                        Text(
                          slotsState.error!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (slotsState.availableSlots.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.h),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 48.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '선택한 날짜에 예약 가능한 시간이 없습니다',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '다른 날짜를 선택해주세요',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children:
                    slotsState.availableSlots.map((slot) {
                      final isSelected =
                          _selectedTime != null &&
                          _selectedTime!.hour == slot.hour &&
                          _selectedTime!.minute == slot.minute;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedTime = slot);
                          ref.read(bookingProvider.notifier).selectTime(slot);
                          _slideController.reset();
                          _slideController.forward();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.grey50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.grey200,
                            ),
                          ),
                          child: Text(
                            '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상담 방식 선택',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children:
                  CounselingMethod.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    return InkWell(
                      onTap: () => setState(() => _selectedMethod = method),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.background,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              method.icon,
                              size: 20.sp,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              method.displayName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingButton() {
    return Consumer(
      builder: (context, ref, child) {
        final bookingState = ref.watch(bookingProvider);
        final canBook = _selectedDay != null && _selectedTime != null;

        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canBook) _buildSelectedBookingInfo(),
                CustomButton(
                  text: bookingState.isCreating ? '예약 중...' : '예약하기',
                  onPressed:
                      canBook && !bookingState.isCreating
                          ? _handleBooking
                          : null,
                  isLoading: bookingState.isCreating,
                  icon: bookingState.isCreating ? null : Icons.calendar_month,
                  gradient:
                      canBook
                          ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          )
                          : null,
                ),
                if (bookingState.error != null)
                  _buildErrorMessage(bookingState.error!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedBookingInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.lightBlue50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available, size: 20.sp, color: AppColors.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedDay!.month}월 ${_selectedDay!.day}일 ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_selectedMethod.displayName} 상담',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16.sp, color: AppColors.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 12.sp, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _selectedTime = null;
      _focusedDay = focusedDay;
    });

    // 선택한 날짜의 예약 가능 시간 로드
    ref
        .read(availableSlotsProvider(widget.counselorId).notifier)
        .loadAvailableSlots(selectedDay);
    ref.read(bookingProvider.notifier).selectDate(selectedDay);

    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _handleBooking() async {
    if (_selectedDay == null || _selectedTime == null) return;

    // 예약 정보 설정 (예약 생성 X)
    ref.read(bookingProvider.notifier)
      ..selectCounselor(widget.counselorId)
      ..selectDate(_selectedDay!)
      ..selectTime(_selectedTime!)
      ..selectMethod(_selectedMethod);

    // 예약확인 화면으로 이동 (임시 예약 정보 전달)
    final bookingState = ref.read(bookingProvider);
    context.push(
      '${AppRoutes.bookingConfirm}/${widget.counselorId}',
      extra: {
        'counselorId': widget.counselorId,
        'selectedDate': bookingState.selectedDate,
        'selectedTime': bookingState.selectedTime,
        'selectedMethod': bookingState.selectedMethod,
        'durationMinutes': bookingState.durationMinutes,
        'notes': bookingState.notes,
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('예약 도움말'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  Icons.calendar_today,
                  '날짜 선택',
                  '오늘부터 30일 후까지 예약 가능합니다.',
                ),
                SizedBox(height: 12.h),
                _buildHelpItem(
                  Icons.schedule,
                  '시간 선택',
                  '녹색 점이 있는 날짜에 예약 가능한 시간이 있습니다.',
                ),
                SizedBox(height: 12.h),
                _buildHelpItem(
                  Icons.videocam,
                  '상담 방식',
                  '화상, 음성, 채팅, 대면 중 선택할 수 있습니다.',
                ),
                SizedBox(height: 12.h),
                _buildHelpItem(
                  Icons.cancel,
                  '예약 취소',
                  '예약 시간 2시간 전까지 취소 가능합니다.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getKoreanWeekday(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }
}
