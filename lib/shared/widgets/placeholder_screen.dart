import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../../shared/widgets/theme_aware_widgets.dart';
import '../../shared/widgets/custom_app_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: CustomAppBar(title: title),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // === 플레이스홀더 아이콘 ===
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.construction,
                  size: 40.sp,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(height: 24.h),

              // === 제목 ===
              ThemedText(
                text: title,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              // === 설명 ===
              ThemedText(
                text: description ?? '이 기능은 곧 제공될 예정입니다.\n조금만 기다려 주세요! 🚀',
                isPrimary: false,
                style: TextStyle(fontSize: 14.sp, height: 1.5),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // === 액션 버튼 ===
              if (onAction != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      actionText ?? '돌아가기',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
