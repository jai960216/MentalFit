import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/services/openai_service.dart';
import '../../shared/models/ai_chat_models.dart';
import '../../shared/services/ai_chat_local_service.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'ai_counseling_topic_grid.dart';
import 'ai_counseling_history_list.dart';

class AiCounselingScreen extends StatefulWidget {
  const AiCounselingScreen({super.key});

  @override
  State<AiCounselingScreen> createState() => _AiCounselingScreenState();
}

class _AiCounselingScreenState extends State<AiCounselingScreen> {
  String? selectedTopic;
  int scenarioStep = 0;
  List<Map<String, String>> chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  bool isLoading = false;

  // === AI 상담방 목록 ===
  List<AIChatRoom> aiRooms = [];
  String? currentRoomId;

  final List<Map<String, dynamic>> topics = [
    {
      'id': 'general',
      'title': '전체',
      'icon': Icons.apps_rounded,
      'color': AppColors.primary,
      'description': '일반적인 고민이나 궁금한 점',
    },
    {
      'id': 'anxiety',
      'title': '불안',
      'icon': Icons.psychology_rounded,
      'color': AppColors.secondary,
      'description': '경기 전 불안, 긴장감, 걱정',
    },
    {
      'id': 'stress',
      'title': '스트레스',
      'icon': Icons.flash_on_rounded,
      'color': AppColors.warning,
      'description': '훈련, 경기, 일상 스트레스',
    },
    {
      'id': 'burnout',
      'title': '번아웃',
      'icon': Icons.local_fire_department_rounded,
      'color': AppColors.info,
      'description': '운동에 대한 의욕 상실, 피로감',
    },
    {
      'id': 'depression',
      'title': '우울',
      'icon': Icons.cloud_rounded,
      'color': AppColors.info,
      'description': '우울감, 무기력함, 슬픔',
    },
    {
      'id': 'confidence',
      'title': '자존감',
      'icon': Icons.favorite_rounded,
      'color': AppColors.error,
      'description': '자신감 부족, 자존감 향상',
    },
  ];

  // 전문적인 상담 시작 메시지
  Map<String, String> get topicStartMessages => {
    'anxiety': '''안녕하세요! 불안감과 관련된 고민으로 찾아주셨군요.

경기나 중요한 상황에서 불안을 느끼는 것은 매우 자연스러운 일이에요. 오히려 적절한 긴장감은 더 좋은 퍼포먼스를 이끌어내기도 하죠.

어떤 상황에서 주로 불안감을 느끼시는지, 그때 어떤 기분이 드시는지 편안하게 말씀해 주세요. 함께 차근차근 해결해나가보도록 해요.''',

    'confidence': '''안녕하세요! 자신감과 관련해서 고민이 있으시군요.

자신감은 하루아침에 생기는 것도, 영원히 유지되는 것도 아니에요. 누구나 자신감이 오르락내리락하는 경험을 하죠.

최근에 자신감이 떨어졌다고 느끼시나요, 아니면 전반적으로 자존감을 높이고 싶으신가요? 어떤 부분에서 어려움을 느끼고 계신지 들려주세요.''',

    'stress': '''안녕하세요! 스트레스로 힘든 시간을 보내고 계시는군요.

스트레스는 우리 삶에서 피할 수 없는 부분이에요. 중요한 것은 스트레스를 어떻게 건강하게 관리하느냐인 것 같아요.

최근에 어떤 부분에서 가장 많은 스트레스를 받고 계신가요? 훈련, 경기, 아니면 다른 요인 때문인지 궁금해요.''',

    'burnout': '''안녕하세요. 번아웃으로 힘드시겠어요.

그동안 정말 열심히 해오셨기 때문에 지금 이런 상태가 된 것 같아요. 번아웃은 게으름이나 의지력 부족이 아니라, 너무 열심히 해서 에너지가 고갈된 상태예요.

언제부터 이런 기분을 느끼기 시작하셨는지, 어떤 변화들을 경험하고 계신지 편안하게 말씀해 주세요.''',

    'depression': '''안녕하세요. 우울감으로 힘든 시간을 보내고 계시는군요.

먼저 이렇게 용기 내어 상담을 요청해 주신 것만으로도 정말 대단하다고 말씀드리고 싶어요. 우울한 기분은 누구에게나 찾아올 수 있어요.

지금 어떤 기분이 드시는지, 언제부터 이런 감정을 느끼기 시작하셨는지 천천히 들려주세요. 혼자가 아니에요.''',

    'general': '''안녕하세요! 스포츠 심리 상담에 오신 것을 환영합니다.

저는 다양한 운동선수들과 스포츠 애호가분들과 함께 고민을 나누고 해결책을 찾아온 스포츠 심리학자예요.

운동을 하다 보면 신체적인 면뿐만 아니라 정신적, 감정적으로도 많은 경험을 하게 되죠. 오늘은 어떤 고민이나 궁금한 점이 있어서 찾아오셨나요?''',
  };

