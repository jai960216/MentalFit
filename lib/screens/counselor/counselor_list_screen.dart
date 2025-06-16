import 'package:flutter/material.dart';
import 'package:flutter_mentalfit/providers/booking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/models/counselor_model.dart';
import '../../providers/counselor_provider.dart';
import 'dart:io';

class CounselorListScreen extends ConsumerStatefulWidget {
  const CounselorListScreen({super.key});

  @override
  ConsumerState<CounselorListScreen> createState() =>
      _CounselorListScreenState();
}

class _CounselorListScreenState extends ConsumerState<CounselorListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreData();
      }
    });
  }

  void _loadInitialData() {
    ref.read(counselorsProvider.notifier).loadCounselors();
  }

  void _loadMoreData() {
    final state = ref.read(counselorsProvider);
    if (!state.isLoadingMore && state.hasMoreData) {
      ref.read(counselorsProvider.notifier).loadMoreCounselors();
    }
  }

  Future<void> _refreshData() async {
    await ref.read(counselorsProvider.notifier).refreshCounselors();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      ref.read(counselorSearchProvider.notifier).clearSearch();
      _refreshData();
    } else {
      ref.read(counselorSearchProvider.notifier).performSearch(query);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              if (_showFilter) Expanded(child: _buildFilterSection()),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '상담사 찾기',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(counselorsProvider);
                    return Text(
                      '${state.counselors.length}명의 전문 상담사',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showFilter = !_showFilter),
            icon: Icon(
              _showFilter ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilter ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      color: AppColors.white,
      child: CustomTextField(
        controller: _searchController,
        hintText: '상담사 이름이나 전문 분야로 검색',
        prefixIcon: Icons.search,
        onChanged: _performSearch,
        suffixIcon: _searchController.text.isNotEmpty ? Icons.clear : null,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      color: AppColors.lightBlue50,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '필터',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            _buildSpecialtyFilter(),
            SizedBox(height: 16.h),
            _buildMethodFilter(),
            SizedBox(height: 16.h),
            _buildRatingFilter(),
            SizedBox(height: 16.h),
            _buildPriceFilter(),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: CustomButton(text: '필터 적용', onPressed: _applyFilters),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.grey300),
                    ),
                    child: const Text('초기화'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    final searchState = ref.watch(counselorSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '전문 분야',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children:
              [
                '스포츠 심리',
                '스트레스 관리',
                '불안 장애',
                '우울증',
                '수면 장애',
                '인지 행동 치료',
                '정신분석',
                '가족 상담',
              ].map((specialty) {
                final isSelected = searchState.selectedSpecialties.contains(
                  specialty,
                );
                return _buildFilterChip(
                  specialty,
                  isSelected,
                  () => ref
                      .read(counselorSearchProvider.notifier)
                      .toggleSpecialty(specialty),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildMethodFilter() {
    final searchState = ref.watch(counselorSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상담 방식',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children:
              CounselingMethod.values
                  .where((method) => method != CounselingMethod.all)
                  .map((method) {
                    final isSelected = searchState.selectedMethod == method;
                    return _buildFilterChip(
                      method.displayName,
                      isSelected,
                      () => ref
                          .read(counselorSearchProvider.notifier)
                          .setMethod(isSelected ? null : method),
                    );
                  })
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    final searchState = ref.watch(counselorSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최소 평점',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Row(
          children:
              [1.0, 2.0, 3.0, 4.0, 4.5].map((rating) {
                final isSelected = searchState.minRating == rating;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _buildFilterChip(
                    '$rating★',
                    isSelected,
                    () => ref
                        .read(counselorSearchProvider.notifier)
                        .setMinRating(isSelected ? null : rating),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    final searchState = ref.watch(counselorSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최대 상담료',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children:
              [30000, 50000, 70000, 100000].map((price) {
                final isSelected = searchState.maxPrice == price;
                return _buildFilterChip(
                  '${price ~/ 10000}만원 이하',
                  isSelected,
                  () => ref
                      .read(counselorSearchProvider.notifier)
                      .setMaxPrice(isSelected ? null : price),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    final searchState = ref.read(counselorSearchProvider);
    ref
        .read(counselorsProvider.notifier)
        .loadCounselors(
          specialties: searchState.selectedSpecialties,
          method: searchState.selectedMethod,
          minRating: searchState.minRating,
          maxPrice: searchState.maxPrice,
          onlineOnly: searchState.onlineOnly,
        );
    setState(() => _showFilter = false);
  }

  void _clearFilters() {
    ref.read(counselorSearchProvider.notifier).clearFilters();
    _refreshData();
  }

  Widget _buildContent() {
    return Consumer(
      builder: (context, ref, child) {
        final counselorsState = ref.watch(counselorsProvider);
        final searchState = ref.watch(counselorSearchProvider);

        if (searchState.isSearching) {
          return _buildLoadingWidget();
        }

        if (searchState.searchResults.isNotEmpty) {
          return _buildCounselorList(
            searchState.searchResults,
            counselorsState,
          );
        }

        if (searchState.searchQuery.isNotEmpty &&
            searchState.searchResults.isEmpty &&
            !searchState.isSearching) {
          return _buildEmptyWidget();
        }

        if (counselorsState.isLoading && counselorsState.counselors.isEmpty) {
          return _buildLoadingWidget();
        }

        if (counselorsState.error != null &&
            counselorsState.counselors.isEmpty) {
          return _buildErrorWidget(counselorsState.error!);
        }

        if (counselorsState.counselors.isEmpty && !counselorsState.isLoading) {
          return _buildEmptyWidget();
        }

        return _buildCounselorList(counselorsState.counselors, counselorsState);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16.h),
          Text(
            '상담사 목록을 불러오는 중...',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: 16.h),
          Text(
            '상담사 목록을 불러올 수 없습니다',
            style: TextStyle(fontSize: 16.sp, color: AppColors.error),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          CustomButton(text: '다시 시도', onPressed: _refreshData, width: 120.w),
        ],
      ),
    );
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
          if (isSearchMode) ...[
            SizedBox(height: 16.h),
            CustomButton(
              text: '전체 상담사 보기',
              onPressed: () {
                _searchController.clear();
                _refreshData();
              },
              width: 150.w,
            ),
          ],
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
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            SizedBox(height: 8.h),
            Text(
              '더 많은 상담사를 불러오는 중...',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounselorCard(Counselor counselor) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.counselorDetail}/${counselor.id}'),
      child: Container(
        padding: EdgeInsets.all(16.w),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
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
                      ? const Icon(Icons.person, size: 32, color: Colors.grey)
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
                            fontSize: 16.sp,
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
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '온라인',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
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
                  Wrap(
                    spacing: 8.w,
                    children:
                        counselor.specialties
                            .take(3)
                            .map(
                              (specialty) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
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
                              ),
                            )
                            .toList(),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16.w, color: AppColors.warning),
                      SizedBox(width: 4.w),
                      Text(
                        counselor.ratingText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        counselor.consultationText,
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
      ),
    );
  }
}
