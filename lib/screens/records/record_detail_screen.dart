import 'package:flutter/material.dart';
import 'package:flutter_mentalfit/shared/services/records_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/record_model.dart';
import '../../providers/records_provider.dart';

// RecordDetailState 정의
class RecordDetailState {
  final CounselingRecord? record;
  final bool isLoading;
  final String? error;

  const RecordDetailState({this.record, this.isLoading = false, this.error});

  RecordDetailState copyWith({
    CounselingRecord? record,
    bool? isLoading,
    String? error,
  }) {
    return RecordDetailState(
      record: record ?? this.record,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// RecordDetailNotifier 정의
class RecordDetailNotifier extends StateNotifier<RecordDetailState> {
  RecordDetailNotifier(this.recordId) : super(const RecordDetailState());

  final String recordId;
  late RecordsService _recordsService;

  Future<void> loadRecord(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Mock 데이터 사용 (실제로는 RecordsService 사용)
      await Future.delayed(const Duration(milliseconds: 500));

      final mockRecords = _getMockRecords();
      final record = mockRecords.firstWhere(
        (r) => r.id == id,
        orElse: () => mockRecords.first,
      );

      state = state.copyWith(record: record, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<CounselingRecord> _getMockRecords() {
    final now = DateTime.now();
    return [
      CounselingRecord(
        id: 'record_1',
        userId: 'user_123',
        type: RecordType.ai,
        title: 'AI 상담 - 경기 전 불안감',
        summary: '내일 중요한 경기가 있어서 너무 긴장되고 불안해요. 실수할까봐 걱정이 많습니다.',
        content: '''오늘 AI 상담을 통해 경기 전 불안감에 대해 이야기했습니다.

주요 내용:
- 경기 전 긴장과 불안은 자연스러운 반응
- 호흡법과 시각화 기법 학습
- 긍정적 자기 대화의 중요성

다음 실천 사항:
1. 경기 1시간 전 호흡 명상 10분
2. 성공적인 경기 장면 시각화
3. "나는 충분히 준비했다" 반복하기

느낀 점:
불안감이 완전히 사라지지는 않았지만, 이를 관리할 수 있는 구체적인 방법을 배웠습니다.''',
        sessionDate: now.subtract(const Duration(days: 2)),
        durationMinutes: 45,
        rating: 4.5,
        feedback: '구체적인 방법을 알려줘서 도움이 되었어요.',
        tags: ['경기불안', '호흡법', '시각화'],
        attachments: [],
        status: RecordStatus.completed,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

// Provider 정의
final recordDetailProvider = StateNotifierProvider.family<
  RecordDetailNotifier,
  RecordDetailState,
  String
>((ref, recordId) => RecordDetailNotifier(recordId));

final recordsByTagProvider = Provider.family<List<CounselingRecord>, String>((
  ref,
  tag,
) {
  // Mock 데이터 반환
  final now = DateTime.now();
  return [
    CounselingRecord(
      id: 'record_similar_1',
      userId: 'user_123',
      type: RecordType.ai,
      title: 'AI 상담 - 집중력 향상',
      summary: '경기 중 집중력이 떨어지는 문제를 상담했습니다.',
      sessionDate: now.subtract(const Duration(days: 5)),
      durationMinutes: 30,
      rating: 4.0,
      tags: [tag],
      attachments: [],
      status: RecordStatus.completed,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
  ];
});

class RecordDetailScreen extends ConsumerStatefulWidget {
  final String recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  ConsumerState<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen>
    with TickerProviderStateMixin {
  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;

  bool _isDeleting = false;
  bool _isContentExpanded = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // 기록 상세 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(recordDetailProvider(widget.recordId).notifier)
          .loadRecord(widget.recordId);
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordDetailState = ref.watch(recordDetailProvider(widget.recordId));

    debugPrint('Record Detail State: ${recordDetailState.toString()}');
    debugPrint('Record ID: ${widget.recordId}');
    debugPrint('Is Loading: ${recordDetailState.isLoading}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: '상담 기록',
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _handleShare),
          if (recordDetailState.record != null)
            IconButton(icon: const Icon(Icons.edit), onPressed: _handleEdit),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildContent(recordDetailState),
      ),
    );
  }

  Widget _buildContent(RecordDetailState state) {
    if (state.isLoading) {
      return const LoadingWidget();
    } else if (state.error != null) {
      return _buildErrorState(state.error!);
    } else if (state.record == null) {
      return _buildNotFoundState();
    } else {
      return _buildRecordDetail(state.record!);
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              '오류가 발생했습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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
              onPressed: () {
                ref
                    .read(recordDetailProvider(widget.recordId).notifier)
                    .loadRecord(widget.recordId);
              },
              type: ButtonType.primary,
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
            Icon(Icons.search_off, size: 64.w, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              '기록을 찾을 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '삭제되었거나 존재하지 않는 기록입니다',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: '목록으로 돌아가기',
              onPressed: () => context.pop(),
              type: ButtonType.primary,
              icon: Icons.arrow_back,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordDetail(CounselingRecord record) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // === 헤더 섹션 ===
          FadeTransition(opacity: _cardAnimation, child: _buildHeader(record)),

          SizedBox(height: 20.h),

          // === 상담사 정보 섹션 (전문 상담인 경우만) ===
          if (record.counselorName != null)
            FadeTransition(
              opacity: _cardAnimation,
              child: _buildCounselorInfo(record),
            ),

          if (record.counselorName != null) SizedBox(height: 20.h),

          // === 상담 내용 섹션 ===
          FadeTransition(
            opacity: _cardAnimation,
            child: _buildContentSection(record),
          ),

          SizedBox(height: 20.h),

          // === 첨부파일 섹션 ===
          if (record.attachments.isNotEmpty)
            FadeTransition(
              opacity: _cardAnimation,
              child: _buildAttachments(record.attachments),
            ),

          if (record.attachments.isNotEmpty) SizedBox(height: 20.h),

          // === 비슷한 기록 섹션 ===
          if (record.tags.isNotEmpty)
            FadeTransition(
              opacity: _cardAnimation,
              child: _buildSimilarRecords(record.tags.first),
            ),

          if (record.tags.isNotEmpty) SizedBox(height: 20.h),

          // === 액션 버튼들 ===
          FadeTransition(opacity: _cardAnimation, child: _buildActionButtons()),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildHeader(CounselingRecord record) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 상담 유형 + 제목 ===
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: record.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  record.type.icon,
                  color: record.type.color,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.type.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: record.type.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      record.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // === 날짜 + 시간 정보 ===
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.textSecondary,
                  size: 16.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  record.detailDateText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  record.durationText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // === 평점 (별점) ===
          if (record.rating != null) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Text(
                  '만족도',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 12.w),
                _buildRatingStars(record.rating!),
                SizedBox(width: 8.w),
                Text(
                  record.ratingText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: AppColors.warning,
          size: 16.sp,
        );
      }),
    );
  }

  Widget _buildCounselorInfo(CounselingRecord record) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상담사 정보',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Icon(Icons.person, color: AppColors.success, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.counselorName!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '전문 상담사',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // 상담사 상세 화면으로 이동
                  if (record.counselorId != null) {
                    context.push(
                      '${AppRoutes.counselorDetail}/${record.counselorId}',
                    );
                  }
                },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(CounselingRecord record) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상담 내용',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // === 요약 ===
          _buildSummary(record.summary),

          SizedBox(height: 16.h),

          // === 상세 내용 ===
          if (record.content != null) _buildDetailContent(record.content!),

          // === 태그들 ===
          if (record.tags.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildTags(record.tags),
          ],

          // === 사용자 피드백 ===
          if (record.feedback != null) ...[
            SizedBox(height: 16.h),
            _buildFeedback(record.feedback!),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(String summary) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: AppColors.primary, size: 16.w),
              SizedBox(width: 6.w),
              Text(
                '요약',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            summary,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(String content) {
    final isLongContent = content.length > 200;
    final displayContent =
        _isContentExpanded || !isLongContent
            ? content
            : '${content.substring(0, 200)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article, color: AppColors.textSecondary, size: 16.w),
            SizedBox(width: 6.w),
            Text(
              '상세 내용',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          displayContent,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
        if (isLongContent) ...[
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _toggleContentExpansion,
            child: Text(
              _isContentExpanded ? '접기' : '더보기',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTags(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag, color: AppColors.textSecondary, size: 16.w),
            SizedBox(width: 6.w),
            Text(
              '태그',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children:
              tags
                  .map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildFeedback(String feedback) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.success.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.feedback, color: AppColors.success, size: 16.w),
              SizedBox(width: 6.w),
              Text(
                '피드백',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(List<RecordAttachment> attachments) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: AppColors.textPrimary, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '첨부파일',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${attachments.length}개',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...attachments.map((attachment) => _buildAttachmentItem(attachment)),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(RecordAttachment attachment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Row(
        children: [
          _getAttachmentIcon(attachment.type),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    if (attachment.fileSize != null) ...[
                      Text(
                        attachment.fileSizeText,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      attachment.uploadedAt.toString().substring(0, 16),
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
          IconButton(
            onPressed: () => _handleDownloadAttachment(attachment),
            icon: Icon(Icons.download, color: AppColors.primary, size: 20.w),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAttachmentIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icon(Icons.image, color: AppColors.info, size: 20.sp);
      case AttachmentType.audio:
        return Icon(Icons.audiotrack, color: AppColors.success, size: 20.sp);
      case AttachmentType.document:
        return Icon(Icons.description, color: AppColors.warning, size: 20.sp);
      case AttachmentType.video:
        return Icon(Icons.videocam, color: AppColors.error, size: 20.sp);
    }
  }

  Widget _buildSimilarRecords(String tag) {
    final similarRecords = ref.watch(recordsByTagProvider(tag));

    if (similarRecords.isEmpty || similarRecords.length <= 1) {
      return const SizedBox.shrink();
    }

    // 현재 기록 제외
    final otherRecords =
        similarRecords
            .where((record) => record.id != widget.recordId)
            .take(3)
            .toList();

    if (otherRecords.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.textPrimary, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '비슷한 기록',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...otherRecords.map((record) => _buildSimilarRecordItem(record)),
        ],
      ),
    );
  }

  Widget _buildSimilarRecordItem(CounselingRecord record) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: record.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(record.type.icon, color: record.type.color, size: 16.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  record.dateText,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.push('${AppRoutes.recordDetail}/${record.id}');
            },
            icon: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 14.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: '수정하기',
            onPressed: _handleEdit,
            type: ButtonType.secondary,
            icon: Icons.edit,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomButton(
            text: '삭제하기',
            onPressed: _isDeleting ? null : _handleDelete,
            isLoading: _isDeleting,
            type: ButtonType.outline,
            icon: Icons.delete,
          ),
        ),
      ],
    );
  }

  // === 이벤트 핸들러들 ===

  void _handleEdit() {
    // 수정 화면으로 이동 (아직 구현되지 않았으므로 준비 중 메시지)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('기록 수정 기능은 준비 중입니다'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await _showDeleteDialog();
    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      final success = await ref
          .read(recordsProvider.notifier)
          .deleteRecord(widget.recordId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 삭제되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('공유 기능은 준비 중입니다'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _handleDownloadAttachment(RecordAttachment attachment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${attachment.fileName} 다운로드 준비 중입니다'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<bool> _showDeleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning, size: 24.w),
                SizedBox(width: 8.w),
                const Text('기록 삭제'),
              ],
            ),
            content: Text(
              '이 상담 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(
                  '삭제',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  void _toggleContentExpansion() {
    setState(() {
      _isContentExpanded = !_isContentExpanded;
    });
  }
}
