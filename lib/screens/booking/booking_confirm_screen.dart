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

class BookingConfirmScreen extends ConsumerStatefulWidget {
  final String counselorId;

  const BookingConfirmScreen({super.key, required this.counselorId});

  @override
  ConsumerState<BookingConfirmScreen> createState() =>
      _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadBookingInfo();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  Future<void> _loadBookingInfo() async {
    // 상담사 정보 로드
    ref
        .read(counselorDetailProvider(widget.counselorId).notifier)
        .loadCounselorDetail();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final counselorDetailState = ref.watch(
      counselorDetailProvider(widget.counselorId),
    );
    final counselor = counselorDetailState.counselor;

    if (counselor == null || !bookingState.canBook) {
      return _buildLoadingScreen();
    }

    // BookingState에서 예약 정보 구성
    final mockAppointment = _createMockAppointment(bookingState, counselor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('예약 확정'),
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // === 성공 아이콘 ===
                      _buildSuccessIcon(),

                      SizedBox(height: 32.h),

                      // === 예약 정보 카드 ===
                      _buildBookingInfoCard(mockAppointment, counselor),

                      SizedBox(height: 24.h),

                      // === 결제 정보 ===
                      _buildPaymentInfo(counselor),

                      SizedBox(height: 24.h),

                      // === 안내 사항 ===
                      _buildGuidelines(),
                    ],
                  ),
                ),
              ),
            ),

            // === 버튼 영역 ===
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // === 헬퍼 메서드들 ===

  // MockAppointment 생성 (BookingState에서)
  Appointment _createMockAppointment(
    BookingState bookingState,
    Counselor counselor,
  ) {
    return Appointment(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      counselorId: counselor.id,
      userId: 'current_user',
      scheduledDate: DateTime(
        bookingState.selectedDate!.year,
        bookingState.selectedDate!.month,
        bookingState.selectedDate!.day,
        bookingState.selectedTime!.hour,
        bookingState.selectedTime!.minute,
      ),
      durationMinutes: bookingState.durationMinutes,
      method: bookingState.selectedMethod!,
      status: AppointmentStatus.pending,
      notes: bookingState.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // 시간 포맷팅
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // === UI 구성 요소들 ===

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 24.h),
            Text(
              '예약 정보를 불러오는 중...',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 3),
      ),
      child: Icon(Icons.check, size: 50.sp, color: AppColors.success),
    );
  }

  Widget _buildBookingInfoCard(Appointment appointment, Counselor counselor) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // === 제목 ===
          Text(
            '예약이 완료되었습니다!',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20.h),

          // === 상담사 정보 ===
          Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
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
                      counselor.profileImageUrl == null
                          ? AppColors.grey200
                          : null,
                ),
                child:
                    counselor.profileImageUrl == null
                        ? Icon(
                          Icons.person,
                          size: 25.sp,
                          color: AppColors.textSecondary,
                        )
                        : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counselor.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      counselor.specialties.join(', '),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // === 예약 상세 정보 ===
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_month,
                  '날짜',
                  '${appointment.scheduledDate.year}년 ${appointment.scheduledDate.month}월 ${appointment.scheduledDate.day}일',
                ),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  Icons.access_time,
                  '시간',
                  _formatTime(appointment.scheduledDate),
                ),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  Icons.videocam,
                  '상담 방식',
                  appointment.method == CounselingMethod.video
                      ? '화상 상담'
                      : '채팅 상담',
                ),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  Icons.confirmation_number,
                  '예약 번호',
                  appointment.id.substring(0, 8).toUpperCase(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primary),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(Counselor counselor) {
    final totalAmount = counselor.price.consultationFee;
    final serviceFee = (totalAmount * 0.1).round(); // 10% 서비스 수수료
    final finalAmount = totalAmount + serviceFee;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '결제 정보',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildPaymentRow('상담료', '₩${totalAmount.toStringAsFixed(0)}'),
          SizedBox(height: 8.h),
          _buildPaymentRow('서비스 수수료', '₩${serviceFee.toStringAsFixed(0)}'),
          SizedBox(height: 12.h),
          Divider(color: AppColors.grey200),
          SizedBox(height: 12.h),
          _buildPaymentRow(
            '총 결제 금액',
            '₩${finalAmount.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: FontWeight.w600,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                '상담 안내사항',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildGuidelineItem('• 상담 시간 10분 전까지 접속 해주세요'),
          _buildGuidelineItem('• 취소는 상담 2시간 전까지 가능합니다'),
          _buildGuidelineItem('• 상담사와의 연락은 채팅을 통해서만 가능합니다'),
          _buildGuidelineItem('• 상담 중 녹화나 녹음은 금지되어 있습니다'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
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
          // === 결제하기 버튼 ===
          CustomButton(
            text: '결제하기',
            onPressed: _isProcessing ? null : _handlePayment,
            isLoading: _isProcessing,
            icon: Icons.payment,
          ),
          SizedBox(height: 12.h),
          // === 나중에 결제하기 버튼 ===
          TextButton(
            onPressed: _isProcessing ? null : _handlePaymentLater,
            child: Text(
              '나중에 결제하기',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 액션 메서드들 ===

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 결제 처리 시뮬레이션
      await Future.delayed(const Duration(seconds: 2));

      // 예약 확정 처리 (실제로는 createBooking 호출)
      final success = await ref.read(bookingProvider.notifier).createBooking();

      if (success && mounted) {
        // 성공 시 예약 목록으로 이동
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorDialog('결제에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handlePaymentLater() async {
    // 예약만 생성하고 결제는 나중에 (현재는 바로 홈으로 이동)
    context.go(AppRoutes.home);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('예약 정보가 저장되었습니다. 상담 전까지 결제를 완료해주세요.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 60.sp, color: AppColors.success),
                SizedBox(height: 16.h),
                Text(
                  '결제가 완료되었습니다!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  '예약이 확정되었습니다.\n상담사가 곧 연락드릴 예정입니다.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.bookingList);
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('오류'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }
}
