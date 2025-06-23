import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/counselor_model.dart';
import '../../shared/services/counselor_service.dart';
import '../../providers/auth_provider.dart';
import '../../shared/models/user_model.dart';

class CounselorApprovalScreen extends ConsumerStatefulWidget {
  const CounselorApprovalScreen({super.key});

  @override
  ConsumerState<CounselorApprovalScreen> createState() =>
      _CounselorApprovalScreenState();
}

class _CounselorApprovalScreenState
    extends ConsumerState<CounselorApprovalScreen> {
  bool _isLoading = false;
  List<CounselorRequest> _requests = [];
  CounselorRequestStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 상담사 승인 화면: 요청 목록 로딩 시작');
      final counselorService = await CounselorService.getInstance();
      print('✅ CounselorService 인스턴스 생성 완료');

      final requests = await counselorService.getCounselorRequests(
        status: _selectedStatus,
      );
      print('✅ 상담사 등록 요청 ${requests.length}개 조회 완료');

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ 상담사 승인 화면 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, '오류가 발생했습니다: $e');
      }
    }
  }

  Future<void> _handleApproval(CounselorRequest request, bool approved) async {
    try {
      final counselorService = await CounselorService.getInstance();
      final status =
          approved
              ? CounselorRequestStatus.approved
              : CounselorRequestStatus.rejected;

      String? rejectionReason;
      if (!approved) {
        rejectionReason = await _showRejectionDialog();
        if (rejectionReason == null) return; // 사용자가 취소
      }

      // 상태 업데이트 로직 실행
      await counselorService.updateCounselorRequestStatus(
        request.id,
        status,
        rejectionReason: rejectionReason,
      );

      // 성공 메시지 표시 및 목록 새로고침
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? '상담사 등록을 승인했습니다.' : '상담사 등록을 거부했습니다.'),
            backgroundColor: approved ? AppColors.success : AppColors.error,
          ),
        );
        _loadRequests(); // 목록 새로고침
      }
    } catch (e) {
      // Firestore 권한 오류 발생 시 자동 로그아웃 및 안내
      ref
          .read(authProvider.notifier)
          .handleFirestoreAuthError(e, context: context);
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e.toString());
      }
    }
  }

  ImageProvider? _getImageProviderFromString(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      try {
        final bytes = base64Decode(imageUrl);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding base64 image: $e');
        return null;
      }
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('거부 사유'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '거부 사유를 입력해주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // master 권한 체크
    if (user?.userType != UserType.master) {
      return Scaffold(
        appBar: const CustomAppBar(title: '상담사 승인'),
        body: const Center(child: Text('접근 권한이 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '상담사 승인'),
      body: Column(
        children: [
          // 필터 버튼
          Container(
            padding: EdgeInsets.all(16.w),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CounselorRequestStatus?>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: '상태별 필터',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('전체')),
                      ...CounselorRequestStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                      _loadRequests();
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                IconButton(
                  onPressed: _loadRequests,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // 요청 목록
          Expanded(
            child:
                _isLoading
                    ? const LoadingWidget()
                    : _requests.isEmpty
                    ? const Center(child: Text('상담사 등록 요청이 없습니다.'))
                    : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return _buildRequestCard(request);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CounselorRequest request) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundImage: _getImageProviderFromString(
                    request.userProfileImageUrl,
                  ),
                  child:
                      request.userProfileImageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    request.status.displayName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 상세 정보
            _buildInfoRow('전문 분야', request.specialties.join(', ')),
            _buildInfoRow('경력', '${request.experienceYears}년'),
            _buildInfoRow('자격증/학력', request.qualifications.join(', ')),
            _buildInfoRow('상담 방식', request.preferredMethod.displayName),
            _buildInfoRow('상담 비용', '${request.price.consultationFeeText}'),
            _buildInfoRow('가능한 시간', '${request.availableTimes.length}개 시간대'),

            SizedBox(height: 12.h),

            // 소개
            Text(
              '소개',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text(
              request.introduction,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),

            // 거부 사유 (거부된 경우)
            if (request.status == CounselorRequestStatus.rejected &&
                request.rejectionReason != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '거부 사유',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      request.rejectionReason!,
                      style: TextStyle(fontSize: 14.sp, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],

            // 승인/거부 버튼 (대기 중인 경우만)
            if (request.status == CounselorRequestStatus.pending) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: '승인',
                      onPressed: () => _handleApproval(request, true),
                      type: ButtonType.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomButton(
                      text: '거부',
                      onPressed: () => _handleApproval(request, false),
                      type: ButtonType.outline,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 8.h),
            Text(
              '요청일: ${_formatDate(request.createdAt)}',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CounselorRequestStatus status) {
    switch (status) {
      case CounselorRequestStatus.pending:
        return AppColors.warning;
      case CounselorRequestStatus.approved:
        return AppColors.success;
      case CounselorRequestStatus.rejected:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
