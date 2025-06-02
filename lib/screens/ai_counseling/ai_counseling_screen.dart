import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../../shared/widgets/custom_button.dart';

class AiCounselingScreen extends StatefulWidget {
  const AiCounselingScreen({super.key});

  @override
  State<AiCounselingScreen> createState() => _AiCounselingScreenState();
}

class _AiCounselingScreenState extends State<AiCounselingScreen> {
  String? selectedTopic;

  final List<Map<String, dynamic>> topics = [
    {
      'id': 'general',
      'title': '전체',
      'icon': Icons.apps,
      'color': AppColors.primary,
    },
    {
      'id': 'anxiety',
      'title': '불안',
      'icon': Icons.psychology,
      'color': AppColors.secondary,
    },
    {
      'id': 'stress',
      'title': '스트레스',
      'icon': Icons.flash_on,
      'color': AppColors.warning,
    },
    {
      'id': 'depression',
      'title': '우울',
      'icon': Icons.cloud,
      'color': AppColors.info,
    },
    {
      'id': 'confidence',
      'title': '자존감',
      'icon': Icons.favorite,
      'color': AppColors.error,
    },
  ];

  final List<Map<String, String>> previousChats = [
    {
      'title': '경기 전 불안감 관리',
      'date': '2025.05.29',
      'preview': '경기 전에 불안감이 너무 심해서 제 실력을 발휘하지 못하는 것 같아요...',
    },
    {
      'title': '팀원과의 갈등 해결',
      'date': '2025.05.25',
      'preview': '팀 내에서 의견 충돌이 있었는데, 어떻게 해결해야 할지 모르겠어요.',
    },
    {
      'title': '집중력 향상 방법',
      'date': '2025.05.20',
      'preview': '중요한 경기에서 집중력이 자꾸 흐트러져요. 어떻게 하면 좋을까요?',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI 상담'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 상담 기록 새로고침
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 더보기 메뉴
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상담 주제 선택 섹션
            Text(
              '상담 주제',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 16.h),

            // 주제 선택 그리드
            SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final isSelected = selectedTopic == topic['id'];

                  return Container(
                    width: 80.w,
                    margin: EdgeInsets.only(right: 12.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTopic = topic['id'];
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? topic['color']
                                      : AppColors.grey200,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              topic['icon'],
                              size: 28.sp,
                              color:
                                  isSelected
                                      ? AppColors.white
                                      : AppColors.grey600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            topic['title'],
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? topic['color']
                                      : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 32.h),

            // 이전 상담 기록 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이전 상담 기록',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // 전체보기
                  },
                  child: Text(
                    '전체보기',
                    style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 이전 상담 기록 리스트
            ...previousChats.map((chat) => _buildChatHistoryCard(chat)),

            SizedBox(height: 32.h),

            // 새 상담 시작하기 버튼
            CustomButton(
              text: '+ 새 상담 시작하기',
              onPressed: () {
                _startNewChat();
              },
              icon: Icons.add,
            ),

            SizedBox(height: 32.h),

            // AI 상담 이용 팁
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 20.sp,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'AI 상담 이용 팁',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '구체적인 상황과 감정을 설명할수록 더 정확한 상담을 받을 수 있습니다. 언제든지 대화 중에 주제를 변경하거나 더 깊이 있는 질문을 할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // 채팅 입력창
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '고민이나 질문을 입력해주세요...',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      // 메시지 전송
                    },
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        size: 18.sp,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistoryCard(Map<String, String> chat) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  chat['title']!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                chat['date']!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            chat['preview']!,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // 이어서 상담하기
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  '이어서 상담하기',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startNewChat() {
    // 새로운 상담 시작 로직
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('새 상담 시작'),
            content: Text(
              selectedTopic != null
                  ? '${topics.firstWhere((t) => t['id'] == selectedTopic)['title']} 주제로 새 상담을 시작하시겠습니까?'
                  : '새 상담을 시작하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 실제 채팅 화면으로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 상담이 시작되었습니다!')),
                  );
                },
                child: const Text('시작'),
              ),
            ],
          ),
    );
  }
}
