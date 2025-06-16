import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double? height;
  final LinearGradient? gradient; // 🔥 gradient 매개변수 추가
  final double? textSize;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
    this.height,
    this.gradient, // 🔥 gradient 매개변수 추가
    this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 56.h,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    // 🔥 gradient가 있을 때 특별 처리
    if (gradient != null && type == ButtonType.primary) {
      return _buildGradientButton(context);
    }

    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton(context);
      case ButtonType.secondary:
        return _buildSecondaryButton(context);
      case ButtonType.outline:
        return _buildOutlineButton(context);
      case ButtonType.text:
        return _buildTextButton(context);
    }
  }

  // 🔥 그라데이션 버튼 생성 메서드
  Widget _buildGradientButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isLoading || onPressed == null ? null : gradient,
        color: isLoading || onPressed == null ? AppColors.grey300 : null,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.grey300,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.grey300,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlineButton(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary, width: 2.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 20.h,
        width: 20.w,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              text,
              style: TextStyle(
                fontSize: textSize ?? 16.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(
          fontSize: textSize ?? 16.sp,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
