import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../../shared/models/ai_chat_models.dart';
import '../../shared/services/ai_chat_local_service.dart';

class AiCounselingHistoryList extends StatelessWidget {
  final List<AIChatRoom> aiRooms;
  final List<Map<String, dynamic>> topics;
  final String Function(String topicId) getTopicTitle;
  final Function(AIChatRoom room) onEnterRoom;
  final Function()? onRoomDeleted;
  const AiCounselingHistoryList({
    required this.aiRooms,
    required this.topics,
    required this.getTopicTitle,
    required this.onEnterRoom,
    this.onRoomDeleted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (aiRooms.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16.h),
            Text(
              '아직 상담 기록이 없어요',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '주제를 선택해 AI와와 대화를 시작해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: aiRooms.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, idx) {
        final room = aiRooms[idx];
        final topicTitle = getTopicTitle(room.topic);
        final topic = topics.firstWhere(
          (t) => t['id'] == room.topic,
          orElse: () => topics[0],
        );
        return Dismissible(
          key: ValueKey(room.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.8),
                ],
                stops: const [0.0, 0.7, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(-2, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
          onDismissed: (_) async {
            await AIChatLocalService.deleteRoom(room.id);
            if (onRoomDeleted != null) onRoomDeleted!();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey200),
            ),
            child: ListTile(
              onTap: () => onEnterRoom(room),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: topic['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(topic['icon'], color: topic['color'], size: 20.sp),
              ),
              title: Text(
                topicTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  room.lastMessage ?? '새로운 상담',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    room.lastMessageAt != null
                        ? '${room.lastMessageAt!.month}/${room.lastMessageAt!.day}'
                        : '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18.sp,
                    color: AppColors.textHint,
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