  // 전문적인 조언 및 기법 제안
  Map<String, List<String>> get professionalTechniques => {
    'anxiety': [
      "4-7-8 호흡법: 4초 들이마시고, 7초 참고, 8초에 걸쳐 내쉬는 호흡법을 연습해보세요",
      "점진적 근육 이완법: 발끝부터 머리까지 순서대로 긴장을 주고 이완하는 연습을 해보세요",
      "긍정적 자기대화: '나는 할 수 있다', '지금 이 순간에 집중하자' 같은 격려 문구를 준비해보세요",
      "이미지 트레이닝: 성공적인 경기 모습을 머릿속으로 그려보며 자신감을 키워보세요",
    ],
    'stress': [
      "시간 관리: 훈련과 휴식의 균형을 맞춘 스케줄을 만들어보세요",
      "마음챙김 명상: 하루 10분씩 현재 순간에 집중하는 연습을 해보세요",
      "스트레스 일기: 언제, 어떤 상황에서 스트레스를 받는지 기록해보세요",
      "사회적 지지: 가족, 친구, 동료들과 고민을 나누는 시간을 가져보세요",
    ],
    'confidence': [
      "성취 일기: 매일 작은 성공이라도 기록하는 습관을 만들어보세요",
      "강점 찾기: 자신만의 특별한 능력이나 장점을 명확히 인식해보세요",
      "목표 세분화: 큰 목표를 작은 단계로 나누어 달성 가능한 목표를 설정해보세요",
      "긍정적 피드백: 스스로에게 칭찬하는 습관을 만들어보세요",
    ],
    'burnout': [
      "에너지 관리: 하루 중 에너지가 높은 시간과 낮은 시간을 파악해보세요",
      "의미 찾기: 운동을 하는 이유와 목적을 다시 생각해보세요",
      "작은 즐거움: 운동 외에도 작은 기쁨을 주는 활동들을 찾아보세요",
      "점진적 복귀: 무리하지 말고 천천히 운동 강도를 조절해보세요",
    ],
    'depression': [
      "활동 계획: 하루에 하나씩 작은 활동 목표를 세워보세요",
      "사회적 연결: 가족이나 친구와의 만남을 늘려보세요",
      "긍정적 활동: 기분을 좋게 만드는 활동 목록을 만들어보세요",
      "전문가 도움: 필요시 전문 상담사나 의료진의 도움을 받아보세요",
    ],
  };

