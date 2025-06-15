import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';

class ChatListWidgets {
  static Widget buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('채팅'), backgroundColor: AppColors.white),
      body: buildLoading('채팅 불러오는 중...'),
    );
  }

  static Widget buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  static Widget buildChatRoomCard(
    ChatRoom chatRoom,
    User? user,
    Function(ChatRoom) onTap,
    Function(ChatRoom) onLongPress,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(chatRoom),
          onLongPress: () => onLongPress(chatRoom),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey400.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildAvatar(chatRoom),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatRoom.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chatRoom.unreadCount > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                chatRoom.unreadCount > 99
                                    ? '99+'
                                    : chatRoom.unreadCount.toString(),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (chatRoom.lastMessage != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          chatRoom.lastMessage!.content,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatTime(chatRoom.lastMessage!.timestamp),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildAvatar(ChatRoom chatRoom) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color:
            chatRoom.type == ChatRoomType.ai
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Icon(
        chatRoom.type == ChatRoomType.ai ? Icons.smart_toy : Icons.person,
        size: 24.sp,
        color:
            chatRoom.type == ChatRoomType.ai
                ? AppColors.primary
                : AppColors.secondary,
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
