import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';
import '../../shared/services/ai_chat_local_service.dart';
import '../../shared/services/openai_service.dart';
import '../../shared/models/ai_chat_models.dart';
import '../../providers/chat_provider.dart';
import 'package:go_router/go_router.dart';

class AiChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const AiChatRoomScreen({required this.roomId, Key? key}) : super(key: key);

  @override
  ConsumerState<AiChatRoomScreen> createState() => _AiChatRoomScreenState();
}

class _AiChatRoomScreenState extends ConsumerState<AiChatRoomScreen> {
  List<AIChatMessage> messages = [];
  String? topic;
  String? realRoomId;
  final controller = TextEditingController();
  bool isLoading = false;
  final scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (realRoomId != null) {
      debugPrint('[AIChat] realRoomId가 이미 설정됨: $realRoomId');
      return;
    }
    
    if (widget.roomId != 'new') {
      realRoomId = widget.roomId;
      debugPrint('[AIChat] 기존 방으로 설정: $realRoomId');
      _loadRoomAndMessages();
    } else {
      // GoRouter의 extra에서 topic 추출
      final state = GoRouterState.of(context);
      if (state.extra is Map && (state.extra as Map).containsKey('topic')) {
        topic = (state.extra as Map)['topic'] as String?;
        debugPrint('[AIChat] extra에서 topic 추출: $topic');
      }
      
      // topic이 있으면 방 생성 준비
      if (topic != null && topic!.isNotEmpty) {
        debugPrint('[AIChat] 새로운 방 생성을 위한 topic 설정: $topic');
      } else {
        debugPrint('[AIChat] 경고: topic이 설정되지 않음');
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomAndMessages() async {
    // topic이 null이면 GoRouter의 extra에서 한 번 더 가져오기
    if (realRoomId == null && topic == null) {
      final state = GoRouterState.of(context);
      if (state.extra is Map && (state.extra as Map).containsKey('topic')) {
        topic = (state.extra as Map)['topic'] as String?;
      }
    }
    
    // realRoomId가 없으면 메시지를 불러올 수 없음
    if (realRoomId == null || realRoomId!.isEmpty) {
      debugPrint('[AIChat] roomId가 없어서 메시지를 불러올 수 없음');
      return;
    }
    
    try {
      debugPrint('[AIChat] 메시지 불러오기: roomId=$realRoomId');
      final msgs = await AIChatLocalService.getMessages(realRoomId!);
      debugPrint('[AIChat] 불러온 메시지 수: ${msgs.length}');
      
      // 방 정보 확인
      final rooms = await AIChatLocalService.getRooms();
      final room = rooms.firstWhere(
        (r) => r.id == realRoomId,
        orElse: () => AIChatRoom(
          id: '',
          topic: topic ?? '',
          createdAt: DateTime.now(),
        ),
      );
      
      setState(() {
        messages = msgs;
        // room.id가 비어있으면 기존 topic 유지
        topic = (room.id.isNotEmpty && room.topic.isNotEmpty) ? room.topic : topic;
      });

      // 메시지가 0개이고 topic이 있으면 AI 인사 메시지 추가
      if (msgs.isEmpty && topic != null && topic!.isNotEmpty) {
        final startMsg = OpenAIService().topicStartMessages[topic!] ?? '안녕하세요. 편하게 말씀해 주세요.';
        await AIChatLocalService.addMessage(realRoomId!, 'assistant', startMsg);
        // 메시지 추가 후 다시 불러오기
        final newMsgs = await AIChatLocalService.getMessages(realRoomId!);
        setState(() {
          messages = newMsgs;
        });
        debugPrint('[AIChat] AI 인사 메시지 추가 완료');
      }
      
      _scrollToBottom();
    } catch (e) {
      debugPrint('[AIChat] 메시지 불러오기 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 로딩 중 오류가 발생했습니다: $e'))
      );
    }
  }

