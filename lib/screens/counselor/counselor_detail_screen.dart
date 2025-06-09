import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/models/counselor_model.dart';
import '../../providers/counselor_provider.dart';
import '../../providers/booking_provider.dart';

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
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBookingDialog() {
    showDialog(context: context, builder: (context) => _buildBookingDialog());
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(counselorDetailProvider(widget.counselorId));
    final reviewsState = ref.watch(
      counselorReviewsProvider(widget.counselorId),
    );

    if (detailState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (detailState.counselor == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16.h),
              Text(
                '상담사 정보를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final counselor = detailState.counselor!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 320.h,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    detailState.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color:
                        detailState.isFavorite
                            ? AppColors.error
                            : AppColors.textSecondary,
                  ),
                  onPressed:
                      () =>
                          ref
                              .read(
                                counselorDetailProvider(
                                  widget.counselorId,
                                ).notifier,
                              )
                              .toggleFavorite(),
                ),
                IconButton(
                  icon: Icon(Icons.share, color: AppColors.textSecondary),
                  onPressed: () {
                    // TODO: 공유 기능 구현
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(counselor),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // === 탭 바 ===
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: '정보'), Tab(text: '리뷰'), Tab(text: '예약')],
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),

            // === 탭 내용 ===
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(counselor),
                  _buildReviewsTab(reviewsState),
                  _buildBookingTab(counselor),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(counselor),
    );
  }

  Widget _buildHeader(Counselor counselor) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 100.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // === 프로필 이미지 ===
              CircleAvatar(
                radius: 40.r,
                backgroundColor: AppColors.grey200,
                backgroundImage:
                    counselor.profileImageUrl != null
                        ? NetworkImage(counselor.profileImageUrl!)
                        : null,
                child:
                    counselor.profileImageUrl == null
                        ? Icon(
                          Icons.person,
                          size: 40.sp,
                          color: AppColors.textSecondary,
                        )
                        : null,
              ),

              SizedBox(width: 20.w),

              // === 기본 정보 ===
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          counselor.name,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (counselor.isOnline)
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: const BoxDecoration(
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
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // === 평점과 리뷰 ===
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < counselor.rating.floor()
                                  ? Icons.star
                                  : index < counselor.rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                              size: 16.sp,
                              color: AppColors.warning,
                            );
                          }),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${counselor.rating.toStringAsFixed(1)} (${counselor.reviewCount}개)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // === 경력과 상담 횟수 ===
                    Row(
                      children: [
                        Text(
                          '경력 ${counselor.experienceYears}년',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Text(
                          '상담 ${counselor.consultationCount}회',
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

          SizedBox(height: 20.h),

          // === 전문 분야 ===
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children:
                counselor.specialties
                    .map(
                      (specialty) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Counselor counselor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 소개 ===
          _buildInfoSection(
            title: '소개',
            child: Text(
              counselor.introduction,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // === 자격 및 학력 ===
          _buildInfoSection(
            title: '자격 및 학력',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  counselor.qualifications
                      .map(
                        (qualification) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.w,
                                margin: EdgeInsets.only(top: 6.h, right: 12.w),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  qualification,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          SizedBox(height: 24.h),

          // === 상담 방식 ===
          _buildInfoSection(
            title: '상담 방식',
            child: Row(
              children: [
                Icon(
                  _getMethodIcon(counselor.preferredMethod),
                  size: 20.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  counselor.preferredMethod.displayName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // === 사용 언어 ===
          _buildInfoSection(
            title: '사용 언어',
            child: Wrap(
              spacing: 8.w,
              children:
                  counselor.languages
                      .map(
                        (language) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            language,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          SizedBox(height: 24.h),

          // === 상담료 ===
          _buildInfoSection(
            title: '상담료',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1회 상담',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      counselor.price.consultationFeeText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (counselor.price.packagePriceText != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '패키지 (${counselor.price.packageSessions}회)',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        counselor.price.packagePriceText!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(CounselorReviewsState reviewsState) {
    if (reviewsState.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (reviewsState.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '아직 리뷰가 없습니다',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount:
          reviewsState.reviews.length + (reviewsState.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        if (index >= reviewsState.reviews.length) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final review = reviewsState.reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(CounselorReview review) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 리뷰어 정보 ===
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: AppColors.grey300,
                child: Text(
                  review.userName.substring(0, 1),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating.floor()
                                  ? Icons.star
                                  : index < review.rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                              size: 12.sp,
                              color: AppColors.warning,
                            );
                          }),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${review.rating.toStringAsFixed(1)}',
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
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // === 리뷰 내용 ===
          Text(
            review.content,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),

          // === 태그 ===
          if (review.tags != null && review.tags!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 6.w,
              children:
                  review.tags!
                      .map(
                        (tag) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.primary,
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

  Widget _buildBookingTab(Counselor counselor) {
    final availableSlotsState = ref.watch(
      availableSlotsProvider(widget.counselorId),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 날짜 선택 ===
          Text(
            '예약 날짜 선택',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          _buildDateSelector(),

          SizedBox(height: 24.h),

          // === 시간 선택 ===
          Text(
            '예약 시간 선택',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          _buildTimeSlots(availableSlotsState),

          SizedBox(height: 24.h),

          // === 상담 방식 선택 ===
          Text(
            '상담 방식 선택',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          _buildMethodSelector(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // 2주간
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected =
              _selectedDate.day == date.day &&
              _selectedDate.month == date.month &&
              _selectedDate.year == date.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              ref
                  .read(availableSlotsProvider(widget.counselorId).notifier)
                  .changeDate(date);
            },
            child: Container(
              width: 80.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekday(date),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${date.month}월',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots(AvailableSlotsState slotsState) {
    if (slotsState.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (slotsState.availableSlots.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            '선택한 날짜에 예약 가능한 시간이 없습니다',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 2.5,
      ),
      itemCount: slotsState.availableSlots.length,
      itemBuilder: (context, index) {
        final slot = slotsState.availableSlots[index];
        final bookingState = ref.watch(bookingProvider);
        final isSelected = bookingState.selectedTime == slot;

        return GestureDetector(
          onTap: () {
            ref.read(bookingProvider.notifier).selectTime(slot);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey300,
              ),
            ),
            child: Center(
              child: Text(
                '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodSelector() {
    final bookingState = ref.watch(bookingProvider);

    return Column(
      children:
          CounselingMethod.values
              .where((method) => method != CounselingMethod.all)
              .map((method) {
                final isSelected = bookingState.selectedMethod == method;

                return GestureDetector(
                  onTap: () {
                    ref.read(bookingProvider.notifier).selectMethod(method);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lightBlue50 : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.grey300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getMethodIcon(method),
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          method.displayName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                );
              })
              .toList(),
    );
  }

  Widget _buildInfoSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        child,
      ],
    );
  }

  Widget _buildBottomBar(Counselor counselor) {
    final bookingState = ref.watch(bookingProvider);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // === 가격 정보 ===
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '상담료',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                counselor.price.consultationFeeText,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          SizedBox(width: 20.w),

          // === 예약 버튼 ===
          Expanded(
            child: CustomButton(
              text: '예약하기',
              onPressed: bookingState.canBook ? _showBookingDialog : null,
              isLoading: bookingState.isCreating,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDialog() {
    return Consumer(
      builder: (context, ref, child) {
        final bookingState = ref.watch(bookingProvider);
        final counselor =
            ref.watch(counselorDetailProvider(widget.counselorId)).counselor!;

        return AlertDialog(
          title: Text(
            '예약 확인',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow('상담사', counselor.name),
              _buildDialogRow(
                '날짜',
                _formatBookingDate(bookingState.selectedDate!),
              ),
              _buildDialogRow(
                '시간',
                _formatBookingTime(bookingState.selectedTime!),
              ),
              _buildDialogRow('방식', bookingState.selectedMethod!.displayName),
              _buildDialogRow('소요시간', '${bookingState.durationMinutes}분'),
              _buildDialogRow('상담료', counselor.price.consultationFeeText),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed:
                  bookingState.isCreating
                      ? null
                      : () async {
                        // 예약 정보 설정
                        ref
                            .read(bookingProvider.notifier)
                            .selectCounselor(widget.counselorId);
                        ref
                            .read(bookingProvider.notifier)
                            .selectDate(_selectedDate);

                        final success =
                            await ref
                                .read(bookingProvider.notifier)
                                .createBooking();

                        if (mounted) {
                          Navigator.pop(context);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('예약이 완료되었습니다'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            // 예약 목록 화면으로 이동
                            context.push(AppRoutes.bookingList);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  bookingState.error ?? '예약에 실패했습니다',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
              child:
                  bookingState.isCreating
                      ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text('예약 확정'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
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
      default:
        return Icons.help_outline;
    }
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return weekdays[date.weekday % 7];
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _formatBookingDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일 (${_getWeekday(date)})';
  }

  String _formatBookingTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
