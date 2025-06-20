import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';

import '../../core/config/app_routes.dart';
import '../../core/utils/image_cache_manager.dart';
import '../../providers/counselor_filters_provider.dart' as filters;
import '../../providers/counselor_provider.dart';
import '../../shared/models/counselor_model.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/theme_aware_widgets.dart';

class CounselorListScreen extends ConsumerWidget {
  const CounselorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // counselorProvider를 초기에 로드하도록 요청합니다.
    ref.watch(counselorsProvider);

    return ThemedScaffold(
      appBar: const CustomAppBar(title: '상담사 찾기'),
      body: Column(
        children: [
          _buildFilterSection(ref),
          Expanded(child: _buildCounselorList(ref)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(WidgetRef ref) {
    return ThemedContainer(
      useSurface: false,
      addShadow: false,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged:
                  (query) =>
                      ref.read(counselorSearchQueryProvider.notifier).state =
                          query,
              decoration: InputDecoration(
                hintText: '상담사 이름으로 검색',
                prefixIcon: const ThemedIcon(icon: Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Consumer(
            builder: (context, ref, child) {
              final filtersState = ref.watch(filters.counselorFiltersProvider);
              final hasActiveFilters = filtersState.hasActiveFilters;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          hasActiveFilters
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    onPressed: () => _showFilterBottomSheet(context, ref),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return ThemedContainer(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: _buildFilterOptions(scrollController, ref),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOptions(ScrollController scrollController, WidgetRef ref) {
    return Column(
      children: [
        // 헤더
        Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ThemedText(
                text: '필터',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final filtersState = ref.watch(
                    filters.counselorFiltersProvider,
                  );
                  return TextButton(
                    onPressed:
                        filtersState.hasActiveFilters
                            ? () =>
                                ref
                                    .read(
                                      filters.counselorFiltersProvider.notifier,
                                    )
                                    .clearAllFilters()
                            : null,
                    child: ThemedText(
                      text: '초기화',
                      isPrimary: false,
                      style: TextStyle(
                        color:
                            filtersState.hasActiveFilters
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // 필터 옵션들
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpecialtiesFilter(ref),
                SizedBox(height: 24.h),
                _buildMethodFilter(ref),
                SizedBox(height: 24.h),
                _buildRatingFilter(ref),
                SizedBox(height: 24.h),
                _buildPriceFilter(ref),
                SizedBox(height: 24.h),
                _buildOnlineFilter(ref),
                SizedBox(height: 24.h),
                _buildSortFilter(ref),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtiesFilter(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final specialties = ref.watch(filters.specialtiesProvider);
        final selectedSpecialties =
            ref.watch(filters.counselorFiltersProvider).selectedSpecialties;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThemedText(
              text: '전문 분야',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            specialties.when(
              data:
                  (specialtyList) => Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children:
                        specialtyList.map((specialty) {
                          final isSelected = selectedSpecialties.contains(
                            specialty,
                          );
                          return FilterChip(
                            label: ThemedText(text: specialty),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref
                                  .read(
                                    filters.counselorFiltersProvider.notifier,
                                  )
                                  .toggleSpecialty(specialty);
                            },
                          );
                        }).toList(),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ThemedText(text: '오류: $error'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMethodFilter(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedMethod =
            ref.watch(filters.counselorFiltersProvider).selectedMethod;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThemedText(
              text: '상담 방식',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  CounselingMethod.values.map((method) {
                    final isSelected = selectedMethod == method;
                    return FilterChip(
                      label: ThemedText(text: method.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref
                            .read(filters.counselorFiltersProvider.notifier)
                            .setMethod(selected ? method : null);
                      },
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingFilter(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final minRating = ref.watch(filters.counselorFiltersProvider).minRating;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThemedText(
              text: '최소 평점',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  [3.0, 3.5, 4.0, 4.5].map((rating) {
                    final isSelected = minRating == rating;
                    return FilterChip(
                      label: ThemedText(text: '${rating}점 이상'),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref
                            .read(filters.counselorFiltersProvider.notifier)
                            .setMinRating(selected ? rating : null);
                      },
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceFilter(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final maxPrice = ref.watch(filters.counselorFiltersProvider).maxPrice;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThemedText(
              text: '최대 가격',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  [30000, 50000, 80000, 100000].map((price) {
                    final isSelected = maxPrice == price;
                    return FilterChip(
                      label: ThemedText(text: '${price ~/ 1000}만원 이하'),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref
                            .read(filters.counselorFiltersProvider.notifier)
                            .setMaxPrice(selected ? price : null);
                      },
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnlineFilter(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final onlineOnly =
            ref.watch(filters.counselorFiltersProvider).onlineOnly;

        return Row(
          children: [
            const ThemedText(
              text: '온라인 상담만',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Switch(
              value: onlineOnly,
              onChanged: (value) {
                ref
                    .read(filters.counselorFiltersProvider.notifier)
                    .setOnlineOnly(value);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortFilter(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final sortBy = ref.watch(filters.counselorFiltersProvider).sortBy;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThemedText(
              text: '정렬',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  [
                    {'value': 'rating', 'label': '평점순'},
                    {'value': 'price', 'label': '가격순'},
                    {'value': 'experience', 'label': '경력순'},
                    {'value': 'name', 'label': '이름순'},
                  ].map((sortOption) {
                    final isSelected = sortBy == sortOption['value'];
                    return FilterChip(
                      label: ThemedText(text: sortOption['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref
                              .read(filters.counselorFiltersProvider.notifier)
                              .setSortBy(sortOption['value']!);
                        }
                      },
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCounselorList(WidgetRef ref) {
    final counselorsState = ref.watch(counselorsProvider);
    final filteredCounselors = ref.watch(filteredCounselorsProvider);

    // 디버그: 상담사 데이터 확인
    if (filteredCounselors.isNotEmpty) {
      debugPrint('📋 상담사 목록 데이터 확인:');
      for (int i = 0; i < filteredCounselors.length; i++) {
        final counselor = filteredCounselors[i];
        debugPrint(
          '  ${i + 1}. ${counselor.name}: profileImageUrl = "${counselor.profileImageUrl}"',
        );
      }
    }

    if (counselorsState.isLoading && counselorsState.counselors.isEmpty) {
      return const LoadingWidget();
    }

    if (counselorsState.error != null) {
      return Center(child: ThemedText(text: '오류: ${counselorsState.error}'));
    }

    if (filteredCounselors.isEmpty && !counselorsState.isLoading) {
      return RefreshIndicator(
        onRefresh:
            () => ref.read(counselorsProvider.notifier).refreshCounselors(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(top: 100.h),
            child: const ThemedText(text: '해당하는 상담사가 없습니다.'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          () => ref.read(counselorsProvider.notifier).refreshCounselors(),
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredCounselors.length,
        itemBuilder: (context, index) {
          return _buildCounselorCard(context, filteredCounselors[index]);
        },
      ),
    );
  }

  Widget _buildCounselorCard(BuildContext context, Counselor counselor) {
    return ThemedCard(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      onTap: () => context.push('${AppRoutes.counselorDetail}/${counselor.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: _buildCounselorImage(context, counselor.profileImageUrl),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText(
                  text: counselor.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                ThemedText(
                  text: counselor.introduction,
                  isPrimary: false,
                  style: TextStyle(fontSize: 13.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    const ThemedIcon(icon: Icons.star, size: 16),
                    SizedBox(width: 4.w),
                    ThemedText(
                      text:
                          '${counselor.rating.toStringAsFixed(1)} (${counselor.reviewCount})',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorImage(BuildContext context, String? imageUrl) {
    // 디버그 로그 추가
    debugPrint('🔍 상담사 이미지 URL: $imageUrl');

    // 이미지 URL이 null이거나 빈 문자열인 경우 기본 프로필 이미지 표시
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('⚠️ 이미지 URL이 없어 기본 이미지 표시');
      return Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          Icons.person,
          size: 40.w,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    // 로컬 파일 경로인지 네트워크 URL인지 확인
    final isLocalFile =
        imageUrl.startsWith('/') || imageUrl.startsWith('file://');

    if (isLocalFile) {
      debugPrint('📁 로컬 파일 경로: $imageUrl');
      return Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          image: DecorationImage(
            image: FileImage(File(imageUrl)),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              debugPrint('❌ 로컬 파일 로딩 실패: $imageUrl, 오류: $exception');
            },
          ),
        ),
      );
    } else {
      debugPrint('🌐 네트워크 URL: $imageUrl');
      return Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              debugPrint('❌ NetworkImage 로딩 실패: $imageUrl, 오류: $exception');
            },
          ),
        ),
      );
    }
  }
}
