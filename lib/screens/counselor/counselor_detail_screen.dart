import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/models/counselor_model.dart';
import '../../providers/counselor_provider.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 상담사 정보 로드
    ref
        .read(counselorDetailProvider(widget.counselorId).notifier)
        .loadCounselorDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(counselorDetailProvider(widget.counselorId));
    final reviewsState = ref.watch(
      counselorReviewsProvider(widget.counselorId),
    );

    if (detailState.isLoading) return _buildLoadingScreen();
    if (detailState.error != null) return _buildErrorScreen(detailState.error!);
    if (detailState.counselor == null) return _buildNotFoundScreen();

    final counselor = detailState.counselor!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder:
              (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _buildHeader(counselor)),
              ],
          body: Column(
            children: [
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(counselor),
                    _buildReviewsTab(reviewsState),
                    _buildScheduleTab(counselor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(counselor),
    );
  }

  Widget _buildLoadingScreen() => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _buildErrorScreen(String error) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('오류: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () =>
                    ref
                        .read(
                          counselorDetailProvider(widget.counselorId).notifier,
                        )
                        .loadCounselorDetail(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    ),
  );

  Widget _buildNotFoundScreen() => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: const Center(child: Text('상담사를 찾을 수 없습니다')),
  );

  Widget _buildHeader(Counselor counselor) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          Row(
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage:
                    (counselor.profileImageUrl != null &&
                            counselor.profileImageUrl!.isNotEmpty)
                        ? (counselor.profileImageUrl!.startsWith('/')
                            ? FileImage(File(counselor.profileImageUrl!))
                            : NetworkImage(counselor.profileImageUrl!)
                                as ImageProvider)
                        : null,
                child:
                    (counselor.profileImageUrl == null ||
                            counselor.profileImageUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            counselor.name,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (counselor.isOnline)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: const Text(
                              '온라인',
                              style: TextStyle(color: AppColors.success),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      counselor.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '${counselor.ratingText} · ${counselor.reviewCount}+ 상담',
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
          SizedBox(height: 16.h),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabController,
      tabs: const [Tab(text: '정보'), Tab(text: '리뷰'), Tab(text: '스케줄')],
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
    ),
  );

  Widget _buildInfoTab(Counselor counselor) => SingleChildScrollView(
    padding: EdgeInsets.all(20.w),
    child: Column(
      children: [
        _card(child: _buildBasicInfo(counselor)),
        SizedBox(height: 16.h),
        _card(child: _buildSpecialties(counselor)),
        SizedBox(height: 16.h),
        _card(child: _buildIntro(counselor)),
        SizedBox(height: 16.h),
        _card(child: _buildQualifications(counselor)),
        SizedBox(height: 16.h),
        _card(child: _buildPrice(counselor)),
      ],
    ),
  );

  Widget _buildReviewsTab(CounselorReviewsState reviewsState) {
    if (reviewsState.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (reviewsState.error != null)
      return Center(child: Text('오류: ${reviewsState.error}'));
    if (reviewsState.reviews.isEmpty)
      return const Center(child: Text('아직 리뷰가 없습니다'));

    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount: reviewsState.reviews.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final review = reviewsState.reviews[index];
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    child: Text(review.userName?[0] ?? 'U'),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName ?? '익명',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(review.content),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleTab(Counselor counselor) => SingleChildScrollView(
    padding: EdgeInsets.all(20.w),
    child: Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '예약 가능 시간',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...counselor.availableTimes.map(
                (time) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        [
                              Text(time.dayOfWeek),
                              Text('${time.startTime} - ${time.endTime}'),
                              time.isAvailable
                                  ? const Chip(label: Text('가능'))
                                  : null,
                            ]
                            .where((widget) => widget != null)
                            .cast<Widget>()
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildBasicInfo(Counselor counselor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '기본 정보',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Text('경력: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${counselor.experienceYears}년'),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('상담 횟수: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${counselor.consultationCount}회'),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('언어: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(counselor.languages.join(', ')),
        ],
      ),
    ],
  );

  Widget _buildSpecialties(Counselor counselor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '전문 분야',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        children:
            counselor.specialties.map((s) => Chip(label: Text(s))).toList(),
      ),
    ],
  );

  Widget _buildIntro(Counselor counselor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '소개',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Text(counselor.introduction),
    ],
  );

  Widget _buildQualifications(Counselor counselor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '자격 및 학력',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      ...counselor.qualifications.map(
        (q) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const Text('• '), Expanded(child: Text(q))],
          ),
        ),
      ),
    ],
  );

  Widget _buildPrice(Counselor counselor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '상담료',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Text(
        '${counselor.price.consultationFee}원/50분',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      if (counselor.price.packageFee != null) ...[
        const SizedBox(height: 8),
        Text(
          '패키지: ${counselor.price.packageFee}원',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
      if (counselor.price.groupFee != null) ...[
        const SizedBox(height: 8),
        Text(
          '그룹: ${counselor.price.groupFee}원',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ],
  );

  Widget _buildBottomBar(Counselor counselor) => Container(
    padding: EdgeInsets.all(20.w),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
    ),
    child: SafeArea(
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '상담료',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${counselor.price.consultationFee}원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: '예약하기',
              onPressed:
                  () => context.push(
                    '${AppRoutes.bookingCalendar}/${counselor.id}',
                  ), // 🔥 수정됨: 쿼리 파라미터 → 패스 파라미터
            ),
          ),
        ],
      ),
    ),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    ),
    child: child,
  );
}
