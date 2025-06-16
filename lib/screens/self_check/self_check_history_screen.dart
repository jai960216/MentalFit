import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../providers/self_check_provider.dart';
import '../../shared/models/self_check_models.dart';

class SelfCheckHistoryScreen extends ConsumerStatefulWidget {
  const SelfCheckHistoryScreen({super.key});

  @override
  ConsumerState<SelfCheckHistoryScreen> createState() =>
      _SelfCheckHistoryScreenState();
}

class _SelfCheckHistoryScreenState
    extends ConsumerState<SelfCheckHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(selfCheckProvider.notifier).loadRecentResults(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selfCheckState = ref.watch(selfCheckProvider);
    final results = selfCheckState.recentResults;
    final isLoading = selfCheckState.isLoading;
    final error = selfCheckState.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '자가진단 기록'),
      body:
          isLoading
              ? const LoadingWidget()
              : error != null
              ? Center(child: Text('오류: $error'))
              : results.isEmpty
              ? Center(
                child: Text(
                  '자가진단 기록이 없습니다.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
              : ListView.separated(
                padding: EdgeInsets.all(20.w),
                itemCount: results.length,
                separatorBuilder: (context, i) => SizedBox(height: 12.h),
                itemBuilder: (context, i) {
                  final result = results[i];
                  return GestureDetector(
                    onTap:
                        () => context.push(
                          '${AppRoutes.selfCheckResult}/${result.id}',
                        ),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: result.riskLevel.color,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.test.title,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _formatDate(result.completedAt),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: result.riskLevel.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              result.riskLevel.name,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: result.riskLevel.color,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12.sp,
                            color: AppColors.grey400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
