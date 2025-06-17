import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/models/counselor_model.dart';
import '../../providers/booking_provider.dart';
import '../../shared/services/counselor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'review_dialog.dart';
import '../../providers/counselor_provider.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupAnimations();
    Future.microtask(_loadAppointments);
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  Future<void> _loadAppointments() async {
    await ref.read(myAppointmentsProvider.notifier).loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('내 예약'),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: '예정'), Tab(text: '완료'), Tab(text: '취소')],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer(
          builder: (context, ref, child) {
            final appointmentsState = ref.watch(myAppointmentsProvider);

            if (appointmentsState.isLoading) {
              return _buildLoadingState();
            }

            if (appointmentsState.error != null) {
              return _buildErrorState(appointmentsState.error!);
            }

            if (appointmentsState.appointments.isEmpty) {
              return _buildEmptyState('예약이 없습니다', '새로운 상담을 예약해보세요');
            }

            return _buildTabBarView(appointmentsState);
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTabBarView(MyAppointmentsState state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAppointmentsList(
          state.upcomingAppointments,
          '예정된 예약이 없습니다',
          '새로운 상담을 예약해보세요',
          showActions: true,
        ),
        _buildAppointmentsList(
          state.pastAppointments,
          '완료된 예약이 없습니다',
          '첫 상담을 시작해보세요',
          showReview: true,
        ),
        _buildAppointmentsList(state.cancelledAppointments, '취소된 예약이 없습니다', ''),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24.h),
          Text(
            '예약 목록을 불러오는 중...',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
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
            SizedBox(height: 24.h),
            Text(
              '예약 목록을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: '다시 시도',
              onPressed: _loadAppointments,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Appointment> appointments,
    String emptyTitle,
    String emptySubtitle, {
    bool showActions = false,
    bool showReview = false,
  }) {
    if (appointments.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildAppointmentCard(
              appointment,
              showActions: showActions,
              showReview: showReview,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 32.h),
            CustomButton(
              text: '새 예약하기',
              onPressed: () => context.push(AppRoutes.counselorList),
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    Appointment appointment, {
    bool showActions = false,
    bool showReview = false,
  }) {
    return Container(
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
        children: [
          _buildCardHeader(appointment),
          _buildCardDetails(appointment),
          if (showActions || showReview)
            _buildCardActions(appointment, showActions, showReview),
        ],
      ),
    );
  }

  Widget _buildCardHeader(Appointment appointment) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              _getStatusText(appointment.status),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _formatDateTime(appointment.scheduledDate),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails(Appointment appointment) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_month,
            '일시',
            _formatDateTime(appointment.scheduledDate),
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            _getMethodIcon(appointment.method),
            '상담 방식',
            _getMethodText(appointment.method),
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            Icons.confirmation_number,
            '예약 번호',
            appointment.id.substring(0, 8).toUpperCase(),
          ),
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.note, '메모', appointment.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildCardActions(
    Appointment appointment,
    bool showActions,
    bool showReview,
  ) {
    // 리뷰 작성 여부 확인 (리뷰 목록에서 appointmentId와 userId로 판별)
    final myUserId = FirebaseAuth.instance.currentUser?.uid;
    final reviewsState = ref.watch(
      counselorReviewsProvider(appointment.counselorId),
    );
    final hasReview = reviewsState.reviews.any(
      (r) => r.userId == myUserId && r.appointmentId == appointment.id,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 16.w),
      child: Row(
        children: [
          if (showActions) ...[
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _completeAppointment(appointment),
                child: const Text('상담 완료'),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showCancelDialog(appointment),
                child: const Text('취소하기'),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _joinSession(appointment),
                child: const Text('채팅 상담'),
              ),
            ),
          ],
          if (showReview) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
                onPressed: () => _viewDetails(appointment),
                child: const Text('상세보기'),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 2,
              child:
                  hasReview
                      ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey200,
                          foregroundColor: AppColors.textSecondary,
                        ),
                        onPressed: null,
                        child: const Text('리뷰작성 완료'),
                      )
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _writeReview(appointment),
                        child: const Text('리뷰 작성'),
                      ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => context.push(AppRoutes.counselorList),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('새 예약'),
    );
  }

  // === 상태 관련 유틸리티 메서드들 ===
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
      case AppointmentStatus.pending:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.warning;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return '대기중';
      case AppointmentStatus.confirmed:
        return '확정됨';
      case AppointmentStatus.completed:
        return '완료됨';
      case AppointmentStatus.cancelled:
        return '취소됨';
      case AppointmentStatus.noShow:
        return '불참';
    }
  }

  IconData _getMethodIcon(CounselingMethod method) {
    switch (method) {
      case CounselingMethod.online:
        return Icons.videocam;
      case CounselingMethod.offline:
        return Icons.call;
      case CounselingMethod.all:
        return Icons.all_inclusive;
      default:
        return Icons.help_outline;
    }
  }

  String _getMethodText(CounselingMethod method) {
    switch (method) {
      case CounselingMethod.online:
        return '온라인 상담';
      case CounselingMethod.offline:
        return '오프라인 상담';
      case CounselingMethod.all:
        return '전체';
      default:
        return '알 수 없음';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[dateTime.weekday % 7];

    return '${dateTime.month}월 ${dateTime.day}일($weekday) ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // === 액션 메서드들 ===
  void _showCancelDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('예약 취소'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('정말로 이 예약을 취소하시겠습니까?'),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: AppColors.warning,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '예약 시간 2시간 전까지만 취소 가능합니다.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelAppointment(appointment);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('취소하기'),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      _showLoadingDialog('예약을 취소하는 중...');

      final service = await CounselorService.getInstance();
      final result = await service.cancelAppointment(appointment.id);

      if (mounted) Navigator.of(context).pop();

      if (result.success) {
        await _loadAppointments();

        if (mounted) {
          _showSuccessSnackBar('예약이 성공적으로 취소되었습니다.');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(result.error ?? '예약 취소에 실패했습니다.');
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        _showErrorSnackBar('예약 취소 중 오류가 발생했습니다: $e');
      }
    }
  }

  void _joinSession(Appointment appointment) {
    if (appointment.meetingLink != null &&
        appointment.meetingLink!.isNotEmpty) {
      _showInfoDialog(
        '채팅 상담',
        '상담사가 제공한 링크로 연결됩니다.\n\n링크: \\${appointment.meetingLink}',
      );
    } else if (appointment.counselorId != null &&
        appointment.counselorId!.isNotEmpty) {
      context.push('${AppRoutes.chatRoom}/${appointment.counselorId}');
    } else {
      _showErrorSnackBar('상담사 정보가 올바르지 않습니다.');
    }
  }

  void _viewDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailBottomSheet(appointment),
    );
  }

  Widget _buildDetailBottomSheet(Appointment appointment) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Text(
                  '예약 상세 정보',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.grey200),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('예약 정보', [
                    _buildDetailItem(
                      '예약 번호',
                      appointment.id.substring(0, 8).toUpperCase(),
                    ),
                    _buildDetailItem('상태', _getStatusText(appointment.status)),
                    _buildDetailItem(
                      '예약 일시',
                      _formatDateTime(appointment.scheduledDate),
                    ),
                    _buildDetailItem(
                      '상담 방식',
                      _getMethodText(appointment.method),
                    ),
                    _buildDetailItem(
                      '상담 시간',
                      '${appointment.durationMinutes}분',
                    ),
                  ]),

                  SizedBox(height: 24.h),

                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty)
                    _buildDetailSection('메모', [
                      Text(
                        appointment.notes!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _writeReview(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => ReviewDialog(
            appointment: appointment,
            onReviewSubmitted: () async {
              await _loadAppointments();
              if (mounted) _showSuccessSnackBar('리뷰가 등록되었습니다!');
            },
          ),
    );
  }

  // === 다이얼로그 및 스낵바 유틸리티 ===
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(width: 16.w),
                Expanded(child: Text(message)),
              ],
            ),
          ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // === 상담 완료 처리 함수 추가 ===
  Future<void> _completeAppointment(Appointment appointment) async {
    try {
      _showLoadingDialog('상담을 완료 처리하는 중...');
      final service = await CounselorService.getInstance();
      final result = await service.completeAppointment(appointment.id);

      if (mounted) Navigator.of(context).pop();

      if (result.success) {
        await _loadAppointments();
        if (mounted) {
          _tabController.index = 1; // 완료 탭으로 이동
          _showSuccessSnackBar('상담이 완료 처리되었습니다.');
        }
      } else {
        if (mounted) _showErrorSnackBar(result.error ?? '상담 완료 처리에 실패했습니다.');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) _showErrorSnackBar('상담 완료 처리 중 오류가 발생했습니다: $e');
    }
  }
}