  // 상담 진행을 위한 스마트 질문 생성
  List<String> _generateFollowUpQuestions(
    String topic,
    List<Map<String, String>> history,
  ) {
    final conversationLength = history.length;

    switch (topic) {
      case 'anxiety':
        if (conversationLength <= 2) {
          return [
            "불안감이 주로 언제 나타나나요? (경기 전, 훈련 중, 결과 발표 때 등)",
            "불안할 때 몸에서 느끼는 변화가 있나요? (심장 두근거림, 손 떨림, 긴장 등)",
          ];
        } else if (conversationLength <= 4) {
          return [
            "이전에 불안감을 줄이기 위해 시도해본 방법이 있다면 말씀해 주세요",
            "불안할 때 머릿속에 주로 어떤 생각들이 떠오르나요?",
          ];
        } else {
          return [
            "지금까지 말씀해주신 내용을 바탕으로 구체적인 대처 방법을 함께 만들어볼까요?",
            "호흡법이나 이미지 트레이닝 같은 기법에 관심이 있으신가요?",
          ];
        }

      case 'stress':
        if (conversationLength <= 2) {
          return [
            "스트레스의 주된 원인이 무엇인지 좀 더 구체적으로 말씀해 주세요",
            "스트레스를 받을 때 평소와 다른 행동이나 생각의 변화가 있나요?",
          ];
        } else if (conversationLength <= 4) {
          return [
            "현재 스트레스 해소를 위해 하고 계신 것이 있나요?",
            "스트레스가 운동 성과나 즐거움에 어떤 영향을 주고 있나요?",
          ];
        } else {
          return [
            "일상에서 실천할 수 있는 스트레스 관리 루틴을 만들어볼까요?",
            "마음챙김이나 명상 같은 방법에 대해 어떻게 생각하세요?",
          ];
        }

      case 'confidence':
        if (conversationLength <= 2) {
          return ["자신감이 떨어진 특별한 계기나 사건이 있었나요?", "자신감이 부족할 때 주로 어떤 생각을 하게 되나요?"];
        } else if (conversationLength <= 4) {
          return [
            "지금까지의 운동 경험에서 가장 자랑스러웠던 순간을 떠올려볼 수 있을까요?",
            "다른 사람들과 자신을 비교하는 편인가요?",
          ];
        } else {
          return [
            "작은 성공 경험들을 인식하고 기록하는 것에 대해 어떻게 생각하세요?",
            "긍정적인 자기대화 방법을 연습해볼까요?",
          ];
        }

      default:
        return [
          "좀 더 구체적으로 어떤 부분이 궁금하시거나 고민이 되시나요?",
          "이 문제가 운동이나 일상생활에 어떤 영향을 주고 있나요?",
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await AIChatLocalService.getRooms();
    setState(() {
      aiRooms = rooms;
    });
  }

  Future<void> _enterRoom(AIChatRoom room) async {
    final msgs = await AIChatLocalService.getMessages(room.id);
    setState(() {
      currentRoomId = room.id;
      selectedTopic = room.topic;
      chatHistory = msgs.map((m) => {'role': m.role, 'text': m.text}).toList();
      isLoading = false;
    });
  }

  Future<void> _startNewRoom() async {
    if (selectedTopic == null) return;
    final room = await AIChatLocalService.createRoom(selectedTopic!);

    // 첫 상담 시작 메시지 추가
    final startMessage =
        topicStartMessages[selectedTopic] ?? topicStartMessages['general']!;

    setState(() {
      currentRoomId = room.id;
      chatHistory = [
        {'role': 'assistant', 'text': startMessage},
      ];
      isLoading = false;
    });

    // 시작 메시지를 로컬 저장소에도 저장
    await AIChatLocalService.addMessage(room.id, 'assistant', startMessage);
    _loadRooms();
  }

  Future<void> _deleteRoom(String roomId) async {
    await AIChatLocalService.deleteRoom(roomId);
    if (currentRoomId == roomId) {
      setState(() {
        currentRoomId = null;
        chatHistory = [];
        selectedTopic = null;
      });
    }
    _loadRooms();
  }

  // topic id -> 한글 title 매핑 함수
  String getTopicTitle(String topicId) {
    final topic = topics.firstWhere(
      (t) => t['id'] == topicId,
      orElse: () => topics[0],
    );
    return topic['title'] ?? topicId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'AI 상담',
        centerTitle: true,
        backgroundColor: AppColors.white,
        titleColor: AppColors.textPrimary,
        leading:
            currentRoomId != null
                ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded, size: 20.sp),
                  onPressed: () {
                    setState(() {
                      currentRoomId = null;
                      chatHistory = [];
                      selectedTopic = null;
                    });
                    _loadRooms();
                  },
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22.sp),
            onPressed: () {
              setState(() {
                chatHistory.clear();
                scenarioStep = 0;
                currentRoomId = null;
                selectedTopic = null;
              });
              _loadRooms();
            },
          ),
          if (currentRoomId != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 22.sp),
              onSelected: (value) async {
                if (value == 'delete') {
                  if (currentRoomId != null) await _deleteRoom(currentRoomId!);
                } else if (value == 'techniques') {
                  _showTechniquesDialog();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'techniques',
                      child: Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('상담 기법 보기'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('대화방 삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: currentRoomId == null ? _buildRoomListUI() : _buildChatUI(),
      floatingActionButton:
          currentRoomId == null
              ? FloatingActionButton.extended(
                onPressed: () => _showTopicSelectDialog(),
                icon: Icon(Icons.add_rounded, size: 20.sp),
                label: Text(
                  '새 상담',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
              )
              : null,
    );
  }

  Widget _buildRoomListUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 안내/타이틀
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI 스포츠 심리 상담',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '전문 상담사와 같은 깊이 있는 대화',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // 2. 주제별 상담 버튼
            Text(
              '상담 주제 선택',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            AiCounselingTopicGrid(
              topics: topics,
              onSelect: (topicId) {
                setState(() {
                  selectedTopic = topicId;
                });
                _startNewRoom();
              },
            ),
            SizedBox(height: 32.h),

            // 3. 최근 상담 기록
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '최근 상담 기록',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (aiRooms.isNotEmpty)
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      '전체보기',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            AiCounselingHistoryList(
              aiRooms: aiRooms,
              topics: topics,
              getTopicTitle: getTopicTitle,
              onEnterRoom: (room) => _enterRoom(room),
            ),

            // 4. 상담 가이드
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '전문적인 상담을 위한 팁',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '• 솔직하고 구체적으로 상황을 설명해 주세요\n• 감정의 변화나 신체 반응도 함께 말씀해 주세요\n• 궁금한 점은 언제든 편하게 물어보세요\n• 상담 내용은 안전하게 보호됩니다',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.5,
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

  void _showTopicSelectDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '상담 주제를 선택해주세요',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '선택하신 주제에 맞는 전문 상담이 시작됩니다',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: topics.length,
                    itemBuilder: (context, idx) {
                      final topic = topics[idx];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTopic = topic['id'];
                          });
                          Navigator.pop(context);
                          _startNewRoom();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: topic['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: topic['color'].withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                topic['icon'],
                                color: topic['color'],
                                size: 18.sp,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                topic['title'],
                                style: TextStyle(
                                  color: topic['color'],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showTechniquesDialog() {
    if (selectedTopic == null) return;

    final techniques = professionalTechniques[selectedTopic] ?? [];
    if (techniques.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${getTopicTitle(selectedTopic!)} 상담 기법',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    constraints: BoxConstraints(maxHeight: 300.h),
                    child: SingleChildScrollView(
                      child: Column(
                        children:
                            techniques.map((technique) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  technique,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '닫기',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        // 상담 주제 표시 헤더
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                topics.firstWhere((t) => t['id'] == selectedTopic)['icon'],
                color: AppColors.primary,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '${getTopicTitle(selectedTopic!)} 상담',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '전문 상담사와 대화 중',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: _buildChatScenario(),
          ),
        ),
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _chatController,
                  hintText: '편안하게 말씀해 주세요...',
                  maxLines: null,
                  suffixIcon: Icons.send_rounded,
                  onSuffixIconPressed: _onSendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatScenario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...chatHistory.map((msg) => _buildChatBubble(msg)),
        if (isLoading)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '상담사가 답변 중...',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(18.r).copyWith(
            bottomRight: isUser ? Radius.circular(4.r) : null,
            bottomLeft: !isUser ? Radius.circular(4.r) : null,
          ),
          border: !isUser ? Border.all(color: AppColors.grey200) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg['text'] ?? '',
          style: TextStyle(
            fontSize: 14.sp,
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  void _onSendMessage() async {
    if (_chatController.text.trim().isEmpty || selectedTopic == null) return;
    final userMsg = _chatController.text.trim();
    setState(() {
      chatHistory.add({'role': 'user', 'text': userMsg});
      _chatController.clear();
      isLoading = true;
    });
    if (currentRoomId != null) {
      await AIChatLocalService.addMessage(currentRoomId!, 'user', userMsg);
    }

    // 개선된 전문 상담 시스템 사용
    try {
      final aiReply = await OpenAIService.sendMessage(
        chatHistory,
        topic: selectedTopic,
      );

      setState(() {
        chatHistory.add({
          'role': 'assistant',
          'text': aiReply ?? '죄송합니다. 일시적으로 응답을 생성할 수 없습니다. 잠시 후 다시 시도해 주세요.',
        });
        isLoading = false;
      });

      if (currentRoomId != null) {
        await AIChatLocalService.addMessage(
          currentRoomId!,
          'assistant',
          aiReply ?? '죄송합니다. 일시적으로 응답을 생성할 수 없습니다.',
        );
        _loadRooms();
      }
    } catch (e) {
      setState(() {
        chatHistory.add({
          'role': 'assistant',
          'text': '네트워크 오류가 발생했습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.',
        });
        isLoading = false;
      });

      if (currentRoomId != null) {
        await AIChatLocalService.addMessage(
          currentRoomId!,
          'assistant',
          '네트워크 오류가 발생했습니다.',
        );
        _loadRooms();
      }
    }
  }
}
