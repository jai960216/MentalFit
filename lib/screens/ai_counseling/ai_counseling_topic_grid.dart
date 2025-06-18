import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';

class AiCounselingTopicGrid extends StatelessWidget {
  final List<Map<String, dynamic>> topics;
  final Function(String topicId) onSelect;

  const AiCounselingTopicGrid({
    required this.topics,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85, // 1.2 → 0.85로 변경 (세로로 더 길게)
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: topics.length,
      itemBuilder: (context, idx) {
        final topic = topics[idx];
        return GestureDetector(
          onTap: () => onSelect(topic['id']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: topic['color'].withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: topic['color'].withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w), // 16.w → 12.w로 줄임
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40.w, // 48.w → 40.w로 줄임
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: topic['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      topic['icon'],
                      color: topic['color'],
                      size: 20.sp, // 24.sp → 20.sp로 줄임
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    topic['title'],
                    textAlign: TextAlign.center, // 가운데 정렬 추가
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp, // 14.sp → 13.sp로 줄임
                    ),
                  ),
                  SizedBox(height: 4.h), // 2.h → 4.h로 늘림
                  Text(
                    topic['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                      height: 1.2, // 줄 간격 추가
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
