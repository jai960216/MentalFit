import 'package:hive/hive.dart';
import '../models/ai_chat_models.dart';
import 'package:uuid/uuid.dart';

class AIChatLocalService {
  static const String roomBoxName = 'ai_chat_rooms';
  static const String messageBoxName = 'ai_chat_messages';

  static Future<Box<AIChatRoom>> _roomBox() async =>
      await Hive.openBox<AIChatRoom>(roomBoxName);
  static Future<Box<AIChatMessage>> _messageBox() async =>
      await Hive.openBox<AIChatMessage>(messageBoxName);

  // 상담방 생성
  static Future<AIChatRoom> createRoom(String topic) async {
    final box = await _roomBox();
    final id = const Uuid().v4();
    final room = AIChatRoom(
      id: id,
      topic: topic,
      createdAt: DateTime.now(),
      lastMessage: null,
      lastMessageAt: null,
    );
    await box.put(id, room);
    return room;
  }

  // 상담방 목록
  static Future<List<AIChatRoom>> getRooms() async {
    final box = await _roomBox();
    final rooms = box.values.toList();
    rooms.sort(
      (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
        a.lastMessageAt ?? a.createdAt,
      ),
    );
    return rooms;
  }

  // 상담방 삭제
  static Future<void> deleteRoom(String roomId) async {
    final box = await _roomBox();
    final msgBox = await _messageBox();
    await box.delete(roomId);
    final msgs = msgBox.values.where((m) => m.roomId == roomId).toList();
    for (final m in msgs) {
      await m.delete();
    }
  }

  // 메시지 추가
  static Future<void> addMessage(
    String roomId,
    String role,
    String text,
  ) async {
    final msgBox = await _messageBox();
    final roomBox = await _roomBox();
    final msg = AIChatMessage(
      roomId: roomId,
      role: role,
      text: text,
      createdAt: DateTime.now(),
    );
    await msgBox.add(msg);
    // 방의 최근 메시지/시간 갱신
    final room = roomBox.get(roomId);
    if (room != null) {
      room.lastMessage = text;
      room.lastMessageAt = msg.createdAt;
      await room.save();
    }
  }

  // 메시지 목록(최신순)
  static Future<List<AIChatMessage>> getMessages(String roomId) async {
    final box = await _messageBox();
    final msgs = box.values.where((m) => m.roomId == roomId).toList();
    msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return msgs;
  }

  // 메시지 전체 삭제(방 삭제와 별개)
  static Future<void> deleteMessages(String roomId) async {
    final box = await _messageBox();
    final msgs = box.values.where((m) => m.roomId == roomId).toList();
    for (final m in msgs) {
      await m.delete();
    }
  }
}
