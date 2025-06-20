import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../shared/widgets/theme_aware_widgets.dart';

class AiCounselingTopicGrid extends StatelessWidget {
  final List<Map<String, dynamic>> topics;
  final Function(String) onTopicSelected;

  const AiCounselingTopicGrid({
    super.key,
    required this.topics,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: topics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final topic = topics[index];
        return _buildTopicCard(context, topic);
      },
    );
  }

  Widget _buildTopicCard(BuildContext context, Map<String, dynamic> topic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ThemedCard(
      onTap: () => onTopicSelected(topic['title'] as String),
      child: ThemedContainer(
        useSurface: true,
        borderRadius: BorderRadius.circular(16.r),
        padding: EdgeInsets.all(0),
        addShadow: false,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: (topic['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  topic['icon'] as IconData,
                  color: topic['color'] as Color,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 12.h),
              ThemedText(
                text: topic['title'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              ThemedText(
                text: topic['subtitle'] as String,
                textAlign: TextAlign.center,
                isPrimary: false,
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
