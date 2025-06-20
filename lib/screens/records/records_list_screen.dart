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
import '../../shared/services/records_service.dart';
import '../../shared/models/record_model.dart';
import '../../providers/records_provider.dart';
import '../../shared/widgets/theme_aware_widgets.dart';

class RecordsListScreen extends ConsumerStatefulWidget {
  const RecordsListScreen({super.key});

  @override
  ConsumerState<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends ConsumerState<RecordsListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  RecordType _selectedFilter = RecordType.all;
  String _selectedSortBy = 'latest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupAnimations();
    _loadRecords();
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

  Future<void> _loadRecords() async {
    await ref.read(recordsProvider.notifier).loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // === 필터링된 기록 가져오기 ===
  List<CounselingRecord> _getFilteredRecords(List<CounselingRecord> records) {
    List<CounselingRecord> filtered = records;

    // 타입별 필터링
    if (_selectedFilter != RecordType.all) {
      filtered =
          filtered.where((record) => record.type == _selectedFilter).toList();
    }

    // 정렬
    switch (_selectedSortBy) {
      case 'latest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'rating':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
    }

    return filtered;
  }

  // === 필터 및 정렬 다이얼로그 ===
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '필터 및 정렬',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),

                // 상담 유형 필터
                Text(
                  '상담 유형',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children:
                      RecordType.values.map((type) {
                        return FilterChip(
                          label: Text(type.displayName),
                          selected: _selectedFilter == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = type;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                ),

                SizedBox(height: 20.h),

                // 정렬 기준
                Text(
                  '정렬 기준',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Column(
                  children: [
                    _buildSortOption('latest', '최신순'),
                    _buildSortOption('oldest', '오래된순'),
                    _buildSortOption('rating', '평점순'),
                  ],
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
    );
  }

  Widget _buildSortOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedSortBy,
      onChanged: (selectedValue) {
        setState(() {
          _selectedSortBy = selectedValue!;
        });
        Navigator.pop(context);
      },
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(recordsProvider);

    return ThemedScaffold(
      appBar: CustomAppBar(
        title: '상담 기록',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child:
            recordsState.isLoading
                ? const LoadingWidget()
                : recordsState.error != null
                ? _buildErrorState(recordsState.error!)
                : _buildRecordsList(recordsState.records),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AppRoutes.createRecord);
        },
        label: const Text('새 기록'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildErrorState(String error) {
    return Center(
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
            error,
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: '다시 시도',
            onPressed: _loadRecords,
            type: ButtonType.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<CounselingRecord> records) {
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    final filteredRecords = _getFilteredRecords(records);

    if (filteredRecords.isEmpty) {
      return _buildNoResultsState();
    }

    return Column(
      children: [
        // === 필터 상태 표시 ===
        if (_selectedFilter != RecordType.all || _selectedSortBy != 'latest')
          _buildFilterStatus(),

        // === 통계 카드 ===
        _buildStatsCard(records),

        SizedBox(height: 16.h),

        // === 기록 목록 ===
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRecords,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: filteredRecords.length,
              itemBuilder: (context, index) {
                final record = filteredRecords[index];
                return _buildRecordCard(record);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 48.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            '아직 상담 기록이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '첫 상담을 받아보세요!\n기록을 통해 성장 과정을 확인할 수 있습니다.',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          CustomButton(
            text: 'AI 상담 시작하기',
            onPressed: () => context.push(AppRoutes.aiCounseling),
            icon: Icons.psychology,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64.sp, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text(
            '조건에 맞는 기록이 없습니다',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: '필터 초기화',
            onPressed: () {
              setState(() {
                _selectedFilter = RecordType.all;
                _selectedSortBy = 'latest';
              });
            },
            type: ButtonType.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16.sp, color: AppColors.primary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${_selectedFilter.displayName} • ${_getSortDisplayName(_selectedSortBy)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = RecordType.all;
                _selectedSortBy = 'latest';
              });
            },
            child: Text(
              '초기화',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'latest':
        return '최신순';
      case 'oldest':
        return '오래된순';
      case 'rating':
        return '평점순';
      default:
        return '최신순';
    }
  }

  Widget _buildStatsCard(List<CounselingRecord> records) {
    final totalSessions = records.length;
    final aiSessions = records.where((r) => r.type == RecordType.ai).length;
    final counselorSessions =
        records.where((r) => r.type == RecordType.counselor).length;
    final avgRating =
        records
            .where((r) => r.rating != null)
            .map((r) => r.rating!)
            .fold(0.0, (a, b) => a + b) /
        (records
            .where((r) => r.rating != null)
            .length
            .clamp(1, double.infinity));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
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
            '나의 상담 통계',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '총 상담',
                  '$totalSessions회',
                  Icons.psychology,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'AI 상담',
                  '$aiSessions회',
                  Icons.smart_toy,
                  AppColors.info,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '전문상담',
                  '$counselorSessions회',
                  Icons.person,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '평균 만족도',
                  avgRating.isNaN ? '-' : '${avgRating.toStringAsFixed(1)}점',
                  Icons.star,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.sp, color: color),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordCard(CounselingRecord record) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('${AppRoutes.recordDetail}/${record.id}'),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 헤더 ===
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
                        size: 16.sp,
                        color: record.type.color,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            record.dateText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (record.rating != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12.sp,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              record.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 12.h),

                // === 내용 미리보기 ===
                if (record.summary.isNotEmpty)
                  Text(
                    record.summary,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                SizedBox(height: 12.h),

                // === 하단 정보 ===
                Row(
                  children: [
                    if (record.counselorName != null) ...[
                      Icon(
                        Icons.person_outline,
                        size: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        record.counselorName!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 16.w),
                    ],
                    Icon(
                      Icons.schedule,
                      size: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${record.durationMinutes}분',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
