import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import 'ai_counseling_history_list.dart';
import '../../shared/services/ai_chat_local_service.dart';
import '../../shared/models/ai_chat_models.dart';
import '../../shared/widgets/theme_aware_widgets.dart';

class AiCounselingTopicGrid extends StatelessWidget {
  final List<Map<String, dynamic>> topics;
  final Function(String topicId) onSelect;

  const AiCounselingTopicGrid({
    super.key,
    required this.topics,
    required this.onSelect,
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
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : topic['color'].withOpacity(0.2),
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
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp, // 14.sp → 13.sp로 줄임
                    ),
                  ),
                  SizedBox(height: 4.h), // 2.h → 4.h로 늘림
                  Text(
                    topic['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7)
                              : AppColors.textSecondary,
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

class AiCounselingScreen extends StatelessWidget {
  const AiCounselingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        AIChatLocalService.migrateRoomIds(),
        AIChatLocalService.migrateRoomTopics(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<Map<String, dynamic>> topics = [
          {
            'id': 'anxiety',
            'title': '불안/스트레스',
            'description': '경기 전 불안과 스트레스 관리',
            'icon': Icons.psychology,
            'color': Colors.blue,
          },
          {
            'id': 'confidence',
            'title': '자신감/동기부여',
            'description': '자신감 향상과 동기부여',
            'icon': Icons.emoji_events,
            'color': Colors.orange,
          },
          {
            'id': 'focus',
            'title': '집중력/수행력',
            'description': '경기 중 집중력 향상',
            'icon': Icons.center_focus_strong,
            'color': Colors.green,
          },
          {
            'id': 'teamwork',
            'title': '팀워크/리더십',
            'description': '팀 내 관계와 리더십',
            'icon': Icons.group,
            'color': Colors.purple,
          },
          {
            'id': 'injury',
            'title': '부상/재활',
            'description': '부상 후 심리적 회복',
            'icon': Icons.healing,
            'color': Colors.red,
          },
          {
            'id': 'performance',
            'title': '경기력 향상',
            'description': '전체적인 경기력 개선',
            'icon': Icons.trending_up,
            'color': Colors.teal,
          },
        ];

        String getTopicTitle(String topicId) {
          final topic = topics.firstWhere(
            (t) => t['id'] == topicId,
            orElse: () => topics[0],
          );
          return topic['title'] as String;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('AI 스포츠심리상담'), centerTitle: true),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThemedText(
                    text: '어떤 도움이 필요하신가요?',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ThemedText(
                    text: '관심 있는 주제를 선택해주세요',
                    isPrimary: false,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 24.h),
                  AiCounselingTopicGrid(
                    topics: topics,
                    onSelect: (topicId) async {
                      // 방을 생성하지 않고, roomId 없이 AI 챗 화면으로 이동
                      context.push(
                        '${AppRoutes.aiChatRoom}/new',
                        extra: {
                          'type': 'ai',
                          'topicId': topicId,
                          'title':
                              topics.firstWhere(
                                (t) => t['id'] == topicId,
                              )['title'],
                          'topic': topicId, // topic을 extra로 전달
                        },
                      );
                    },
                  ),
                  // AI 상담 기록 섹션 제거 - 홈의 채팅 탭에서 확인하도록 변경
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