  Future<void> _ensureRoomAndWelcomeMessage() async {
    if (realRoomId != null) {
      debugPrint('[AIChat] 방이 이미 존재함: $realRoomId');
      return;
    }
    if (topic == null) {
      debugPrint('[AIChat] topic이 없어서 방을 생성할 수 없음');
      return;
    }
    
    try {
      // 방 생성
      final mappedTopic = OpenAIService.mapTopicForPrompt(topic ?? 'general');
      debugPrint('[AIChat] 방 생성 시작: topic=$topic, mapped=$mappedTopic');
      final room = await AIChatLocalService.createRoom(mappedTopic);
      realRoomId = room.id;
      debugPrint('[AIChat] 방 생성 완료: $realRoomId');
      
      // AI 인사 메시지 추가
      final startMsg = OpenAIService().topicStartMessages[topic!] ?? '안녕하세요. 편하게 말씀해 주세요.';
      await AIChatLocalService.addMessage(realRoomId!, 'assistant', startMsg);
      debugPrint('[AIChat] AI 인사 메시지 추가 완료');
      
      await _loadRoomAndMessages();
    } catch (e) {
      debugPrint('[AIChat] 방 생성 및 인사 메시지 추가 오류: $e');
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    print('[AIChat] _sendMessage 호출됨');
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() => isLoading = true);
    controller.clear();

    try {
      // 방이 없으면 먼저 생성
      if (realRoomId == null) {
        final mappedTopic = OpenAIService.mapTopicForPrompt(topic ?? 'general');
        debugPrint('[AIChat] 방 생성 시 topic: $topic, mapped: $mappedTopic');
        final room = await AIChatLocalService.createRoom(mappedTopic);
        realRoomId = room.id;
        debugPrint('[AIChat] 방 생성 완료: $realRoomId');
      }

      // 사용자 메시지 저장
      debugPrint('[AIChat] 사용자 메시지 저장: $text');
      await AIChatLocalService.addMessage(realRoomId!, 'user', text);
      
      // 메시지 목록 새로고침
      await _loadRoomAndMessages();

      // 최신 메시지 목록으로 히스토리 구성
      final currentMessages = await AIChatLocalService.getMessages(realRoomId!);
      final history = currentMessages
          .map(
            (m) => {
              'role': m.role == 'user' ? 'user' : 'assistant',
              'content': m.text,
            },
          )
          .toList();

      debugPrint(
        '[AIChat] OpenAIService 호출: history=${history.length}, topic=$topic',
      );
      
      // AI 응답 요청
      final aiResponse = await OpenAIService.sendMessage(history, topic: topic);
      debugPrint('[AIChat] OpenAIService 응답: $aiResponse');

      if (aiResponse == null || aiResponse.isEmpty) {
        throw Exception('AI 응답을 받지 못했습니다.');
      }

      // AI 응답 저장
      debugPrint('[AIChat] AI 응답 저장: $aiResponse');
      await AIChatLocalService.addMessage(realRoomId!, 'assistant', aiResponse);

      // 최종 메시지 목록 새로고침
      await _loadRoomAndMessages();
      _scrollToBottom();
      
      // 채팅 목록 업데이트
      ref.read(chatListProvider.notifier).refreshAIChatRooms();
      
    } catch (e) {
      debugPrint('[AIChat] GPT 호출 오류: $e');
      // 오류 메시지 저장
      if (realRoomId != null) {
        await AIChatLocalService.addMessage(
          realRoomId!,
          'assistant',
          '죄송합니다. AI 답변 생성에 문제가 발생했습니다.\n(오류: $e)',
        );
        await _loadRoomAndMessages();
        _scrollToBottom();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI 답변 생성 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 새로운 방이고 아직 방이 생성되지 않았으며 topic이 있으면 방 생성
    if (widget.roomId == 'new' && realRoomId == null && topic != null && topic!.isNotEmpty) {
      debugPrint('[AIChat] 새로운 방 생성 시작: topic=$topic');
      Future.microtask(() => _ensureRoomAndWelcomeMessage());
    }
    
    debugPrint('[AIChat] build 호출됨 - realRoomId: $realRoomId, messages: ${messages.length}개');
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 상담'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await AIChatLocalService.deleteRoom(widget.roomId);
                // 채팅 목록 업데이트
                ref.read(chatListProvider.notifier).refreshAIChatRooms();
                if (mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: 'delete', child: Text('채팅방 삭제')),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: messages.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message.role == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    constraints: BoxConstraints(maxWidth: 0.75.sw),
                    child: Text(
                      message.text,
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(strokeWidth: 2.w),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'AI가 응답을 생성하고 있습니다...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 12.w),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            print('[AIChat] 전송 버튼 클릭됨');
                            _sendMessage();
                          },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
