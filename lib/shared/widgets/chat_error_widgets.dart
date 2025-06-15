import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../models/chat_room_model.dart';
import '../../providers/chat_provider.dart';

class ChatErrorWidgets {
  /// 에러 상태 위젯
  static Widget buildErrorState(
    ChatRoomType type,
    String error,
    VoidCallback onRetry,
    VoidCallback onCreateAIChat,
    VoidCallback onFindCounselor,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              '채팅방을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('다시 시도'),
                ),
                SizedBox(width: 16.w),
                if (type == ChatRoomType.ai)
                  OutlinedButton(
                    onPressed: onCreateAIChat,
                    child: const Text('AI 상담 시작'),
                  )
                else
                  OutlinedButton(
                    onPressed: onFindCounselor,
                    child: const Text('상담사 찾기'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 상태 위젯
  static Widget buildEmptyState(
    ChatRoomType type,
    VoidCallback onCreateAIChat,
    VoidCallback onFindCounselor,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == ChatRoomType.ai ? Icons.smart_toy : Icons.person_search,
              size: 64.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16.h),
            Text(
              type == ChatRoomType.ai ? '아직 AI 상담이 없습니다' : '아직 상담사와의 대화가 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              type == ChatRoomType.ai
                  ? 'AI 상담사와 대화를 시작해보세요'
                  : '전문 상담사와 상담을 시작해보세요',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed:
                  type == ChatRoomType.ai ? onCreateAIChat : onFindCounselor,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              ),
              child: Text(
                type == ChatRoomType.ai ? 'AI 상담 시작' : '상담사 찾기',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 배너 위젯
  static Widget buildErrorBanner(
    String error,
    VoidCallback onRetry,
    WidgetRef ref,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppColors.error, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 14.sp, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatListProvider.notifier).clearError();
            },
            child: Text(
              '닫기',
              style: TextStyle(fontSize: 12.sp, color: AppColors.error),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(chatListProvider.notifier).clearError(),
            icon: Icon(Icons.close, size: 16.sp, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  /// 네트워크 에러 위젯
  static Widget buildNetworkError(VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              '인터넷 연결을 확인해주세요',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '네트워크 연결 상태를 확인하고 다시 시도해주세요',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 로딩 실패 위젯
  static Widget buildLoadingError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('새로고침'),
            ),
          ],
        ),
      ),
    );
  }

  /// 권한 거부 위젯
  static Widget buildPermissionDenied(
    String permission,
    VoidCallback onOpenSettings,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64.sp, color: AppColors.warning),
            SizedBox(height: 16.h),
            Text(
              '$permission 권한이 필요합니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '해당 기능을 사용하려면 권한을 허용해주세요',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: onOpenSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('설정으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
