import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../core/config/app_routes.dart';
import '../../providers/counselor_provider.dart';
import '../../shared/models/counselor_model.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/theme_aware_widgets.dart';

class CounselorDetailScreen extends ConsumerStatefulWidget {
  final String counselorId;
  const CounselorDetailScreen({super.key, required this.counselorId});

  @override
  ConsumerState<CounselorDetailScreen> createState() =>
      _CounselorDetailScreenState();
}

class _CounselorDetailScreenState extends ConsumerState<CounselorDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerAnimationController.forward();

    // 상담사 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(counselorDetailProvider(widget.counselorId).notifier)
          .loadCounselorDetail();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(counselorDetailProvider(widget.counselorId));
    final counselor = detailState.counselor;

    return ThemedScaffold(
      body:
          detailState.isLoading
              ? const LoadingWidget()
              : detailState.error != null
              ? _buildErrorScreen(detailState.error!)
              : counselor == null
              ? _buildNotFoundScreen()
              : _buildContent(counselor, detailState),
      appBar: CustomAppBar(title: counselor?.name ?? '상담사 정보'),
    );
  }

  Widget _buildContent(Counselor counselor, dynamic detailState) {
    return Stack(
      children: [
        // 배경 그라데이션
        Container(
          height: 300.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.primary.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // 메인 콘텐츠
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 상단 AppBar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: context.surfaceColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: context.textColor,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // 프로필 헤더
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerAnimation,
                child: _buildModernHeader(counselor),
              ),
            ),

            // 탭과 콘텐츠
            SliverFillRemaining(
              child: Column(
                children: [
                  _buildModernTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(counselor),
                        _buildReviewsTab(),
                        _buildScheduleTab(counselor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 하단 예약 버튼
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildModernBottomBar(counselor),
        ),
      ],
    );
  }

  Widget _buildModernHeader(Counselor counselor) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 80.h, 20.w, 20.h),
      child: Column(
        children: [
          // 프로필 이미지와 기본 정보
          Stack(
            children: [
              // 배경 카드
              Container(
                margin: EdgeInsets.only(top: 50.h),
                padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 24.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),

                    // 이름과 타이틀
                    ThemedText(
                      text: counselor.name,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    SizedBox(height: 6.h),

                    ThemedText(
                      text: counselor.title,
                      isPrimary: false,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // 평점과 상담 횟수
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18.sp),
                          SizedBox(width: 6.w),
                          ThemedText(
                            text: counselor.ratingText,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            width: 1.w,
                            height: 14.h,
                            color: context.secondaryTextColor.withOpacity(0.3),
                          ),
                          SizedBox(width: 8.w),
                          ThemedText(
                            text: '${counselor.reviewCount}+ 상담',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // 전문 분야 태그들
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          counselor.specialties.map((specialty) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    context.isDarkMode
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant
                                        : Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color:
                                      context.isDarkMode
                                          ? Colors.transparent
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withOpacity(0.2),
                                ),
                              ),
                              child: ThemedText(
                                text: specialty,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              // 프로필 이미지 (위에 떠있는 형태)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50.r),
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.surfaceColor,
                            width: 4.w,
                          ),
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        child: _buildCounselorImage(counselor.profileImageUrl),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorImage(String? imageUrl) {
    final imageWidget =
        (imageUrl != null && imageUrl.isNotEmpty)
            ? (imageUrl.startsWith('/') || imageUrl.startsWith('file://'))
                ? FileImage(File(imageUrl))
                : NetworkImage(imageUrl) as ImageProvider
            : null;

    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.r),
        color:
            context.isDarkMode
                ? Theme.of(context).colorScheme.surfaceVariant
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
      child:
          imageWidget != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child: Image(
                  image: imageWidget,
                  fit: BoxFit.cover,
                  width: 100.w,
                  height: 100.w,
                ),
              )
              : Icon(
                Icons.person,
                size: 50.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
    );
  }

  Widget _buildModernTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color:
            context.isDarkMode
                ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor:
            context.isDarkMode
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
        unselectedLabelColor: context.textColor,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Theme.of(context).colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 18.sp),
                SizedBox(width: 6.w),
                const Text('정보'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 18.sp),
                SizedBox(width: 6.w),
                const Text('리뷰'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_outlined, size: 18.sp),
                SizedBox(width: 6.w),
                const Text('스케줄'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Counselor counselor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildModernInfoCard(
            icon: Icons.person_outline,
            title: '소개',
            content: counselor.title,
            color: Theme.of(context).colorScheme.primary,
          ),

          SizedBox(height: 16.h),

          _buildModernInfoCard(
            icon: Icons.work_outline,
            title: '경력',
            content: counselor.experienceText,
            color: Theme.of(context).colorScheme.secondary,
          ),

          if (counselor.qualifications.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildModernInfoCard(
              icon: Icons.military_tech_outlined,
              title: '주요 자격증',
              content: counselor.qualifications.map((q) => '• $q').join('\n'),
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ],

          SizedBox(height: 100.h), // 하단 바 공간
        ],
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color:
              context.isDarkMode ? Colors.transparent : color.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              ThemedText(
                text: title,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          ThemedText(
            text: content,
            isPrimary: false,
            style: TextStyle(fontSize: 15.sp, height: 1.6, letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final reviewsState = ref.watch(
      counselorReviewsProvider(widget.counselorId),
    );

    if (reviewsState.isLoading) {
      return const LoadingWidget();
    }

    if (reviewsState.reviews.isEmpty) {
      return _buildEmptyState(
        icon: Icons.rate_review_outlined,
        title: '아직 작성된 리뷰가 없습니다',
        subtitle: '첫 번째 리뷰를 남겨보세요!',
      );
    }

    // 리뷰 리스트 UI (실제 데이터 사용)
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          ...reviewsState.reviews.map(
            (review) => _buildModernReviewCard(review),
          ),
          SizedBox(height: 100.h), // 하단 바 공간
        ],
      ),
    );
  }

  Widget _buildModernReviewCard(dynamic review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color:
              context.isDarkMode
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리뷰어 정보와 평점
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.sp,
                ),
              ),

              SizedBox(width: 12.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemedText(
                      text: review.userName ?? '익명',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review.rating ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 14.sp,
                          );
                        }),
                        SizedBox(width: 8.w),
                        ThemedText(
                          text: _formatReviewDate(review.createdAt),
                          isPrimary: false,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 리뷰 내용
          ThemedText(
            text: review.content ?? '',
            isPrimary: false,
            style: TextStyle(fontSize: 14.sp, height: 1.5, letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Widget _buildScheduleTab(Counselor counselor) {
    // availableTimes를 요일별로 그룹핑
    final Map<String, List<String>> scheduleMap = {};
    for (final time in counselor.availableTimes) {
      if (time.isAvailable) {
        scheduleMap.putIfAbsent(time.dayOfWeek, () => []);
        scheduleMap[time.dayOfWeek]!.add('${time.startTime} ~ ${time.endTime}');
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // 스케줄 헤더
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color:
                    context.isDarkMode
                        ? Colors.transparent
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    ThemedText(
                      text: '예약 가능 시간',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ThemedText(
                  text: '상담사의 예약 가능한 시간을 확인하고 예약하세요.',
                  isPrimary: false,
                  style: TextStyle(fontSize: 14.sp, height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          if (scheduleMap.isNotEmpty) ...[
            ...scheduleMap.entries.map((entry) {
              return _buildScheduleCard(entry.key, entry.value);
            }),
          ] else ...[
            _buildEmptyState(
              icon: Icons.schedule_outlined,
              title: '예약 가능한 시간이 없습니다',
              subtitle: '상담사에게 문의해보세요',
            ),
          ],
          if (scheduleMap.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ThemedText(
                      text: '예약은 최소 24시간 전에 가능하며, 상담사 승인 후 확정됩니다.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 100.h), // 하단 바 공간
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String day, List<String> timeSlots) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              context.isDarkMode
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color:
                      timeSlots.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : context.secondaryTextColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              ThemedText(
                text: day,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (timeSlots.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: context.secondaryTextColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: ThemedText(
                    text: '휴무',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          if (timeSlots.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  timeSlots.map((time) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ThemedText(
                        text: time,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: Icon(
                icon,
                size: 40.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            SizedBox(height: 24.h),

            ThemedText(
              text: title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8.h),

            ThemedText(
              text: subtitle,
              isPrimary: false,
              style: TextStyle(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomBar(Counselor counselor) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 가격 정보
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThemedText(
                    text: '상담료',
                    isPrimary: false,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      ThemedText(
                        text: '${counselor.price.consultationFee}',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      ThemedText(
                        text: '원',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 16.w),

            // 예약 버튼
            Expanded(
              flex: 3,
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      '${AppRoutes.bookingCalendar}/${counselor.id}',
                      extra: counselor,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  label: Text(
                    '예약하기',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) => Center(
    child: Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40.sp,
              color: Theme.of(context).colorScheme.error,
            ),
          ),

          SizedBox(height: 24.h),

          ThemedText(
            text: '오류가 발생했습니다',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          ThemedText(
            text: error,
            isPrimary: false,
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 32.h),

          CustomButton(
            onPressed:
                () =>
                    ref
                        .read(
                          counselorDetailProvider(widget.counselorId).notifier,
                        )
                        .loadCounselorDetail(),
            text: '다시 시도',
          ),
        ],
      ),
    ),
  );

  Widget _buildNotFoundScreen() => Center(
    child: _buildEmptyState(
      icon: Icons.person_off_outlined,
      title: '상담사를 찾을 수 없습니다',
      subtitle: '다른 상담사를 찾아보세요',
    ),
  );
}
