import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/models/record_model.dart';
import '../../providers/records_provider.dart';

class RecordCreateScreen extends ConsumerStatefulWidget {
  final String? counselorId;
  final String? counselorName;
  final RecordType? initialType;

  const RecordCreateScreen({
    super.key,
    this.counselorId,
    this.counselorName,
    this.initialType,
  });

  @override
  ConsumerState<RecordCreateScreen> createState() => _RecordCreateScreenState();
}

class _RecordCreateScreenState extends ConsumerState<RecordCreateScreen>
    with TickerProviderStateMixin {
  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 폼 컨트롤러들
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _tagsController = TextEditingController();

  // 상태 변수들
  bool _isCreating = false;
  RecordType _selectedType = RecordType.ai;
  DateTime _sessionDate = DateTime.now();
  int _durationMinutes = 30;
  double _rating = 3.0;
  List<String> _tags = [];
  List<RecordAttachment> _attachments = [];

  // 페이지 컨트롤
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeData() {
    // 초기값 설정
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }

    // 상담사 정보가 있으면 전문 상담으로 설정
    if (widget.counselorId != null && widget.counselorName != null) {
      _selectedType = RecordType.counselor;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _feedbackController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: '새 기록 작성',
        actions: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              child: Text(
                '이전',
                style: TextStyle(color: AppColors.primary, fontSize: 14.sp),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // === 진행률 표시 ===
              _buildProgressIndicator(),

              // === 페이지 내용 ===
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    _buildBasicInfoPage(), // 1단계: 기본 정보
                    _buildContentPage(), // 2단계: 상담 내용
                    _buildAdditionalPage(), // 3단계: 추가 정보
                  ],
                ),
              ),

              // === 하단 버튼 ===
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentPage + 1) / _totalPages;

    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentPage + 1}/$_totalPages 단계',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% 완료',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  // === 1단계: 기본 정보 ===
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 페이지 제목 ===
            _buildPageHeader(title: '기본 정보', subtitle: '상담의 기본 정보를 입력해주세요'),

            SizedBox(height: 24.h),

            // === 상담 유형 선택 ===
            _buildRecordTypeSection(),

            SizedBox(height: 20.h),

            // === 제목 입력 ===
            _buildTitleSection(),

            SizedBox(height: 20.h),

            // === 날짜/시간 설정 ===
            _buildDateTimeSection(),

            SizedBox(height: 20.h),

            // === 상담 시간 설정 ===
            _buildDurationSection(),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // === 2단계: 상담 내용 ===
  Widget _buildContentPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 페이지 제목 ===
          _buildPageHeader(title: '상담 내용', subtitle: '상담에서 나눈 내용을 기록해주세요'),

          SizedBox(height: 24.h),

          // === 요약 입력 ===
          _buildSummarySection(),

          SizedBox(height: 20.h),

          // === 상세 내용 입력 ===
          _buildDetailContentSection(),

          SizedBox(height: 20.h),

          // === 태그 입력 ===
          _buildTagsSection(),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // === 3단계: 추가 정보 ===
  Widget _buildAdditionalPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 페이지 제목 ===
          _buildPageHeader(title: '추가 정보', subtitle: '만족도와 피드백을 입력해주세요'),

          SizedBox(height: 24.h),

          // === 만족도 평가 ===
          _buildRatingSection(),

          SizedBox(height: 20.h),

          // === 피드백 입력 ===
          _buildFeedbackSection(),

          SizedBox(height: 20.h),

          // === 첨부파일 ===
          _buildAttachmentSection(),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildPageHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordTypeSection() {
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
            '상담 유형',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children:
                RecordType.values
                    .where((type) => type != RecordType.all)
                    .map((type) => _buildTypeChip(type))
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(RecordType type) {
    final isSelected = _selectedType == type;
    final isDisabled =
        widget.counselorId != null && type != RecordType.counselor;

    return GestureDetector(
      onTap:
          isDisabled
              ? null
              : () {
                setState(() => _selectedType = type);
              },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? type.color.withOpacity(0.1)
                  : isDisabled
                  ? AppColors.grey100
                  : AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? type.color
                    : isDisabled
                    ? AppColors.grey200
                    : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              color:
                  isSelected
                      ? type.color
                      : isDisabled
                      ? AppColors.grey400
                      : AppColors.textSecondary,
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 14.sp,
                color:
                    isSelected
                        ? type.color
                        : isDisabled
                        ? AppColors.grey400
                        : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
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
            '제목',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _titleController,
            hintText: '상담 기록의 제목을 입력하세요',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
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
            '상담 날짜 및 시간',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _selectDateTime,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _formatDateTime(_sessionDate),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16.w,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
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
            '상담 시간',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _durationMinutes.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 21, // (120-15)/5 = 21
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.grey200,
                  onChanged: (value) {
                    setState(() => _durationMinutes = value.round());
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${_durationMinutes}분',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
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
              Icon(Icons.summarize, color: AppColors.primary, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '요약',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '상담 내용을 간단히 요약해주세요',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _summaryController,
            hintText: '예: 경기 전 불안감에 대해 상담하고 호흡법을 배웠습니다',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '요약을 입력해주세요';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContentSection() {
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
              Icon(Icons.article, color: AppColors.textSecondary, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '상세 내용',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '상담에서 나눈 대화나 배운 내용을 자세히 기록해주세요 (선택사항)',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _contentController,
            hintText: '상담 과정에서 나눈 대화, 배운 기법, 느낀 점 등을 자유롭게 작성하세요',
            maxLines: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
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
              Icon(Icons.tag, color: AppColors.secondary, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '태그',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '쉼표(,)로 구분하여 태그를 입력하세요',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _tagsController,
            hintText: '경기불안, 호흡법, 집중력, 자신감',
            onChanged: _updateTags,
          ),
          if (_tags.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  _tags
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
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
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
            '만족도 평가',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '이번 상담에 대한 만족도를 평가해주세요',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 20.h),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _rating = (index + 1).toDouble());
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 32.w,
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 12.h),
                Text(
                  '${_rating.toInt()}점',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _getRatingText(_rating),
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

  Widget _buildFeedbackSection() {
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
              Icon(Icons.feedback, color: AppColors.success, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '피드백',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '상담에 대한 개인적인 생각이나 느낌을 적어주세요 (선택사항)',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _feedbackController,
            hintText: '상담이 도움이 되었던 점, 개선하고 싶은 점, 다음에 해보고 싶은 것 등',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
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
              if (_attachments.isNotEmpty)
                Text(
                  '${_attachments.length}개',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '상담과 관련된 파일을 첨부할 수 있습니다 (선택사항)',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),

          // === 첨부파일 추가 버튼들 ===
          Row(
            children: [
              Expanded(
                child: _buildAttachmentButton(
                  icon: Icons.image,
                  label: '이미지',
                  color: AppColors.info,
                  onTap: () => _addAttachment(AttachmentType.image),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildAttachmentButton(
                  icon: Icons.audiotrack,
                  label: '오디오',
                  color: AppColors.success,
                  onTap: () => _addAttachment(AttachmentType.audio),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildAttachmentButton(
                  icon: Icons.description,
                  label: '문서',
                  color: AppColors.warning,
                  onTap: () => _addAttachment(AttachmentType.document),
                ),
              ),
            ],
          ),

          // === 첨부된 파일 목록 ===
          if (_attachments.isNotEmpty) ...[
            SizedBox(height: 16.h),
            ..._attachments.map(
              (attachment) => _buildAttachmentItem(attachment),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.w),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
            child: Text(
              attachment.fileName,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _removeAttachment(attachment),
            icon: Icon(Icons.close, color: AppColors.error, size: 18.w),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
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

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentPage < _totalPages - 1) ...[
              Expanded(
                child: CustomButton(
                  text: '다음',
                  onPressed: _nextPage,
                  type: ButtonType.primary,
                  icon: Icons.arrow_forward,
                ),
              ),
            ] else ...[
              Expanded(
                child: CustomButton(
                  text: '기록 저장',
                  onPressed: _isCreating ? null : _saveRecord,
                  isLoading: _isCreating,
                  type: ButtonType.primary,
                  icon: Icons.save,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // === 이벤트 핸들러들 ===

  void _nextPage() {
    if (_currentPage == 0) {
      // 1단계 유효성 검사
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else if (_currentPage == 1) {
      // 2단계 유효성 검사
      if (_summaryController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('요약을 입력해주세요'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_sessionDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
                surface: AppColors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _sessionDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _updateTags(String value) {
    final tags =
        value
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
    setState(() => _tags = tags);
  }

  void _addAttachment(AttachmentType type) {
    // 실제 파일 선택 기능은 준비 중 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type.displayName} 첨부 기능은 준비 중입니다'),
        backgroundColor: AppColors.info,
      ),
    );

    // Mock 첨부파일 추가 (개발용)
    final mockAttachment = RecordAttachment(
      id: 'attachment_${DateTime.now().millisecondsSinceEpoch}',
      recordId: '',
      type: type,
      fileName:
          '${type.displayName}_${DateTime.now().millisecondsSinceEpoch}.${_getFileExtension(type)}',
      fileUrl: '',
      fileSize: 1024 * 1024, // 1MB
      uploadedAt: DateTime.now(),
    );

    setState(() {
      _attachments.add(mockAttachment);
    });
  }

  void _removeAttachment(RecordAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    if (_summaryController.text.trim().isEmpty) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('요약을 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final request = CreateRecordRequest(
        type: _selectedType,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        content:
            _contentController.text.trim().isEmpty
                ? null
                : _contentController.text.trim(),
        counselorId: widget.counselorId,
        sessionDate: _sessionDate,
        durationMinutes: _durationMinutes,
        rating: _rating,
        feedback:
            _feedbackController.text.trim().isEmpty
                ? null
                : _feedbackController.text.trim(),
        tags: _tags,
      );

      final success = await ref
          .read(recordsProvider.notifier)
          .createRecord(request);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상담 기록이 저장되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );

        // 기록 목록으로 이동
        context.go(AppRoutes.recordsList);
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  // === 헬퍼 메서드들 ===

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return '매우 불만족';
      case 2:
        return '불만족';
      case 3:
        return '보통';
      case 4:
        return '만족';
      case 5:
        return '매우 만족';
      default:
        return '보통';
    }
  }

  String _getFileExtension(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return 'jpg';
      case AttachmentType.audio:
        return 'mp3';
      case AttachmentType.document:
        return 'pdf';
      case AttachmentType.video:
        return 'mp4';
    }
  }
}

// CreateRecordRequest는 record_model.dart에 이미 정의되어 있으므로 제거
