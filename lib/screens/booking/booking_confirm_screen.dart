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
  final Appointment appointment;

  const BookingConfirmScreen({
    super.key,
    required this.counselorId,
    required this.appointment,
  });

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
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final counselor =
        ref.watch(counselorDetailProvider(widget.counselorId)).counselor;
    if (counselor == null) {
      return _buildLoadingScreen();
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
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
                      _buildSuccessIcon(),
                      SizedBox(height: 32.h),
                      _buildBookingInfoCard(appointment, counselor),
                      SizedBox(height: 24.h),
                      _buildPaymentInfo(counselor),
                      SizedBox(height: 24.h),
                      _buildGuidelines(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('예약 확인'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '예약 확인',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_outline,
        size: 50.sp,
        color: AppColors.success,
      ),
    );
  }

  Widget _buildBookingInfoCard(Appointment appointment, Counselor counselor) {
    return Container(
      padding: EdgeInsets.all(24.w),
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
            '예약 정보',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          _buildInfoRow(
            icon: Icons.person,
            label: '상담사',
            value: '${counselor.name} (${counselor.title})',
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.schedule,
            label: '예약 일시',
            value: _formatDateTime(appointment.scheduledDate),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: _getMethodIcon(appointment.method),
            label: '상담 방식',
            value: appointment.method.displayName,
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.timer,
            label: '상담 시간',
            value: '${appointment.durationMinutes}분',
          ),
          if (appointment.notes?.isNotEmpty == true) ...[
            SizedBox(height: 16.h),
            _buildInfoRow(
              icon: Icons.note,
              label: '요청 사항',
              value: appointment.notes!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.primary),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(Counselor counselor) {
    return Container(
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
            '결제 정보',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildPriceRow('상담료', '${counselor.price.consultationFee}원'),
          SizedBox(height: 8.h),
          _buildPriceRow('수수료', '무료', isSecondary: true),
          SizedBox(height: 12.h),
          Divider(color: AppColors.grey200),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 결제금액',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${counselor.price.consultationFee}원',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String price, {
    bool isSecondary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSecondary ? 14.sp : 16.sp,
            color:
                isSecondary ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: isSecondary ? 14.sp : 16.sp,
            fontWeight: FontWeight.w600,
            color:
                isSecondary
                    ? (label == '수수료'
                        ? AppColors.success
                        : AppColors.textSecondary)
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelines() {
    final guidelines = [
      '• 예약 시간 10분 전까지 대기해주세요.',
      '• 상담 2시간 전까지 취소 가능합니다.',
      '• 상담사가 예약 확정 후 연락드립니다.',
      '• 화상상담의 경우 링크를 전송해드립니다.',
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.lightBlue50,
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
                '안내 사항',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...guidelines.map(
            (guideline) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                guideline,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.primary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
            CustomButton(
              text: _isProcessing ? '결제 처리 중...' : '결제하기',
              onPressed: _isProcessing ? null : _handlePayment,
              isLoading: _isProcessing,
              icon: _isProcessing ? null : Icons.payment,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            SizedBox(height: 12.h),
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
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    try {
      await Future.delayed(const Duration(seconds: 2)); // 결제 시뮬레이션
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('결제 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handlePaymentLater() async {
    if (mounted) {
      context.go(AppRoutes.home);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('예약 정보가 저장되었습니다. 상담 전까지 결제를 완료해주세요.'),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: '예약 목록',
            textColor: Colors.white,
            onPressed: () => context.push(AppRoutes.bookingList),
          ),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
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
                    color: AppColors.textPrimary,
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
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _navigateToHome(),
                      child: const Text('홈으로'),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: '예약 목록',
                      onPressed: () => _navigateToBookingList(),
                      height: 40.h,
                      textSize: 18.sp,
                    ),
                  ),
                ],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                SizedBox(width: 8.w),
                const Text('오류'),
              ],
            ),
            content: Text(message, style: TextStyle(fontSize: 14.sp)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pop();
    ref.read(bookingProvider.notifier).reset();
    context.go(AppRoutes.home);
  }

  void _navigateToBookingList() {
    Navigator.of(context).pop();
    ref.read(bookingProvider.notifier).reset();
    context.push(AppRoutes.bookingList);
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      '',
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return '${months[dateTime.month]} ${dateTime.day}일 (${weekdays[dateTime.weekday % 7]}) ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getMethodIcon(CounselingMethod method) {
    switch (method) {
      case CounselingMethod.online:
        return Icons.videocam;
      case CounselingMethod.offline:
        return Icons.people;
      case CounselingMethod.all:
        return Icons.all_inclusive;
      default:
        return Icons.help_outline;
    }
  }
}

extension CounselingMethodExtension on CounselingMethod {
  String get displayName {
    switch (this) {
      case CounselingMethod.online:
        return '온라인 상담';
      case CounselingMethod.offline:
        return '오프라인 상담';
      case CounselingMethod.all:
        return '온/오프라인 모두 가능';
      default:
        return '알 수 없음';
    }
  }
}
