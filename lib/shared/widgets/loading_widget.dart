import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';

// === 기본 로딩 위젯 ===
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;

  const LoadingWidget({super.key, this.message, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40.w,
            height: size ?? 40.w,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
              strokeWidth: 3.0,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// === 풀스크린 로딩 오버레이 ===
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? AppColors.black.withOpacity(0.5),
            child: LoadingWidget(message: message),
          ),
      ],
    );
  }
}

// === 작은 인라인 로딩 ===
class SmallLoadingWidget extends StatelessWidget {
  final Color? color;
  final double? size;

  const SmallLoadingWidget({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 20.w,
      height: size ?? 20.w,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
        strokeWidth: 2.0,
      ),
    );
  }
}

// === 리스트 아이템 로딩 (스켈레톤) ===
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({super.key, this.width, this.height, this.borderRadius});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 16.h,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4.r),
            gradient: LinearGradient(
              colors: [AppColors.grey200, AppColors.grey100, AppColors.grey200],
              stops: [0.0, _animation.value, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

// === 리스트 스켈레톤 로더 ===
class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? EdgeInsets.all(16.w),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight.h,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SkeletonLoader(
                width: 48.w,
                height: 48.w,
                borderRadius: BorderRadius.circular(24.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonLoader(width: double.infinity, height: 16.h),
                    SizedBox(height: 8.h),
                    SkeletonLoader(width: 200.w, height: 12.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// === 카드 스켈레톤 로더 ===
class CardSkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;

  const CardSkeletonLoader({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 120.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(
                width: 40.w,
                height: 40.w,
                borderRadius: BorderRadius.circular(8.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: double.infinity, height: 16.h),
                    SizedBox(height: 6.h),
                    SkeletonLoader(width: 100.w, height: 12.h),
                  ],
                ),
              ),
              SkeletonLoader(width: 60.w, height: 12.h),
            ],
          ),
          SizedBox(height: 12.h),
          SkeletonLoader(width: double.infinity, height: 12.h),
          SizedBox(height: 6.h),
          SkeletonLoader(width: 250.w, height: 12.h),
        ],
      ),
    );
  }
}

// === 점진적 로딩 표시기 ===
class ProgressLoadingWidget extends StatelessWidget {
  final double progress;
  final String? message;
  final Color? progressColor;
  final Color? backgroundColor;

  const ProgressLoadingWidget({
    super.key,
    required this.progress,
    this.message,
    this.progressColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60.w,
              height: 60.w,
              child: CircularProgressIndicator(
                value: progress,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? AppColors.primary,
                ),
                backgroundColor: backgroundColor ?? AppColors.grey200,
                strokeWidth: 4.0,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: progressColor ?? AppColors.primary,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: 8.h),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// === 상태별 로딩 위젯 ===
class StateLoadingWidget extends StatelessWidget {
  final LoadingState state;
  final String? message;
  final VoidCallback? onRetry;

  const StateLoadingWidget({
    super.key,
    required this.state,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LoadingState.loading:
        return LoadingWidget(message: message);
      case LoadingState.error:
        return _buildErrorWidget();
      case LoadingState.empty:
        return _buildEmptyWidget();
      case LoadingState.success:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.w, color: AppColors.error),
          SizedBox(height: 16.h),
          Text(
            message ?? '오류가 발생했습니다',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48.w,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            message ?? '데이터가 없습니다',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum LoadingState { loading, error, empty, success }
