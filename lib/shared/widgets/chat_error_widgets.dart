import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import 'custom_button.dart';
import '../models/chat_room_model.dart';
import '../../providers/chat_provider.dart';

class ChatErrorWidgets {
  static Widget buildErrorState(
    ChatRoomType type,
    String error,
    VoidCallback onRetry,
    VoidCallback onCreateAI,
    VoidCallback onFindCounselor,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getErrorIcon(type), size: 64.sp, color: AppColors.error),
            SizedBox(height: 24.h),
            Text(
              _getErrorTitle(type),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _getErrorMessage(error),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            if (type == ChatRoomType.ai) ...[
              CustomButton(
                text: '새 AI 채팅 시작',
                onPressed: onCreateAI,
                icon: Icons.smart_toy,
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  '다시 시도',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
                ),
              ),
            ] else if (type == ChatRoomType.counselor) ...[
              CustomButton(
                text: '상담사 찾기',
                onPressed: onFindCounselor,
                icon: Icons.search,
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  '다시 시도',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: '다시 시도',
                      onPressed: onRetry,
                      icon: Icons.refresh,
                      type: ButtonType.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomButton(
                      text: '새 채팅',
                      onPressed: onCreateAI,
                      icon: Icons.add,
                      type: ButtonType.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildEmptyState(
    ChatRoomType type,
    VoidCallback onCreateAI,
    VoidCallback onFindCounselor,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyIcon(type), size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 24.h),
            Text(
              _getEmptyTitle(type),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _getEmptyMessage(type),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            if (type == ChatRoomType.ai) ...[
              CustomButton(
                text: 'AI 상담 시작',
                onPressed: onCreateAI,
                icon: Icons.smart_toy,
              ),
            ] else if (type == ChatRoomType.counselor) ...[
              CustomButton(
                text: '상담사 찾기',
                onPressed: onFindCounselor,
                icon: Icons.search,
              ),
            ] else ...[
              CustomButton(
                text: 'AI 상담 시작',
                onPressed: onCreateAI,
                icon: Icons.smart_toy,
              ),
              SizedBox(height: 12.h),
              CustomButton(
                text: '상담사 찾기',
                onPressed: onFindCounselor,
                icon: Icons.search,
                type: ButtonType.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildErrorBanner(
    String error,
    VoidCallback onRefresh,
    WidgetRef ref,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 20.sp, color: AppColors.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '일부 채팅방을 불러오지 못했습니다',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatRoomsProvider.notifier).clearError();
              onRefresh();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              minimumSize: Size.zero,
            ),
            child: Text(
              '재시도',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(chatRoomsProvider.notifier).clearError(),
            icon: Icon(Icons.close, size: 16.sp, color: AppColors.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static IconData _getErrorIcon(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.ai:
        return Icons.smart_toy_outlined;
      case ChatRoomType.counselor:
        return Icons.people_outline;
      default:
        return Icons.error_outline;
    }
  }

  static IconData _getEmptyIcon(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.ai:
        return Icons.smart_toy_outlined;
      case ChatRoomType.counselor:
        return Icons.people_outline;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  static String _getErrorTitle(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.ai:
        return 'AI 채팅방을 불러올 수 없습니다';
      case ChatRoomType.counselor:
        return '상담사 채팅방을 불러올 수 없습니다';
      default:
        return '채팅 목록을 불러올 수 없습니다';
    }
  }

  static String _getEmptyTitle(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.ai:
        return 'AI 상담을 시작해보세요';
      case ChatRoomType.counselor:
        return '상담사와의 채팅이 없습니다';
      default:
        return '아직 진행 중인 채팅이 없습니다';
    }
  }

  static String _getErrorMessage(String error) {
    if (error.contains('네트워크') || error.contains('network')) {
      return '인터넷 연결을 확인해주세요';
    } else if (error.contains('서버') || error.contains('server')) {
      return '서버에 일시적인 문제가 있습니다\n잠시 후 다시 시도해주세요';
    } else if (error.contains('권한') || error.contains('authorization')) {
      return '로그인이 필요합니다\n다시 로그인해주세요';
    } else {
      return '일시적인 오류가 발생했습니다\n잠시 후 다시 시도해주세요';
    }
  }

  static String _getEmptyMessage(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.ai:
        return '24시간 언제든지 AI와 대화할 수 있습니다';
      case ChatRoomType.counselor:
        return '전문 상담사를 찾아 1:1 상담을 시작해보세요';
      default:
        return 'AI 상담이나 전문가와의 상담을 시작해보세요';
    }
  }
}
