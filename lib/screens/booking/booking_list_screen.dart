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
    _loadAppointments();
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
    final appointmentsState = ref.watch(myAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('내 예약'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
        child:
            appointmentsState.isLoading
                ? _buildLoadingState()
                : appointmentsState.error != null
                ? _buildErrorState(appointmentsState.error!, _loadAppointments)
                : TabBarView(
                  controller: _tabController,
                  children: [
                    // === 예정된 예약 ===
                    _buildAppointmentsList(
                      appointmentsState.upcomingAppointments,
                      '예정된 예약이 없습니다',
                      '새로운 상담을 예약해보세요',
                      showActions: true,
                    ),
                    // === 완료된 예약 ===
                    _buildAppointmentsList(
                      appointmentsState.pastAppointments,
                      '완료된 예약이 없습니다',
                      '첫 상담을 시작해보세요',
                      showReview: true,
                    ),
                    // === 취소된 예약 ===
                    _buildAppointmentsList(
                      appointmentsState.cancelledAppointments,
                      '취소된 예약이 없습니다',
                      '',
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.counselorList),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text(
          '새 예약',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24.h),
          Text(
            '예약 목록을 불러오는 중...',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
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
              onPressed: onRetry,
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
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(
            appointment,
            showActions: showActions,
            showReview: showReview,
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
            Icon(Icons.event_note, size: 80.sp, color: AppColors.grey300),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 32.h),
            CustomButton(
              text: '상담사 찾기',
              onPressed: () => context.push(AppRoutes.counselorList),
              icon: Icons.search,
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
    // 상담사 정보를 별도로 가져와야 함
    final counselorDetailState = ref.watch(
      counselorDetailProvider(appointment.counselorId),
    );
    final counselor = counselorDetailState.counselor;

    if (counselor == null) {
      return Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Text(
            '상담사 정보를 불러오는 중...',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
        children: [
          // === 메인 정보 ===
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
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
                                  image: NetworkImage(
                                    counselor.profileImageUrl!,
                                  ),
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
                          Row(
                            children: [
                              Text(
                                counselor.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              _buildStatusBadge(appointment.status),
                            ],
                          ),
                          SizedBox(height: 4.h),
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
                    Text(
                      '₩${counselor.price.consultationFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // === 예약 상세 정보 ===
                Container(
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === 액션 버튼들 ===
          if (showActions || showReview)
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
              child: Row(
                children: [
                  if (showActions) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showCancelDialog(appointment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                        ),
                        child: Text('취소하기'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _joinSession(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('상담 참여'),
                      ),
                    ),
                  ],
                  if (showReview) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _writeReview(appointment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                        ),
                        child: Text('리뷰 작성'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _viewRecord(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey600,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('기록 보기'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case AppointmentStatus.pending:
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        text = '대기중';
        break;
      case AppointmentStatus.confirmed:
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        text = '확정';
        break;
      case AppointmentStatus.completed:
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        text = '완료';
        break;
      case AppointmentStatus.cancelled:
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        text = '취소';
        break;
      case AppointmentStatus.noShow:
        backgroundColor = AppColors.grey300.withOpacity(0.1);
        textColor = AppColors.grey600;
        text = '노쇼';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // === 액션 메서드들 ===

  Future<void> _joinSession(Appointment appointment) async {
    // 상담 참여 로직 (채팅방으로 이동)
    if (appointment.method == CounselingMethod.chat) {
      context.push('${AppRoutes.chatRoom}/${appointment.id}');
    } else {
      // 화상 상담의 경우 별도 처리
      _showComingSoonDialog('화상 상담');
    }
  }

  Future<void> _writeReview(Appointment appointment) async {
    // 리뷰 작성 (추후 구현)
    _showComingSoonDialog('리뷰 작성');
  }

  Future<void> _viewRecord(Appointment appointment) async {
    // 상담 기록 보기
    context.push('${AppRoutes.recordDetail}/${appointment.id}');
  }

  void _showCancelDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('예약 취소'),
            content: const Text('정말로 이 예약을 취소하시겠습니까?\n취소된 예약은 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _cancelAppointment(appointment);
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
      final success = await ref
          .read(myAppointmentsProvider.notifier)
          .cancelAppointment(appointment.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 취소되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadAppointments(); // 목록 새로고침
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약 취소에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('준비 중'),
            content: Text('$feature 기능은 곧 제공될 예정입니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  // === 헬퍼 메서드들 ===

  IconData _getMethodIcon(CounselingMethod method) {
    switch (method) {
      case CounselingMethod.faceToFace:
        return Icons.person;
      case CounselingMethod.video:
        return Icons.videocam;
      case CounselingMethod.voice:
        return Icons.phone;
      case CounselingMethod.chat:
        return Icons.chat;
      case CounselingMethod.all:
        return Icons.help_outline;
    }
  }

  String _getMethodText(CounselingMethod method) {
    switch (method) {
      case CounselingMethod.faceToFace:
        return '대면 상담';
      case CounselingMethod.video:
        return '화상 상담';
      case CounselingMethod.voice:
        return '음성 상담';
      case CounselingMethod.chat:
        return '채팅 상담';
      case CounselingMethod.all:
        return '전체';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
