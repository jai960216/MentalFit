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
import '../../providers/counselor_filters_provider.dart';

class CounselorListScreen extends ConsumerStatefulWidget {
  const CounselorListScreen({super.key});

  @override
  ConsumerState<CounselorListScreen> createState() =>
      _CounselorListScreenState();
}

class _CounselorListScreenState extends ConsumerState<CounselorListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreCounselors();
      }
    });
  }

  Future<void> _loadMoreCounselors() async {
    final filters = ref.read(counselorFiltersProvider);
    await ref
        .read(counselorsProvider.notifier)
        .loadMoreCounselors(
          specialties:
              filters.selectedSpecialties.isNotEmpty
                  ? filters.selectedSpecialties
                  : null,
          method: filters.selectedMethod,
          minRating: filters.minRating,
          maxPrice: filters.maxPrice,
          onlineOnly: filters.onlineOnly ? true : null,
          sortBy: filters.sortBy,
        );
  }

  Future<void> _refreshData() async {
    final filters = ref.read(counselorFiltersProvider);
    await ref
        .read(counselorsProvider.notifier)
        .loadCounselors(
          specialties:
              filters.selectedSpecialties.isNotEmpty
                  ? filters.selectedSpecialties
                  : null,
          method: filters.selectedMethod,
          minRating: filters.minRating,
          maxPrice: filters.maxPrice,
          onlineOnly: filters.onlineOnly ? true : null,
          sortBy: filters.sortBy,
          refresh: true,
        );
  }

  Future<void> _applyFilters() async {
    final filters = ref.read(counselorFiltersProvider);
    await ref
        .read(counselorsProvider.notifier)
        .loadCounselors(
          specialties:
              filters.selectedSpecialties.isNotEmpty
                  ? filters.selectedSpecialties
                  : null,
          method: filters.selectedMethod,
          minRating: filters.minRating,
          maxPrice: filters.maxPrice,
          onlineOnly: filters.onlineOnly ? true : null,
          sortBy: filters.sortBy,
          refresh: true,
        );
  }

  Future<void> _searchCounselors(String query) async {
    if (query.trim().isEmpty) {
      await _refreshData();
      return;
    }

    await ref.read(counselorSearchProvider.notifier).searchCounselors(query);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counselorsState = ref.watch(counselorsProvider);
    final searchState = ref.watch(counselorSearchProvider);
    final filtersState = ref.watch(counselorFiltersProvider);

    // 검색 결과가 있으면 검색 결과를 표시, 없으면 일반 목록 표시
    final displayCounselors =
        searchState.searchQuery.isNotEmpty
            ? searchState.searchResults
            : counselorsState.counselors;
    final isLoading =
        searchState.searchQuery.isNotEmpty
            ? searchState.isSearching
            : counselorsState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // === 검색 및 필터 영역 ===
          _buildSearchAndFilterSection(filtersState),

          // === 상담사 목록 ===
          Expanded(
            child:
                isLoading && displayCounselors.isEmpty
                    ? _buildLoadingWidget()
                    : displayCounselors.isEmpty
                    ? _buildEmptyWidget()
                    : _buildCounselorList(displayCounselors, counselorsState),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        '상담사 찾기',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(CounselorFilters filters) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Column(
        children: [
          // === 검색창 ===
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '상담사 이름, 전문분야 검색',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onChanged: _searchCounselors,
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // === 필터 버튼 ===
              Container(
                height: 48.h,
                width: 48.w,
                decoration: BoxDecoration(
                  color:
                      filters.hasActiveFilters
                          ? AppColors.primary
                          : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: _showFilterBottomSheet,
                  icon: Icon(
                    Icons.tune,
                    color:
                        filters.hasActiveFilters
                            ? Colors.white
                            : AppColors.textSecondary,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),

          // === 활성 필터 표시 ===
          if (filters.hasActiveFilters) ...[
            SizedBox(height: 16.h),
            _buildActiveFilters(filters),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters(CounselorFilters filters) {
    return SizedBox(
      height: 32.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // === 필터 개수 표시 ===
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              '${filters.activeFilterCount}개 필터 적용',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // === 전문분야 필터 ===
          ...filters.selectedSpecialties.map(
            (specialty) => _buildFilterChip(
              specialty,
              () => ref
                  .read(counselorFiltersProvider.notifier)
                  .toggleSpecialty(specialty),
            ),
          ),

          // === 상담방식 필터 ===
          if (filters.selectedMethod != null)
            _buildFilterChip(
              filters.selectedMethod!.displayName,
              () => ref.read(counselorFiltersProvider.notifier).setMethod(null),
            ),

          // === 온라인 전용 필터 ===
          if (filters.onlineOnly)
            _buildFilterChip(
              '온라인',
              () => ref
                  .read(counselorFiltersProvider.notifier)
                  .setOnlineOnly(false),
            ),

          // === 전체 초기화 ===
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
              ref.read(counselorFiltersProvider.notifier).clearAllFilters();
              _applyFilters();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '초기화',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, VoidCallback onRemove) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.lightBlue100,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14.sp, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(child: CircularProgressIndicator(color: AppColors.primary));
  }

  Widget _buildEmptyWidget() {
    final searchState = ref.watch(counselorSearchProvider);
    final isSearchMode = searchState.searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchMode ? Icons.search_off : Icons.person_search,
            size: 64.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            isSearchMode ? '검색 결과가 없습니다' : '등록된 상담사가 없습니다',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            isSearchMode ? '다른 검색어를 입력해보세요' : '나중에 다시 확인해주세요',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorList(
    List<Counselor> counselors,
    CounselorsState state,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.all(20.w),
        itemCount: counselors.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: 16.h),
        itemBuilder: (context, index) {
          if (index >= counselors.length) {
            return _buildLoadMoreIndicator();
          }

          final counselor = counselors[index];
          return _buildCounselorCard(counselor);
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildCounselorCard(Counselor counselor) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.counselorDetail}/${counselor.id}'),
      child: Container(
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
            // === 상담사 기본 정보 ===
            Row(
              children: [
                // === 프로필 이미지 ===
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: AppColors.grey200,
                  backgroundImage:
                      counselor.profileImageUrl != null
                          ? NetworkImage(counselor.profileImageUrl!)
                          : null,
                  child:
                      counselor.profileImageUrl == null
                          ? Icon(
                            Icons.person,
                            size: 30.sp,
                            color: AppColors.textSecondary,
                          )
                          : null,
                ),

                SizedBox(width: 16.w),

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
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (counselor.isOnline)
                            Container(
                              width: 8.w,
                              height: 8.w,
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
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // === 평점과 경력 ===
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16.sp,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            counselor.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ' (${counselor.reviewCount})',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Text(
                            '경력 ${counselor.experienceYears}년',
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

                // === 가격 ===
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      counselor.price.consultationFeeText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (counselor.price.packagePriceText != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        counselor.price.packagePriceText!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // === 전문 분야 ===
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  counselor.specialties
                      .take(3)
                      .map(
                        (specialty) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue50,
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

            SizedBox(height: 12.h),

            // === 소개 (2줄까지만) ===
            Text(
              counselor.introduction,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Consumer(
      builder: (context, ref, child) {
        final filters = ref.watch(counselorFiltersProvider);
        final specialtiesAsync = ref.watch(specialtiesProvider);

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // === 헤더 ===
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.grey200)),
                ),
                child: Row(
                  children: [
                    Text(
                      '필터',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(counselorFiltersProvider.notifier)
                            .clearAllFilters();
                      },
                      child: Text(
                        '초기화',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // === 필터 옵션들 ===
              Expanded(
                child: specialtiesAsync.when(
                  data:
                      (specialties) =>
                          _buildFilterContent(filters, specialties),
                  loading:
                      () => Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                  error:
                      (error, stack) => Center(
                        child: Text(
                          '전문분야를 불러올 수 없습니다',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                ),
              ),

              // === 적용 버튼 ===
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.grey200)),
                ),
                child: CustomButton(
                  text: '필터 적용',
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterContent(
    CounselorFilters filters,
    List<String> specialties,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 전문 분야 ===
          _buildFilterSection(
            title: '전문 분야',
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  specialties.map((specialty) {
                    final isSelected = filters.selectedSpecialties.contains(
                      specialty,
                    );
                    return GestureDetector(
                      onTap:
                          () => ref
                              .read(counselorFiltersProvider.notifier)
                              .toggleSpecialty(specialty),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.grey100,
                          borderRadius: BorderRadius.circular(20.r),
                          border:
                              isSelected
                                  ? Border.all(color: AppColors.primary)
                                  : null,
                        ),
                        child: Text(
                          specialty,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          SizedBox(height: 24.h),

          // === 상담 방식 ===
          _buildFilterSection(
            title: '상담 방식',
            child: Column(
              children:
                  CounselingMethod.values
                      .where((method) => method != CounselingMethod.all)
                      .map((method) {
                        final isSelected = filters.selectedMethod == method;
                        return GestureDetector(
                          onTap:
                              () => ref
                                  .read(counselorFiltersProvider.notifier)
                                  .setMethod(isSelected ? null : method),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.lightBlue50
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.grey300,
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
            ),
          ),

          SizedBox(height: 24.h),

          // === 기타 옵션 ===
          _buildFilterSection(
            title: '기타 옵션',
            child: Column(
              children: [
                // === 온라인 상담 가능 ===
                GestureDetector(
                  onTap:
                      () =>
                          ref
                              .read(counselorFiltersProvider.notifier)
                              .toggleOnlineOnly(),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color:
                          filters.onlineOnly
                              ? AppColors.lightBlue50
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color:
                            filters.onlineOnly
                                ? AppColors.primary
                                : AppColors.grey300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.online_prediction,
                          color:
                              filters.onlineOnly
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '온라인 상담 가능한 상담사만',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                filters.onlineOnly
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                            fontWeight:
                                filters.onlineOnly
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: filters.onlineOnly,
                          onChanged:
                              (value) => ref
                                  .read(counselorFiltersProvider.notifier)
                                  .setOnlineOnly(value),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // === 정렬 옵션 ===
          _buildFilterSection(
            title: '정렬',
            child: Column(
              children: [
                _buildSortOption('평점순', 'rating', filters.sortBy),
                _buildSortOption('가격순', 'price', filters.sortBy),
                _buildSortOption('경력순', 'experience', filters.sortBy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
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

  Widget _buildSortOption(String title, String value, String currentSort) {
    final isSelected = currentSort == value;
    return GestureDetector(
      onTap: () => ref.read(counselorFiltersProvider.notifier).setSortBy(value),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightBlue50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp),
          ],
        ),
      ),
    );
  }

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
}
