import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mentalfit/shared/models/chat_room_model.dart';

// ChatRoom 모델이 이미 Message를 export하고 있으므로 별도 import 불필요

/// Firebase 기반 실시간 채팅 서비스
/// Firestore + Firebase Storage + Firebase Auth 통합
class FirebaseChatService {
  static FirebaseChatService? _instance;

  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  late FirebaseAuth _auth;

  // 실시간 스트림 구독 관리
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  final Map<String, StreamController<List<Message>>> _messageStreamControllers =
      {};
  final Map<String, StreamController<Message>> _newMessageControllers = {};

  // 싱글톤 패턴
  FirebaseChatService._();

  static Future<FirebaseChatService> getInstance() async {
    if (_instance == null) {
      _instance = FirebaseChatService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    try {
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _auth = FirebaseAuth.instance;

      // Firebase 서비스 상태 확인
      await _checkFirebaseConnection();

      debugPrint('✅ FirebaseChatService 초기화 완료');
    } catch (e) {
      debugPrint('❌ FirebaseChatService 초기화 실패: $e');
      rethrow;
    }
  }

  /// Firebase 연결 상태 확인
  Future<void> _checkFirebaseConnection() async {
    try {
      // Firestore 연결 테스트
      await _firestore
          .collection('_health_check')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Firestore 연결 시간 초과'),
          );

      debugPrint('✅ Firebase 연결 확인 완료');
    } catch (e) {
      debugPrint('❌ Firebase 연결 실패: $e');
      throw Exception('Firebase에 연결할 수 없습니다: $e');
    }
  }

  // === 컬렉션 참조 ===
  CollectionReference get _chatRoomsCollection =>
      _firestore.collection('chat_rooms');
  CollectionReference _messagesCollection(String chatRoomId) => _firestore
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection('messages');

  // === 현재 사용자 정보 ===
  String? get _currentUserId => _auth.currentUser?.uid;
  String get _currentUserName => _auth.currentUser?.displayName ?? '사용자';

  // === 채팅방 관련 메서드 ===

  /// 사용자의 채팅방 목록 조회 (실시간 스트림)
  Stream<List<ChatRoom>> getChatRoomsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _chatRoomsCollection
        .where('participantIds', arrayContains: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return ChatRoom.fromJson(data);
            } catch (e) {
              debugPrint('채팅방 파싱 오류: $e');
              return _createFallbackChatRoom(doc.id);
            }
          }).toList();
        });
  }

  /// 채팅방 목록 조회 (일회성)
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      if (_currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final snapshot =
          await _chatRoomsCollection
              .where('participantIds', arrayContains: _currentUserId)
              .orderBy('updatedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ChatRoom.fromJson(data);
        } catch (e) {
          debugPrint('채팅방 파싱 오류: $e');
          return _createFallbackChatRoom(doc.id);
        }
      }).toList();
    } catch (e) {
      debugPrint('채팅방 목록 조회 오류: $e');
      // 오류 시 기본 AI 채팅방 반환
      return [await _createDefaultAIChatRoom()];
    }
  }

  /// 특정 채팅방 정보 조회
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _chatRoomsCollection.doc(chatRoomId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ChatRoom.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('채팅방 정보 조회 오류: $e');
      return null;
    }
  }

  /// 새 채팅방 생성
  Future<ChatRoom> createChatRoom({
    required String title,
    required ChatRoomType type,
    String? counselorId,
    String? topic,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final now = DateTime.now();
      final participantIds = [_currentUserId!];

      // 상담사 추가
      if (counselorId != null) {
        participantIds.add(counselorId);
      }

      final chatRoomData = {
        'title': title,
        'type': type.value,
        'participantIds': participantIds,
        'counselorId': counselorId,
        'topic': topic,
        'unreadCount': 0,
        'status': ChatRoomStatus.active.value,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _chatRoomsCollection.add(chatRoomData);

      final newChatRoom = ChatRoom(
        id: docRef.id,
        title: title,
        type: type,
        participantIds: participantIds,
        counselorId: counselorId,
        topic: topic,
        unreadCount: 0,
        status: ChatRoomStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      return newChatRoom;
    } catch (e) {
      debugPrint('채팅방 생성 오류: $e');
      throw Exception('채팅방 생성에 실패했습니다: $e');
    }
  }

  /// 채팅방 삭제
  Future<bool> deleteChatRoom(String chatRoomId) async {
    try {
      // 메시지 컬렉션 삭제
      final messagesSnapshot = await _messagesCollection(chatRoomId).get();
      final batch = _firestore.batch();

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 채팅방 문서 삭제
      batch.delete(_chatRoomsCollection.doc(chatRoomId));

      await batch.commit();

      // 스트림 정리
      _cleanupChatRoomStreams(chatRoomId);

      return true;
    } catch (e) {
      debugPrint('채팅방 삭제 오류: $e');
      return false;
    }
  }

  // === 메시지 관련 메서드 ===

  /// 메시지 목록 실시간 스트림
  Stream<List<Message>> getMessagesStream(String chatRoomId) {
    // 기존 스트림이 있으면 재사용
    if (_messageStreamControllers.containsKey(chatRoomId)) {
      return _messageStreamControllers[chatRoomId]!.stream;
    }

    // 새 스트림 컨트롤러 생성
    final controller = StreamController<List<Message>>.broadcast();
    _messageStreamControllers[chatRoomId] = controller;

    // Firestore 스트림 구독
    final subscription = _messagesCollection(chatRoomId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final messages =
                  snapshot.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return Message.fromJson(data);
                  }).toList();

              controller.add(messages);
            } catch (e) {
              debugPrint('메시지 스트림 파싱 오류: $e');
              controller.addError(e);
            }
          },
          onError: (error) {
            debugPrint('메시지 스트림 오류: $error');
            controller.addError(error);
          },
        );

    _streamSubscriptions['messages_$chatRoomId'] = subscription;

    return controller.stream;
  }

  /// 메시지 목록 조회 (일회성)
  Future<List<Message>> getMessages(String chatRoomId) async {
    try {
      final snapshot =
          await _messagesCollection(
            chatRoomId,
          ).orderBy('timestamp', descending: false).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Message.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('메시지 목록 조회 오류: $e');
      return [];
    }
  }

  /// 메시지 전송
  Future<Message> sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final now = DateTime.now();
      final messageData = {
        'chatRoomId': chatRoomId,
        'senderId': _currentUserId!,
        'senderName': _currentUserName,
        'content': content,
        'type': type.value,
        'timestamp': Timestamp.fromDate(now),
        'isRead': false,
        'metadata': metadata ?? {},
      };

      // 메시지 저장
      final docRef = await _messagesCollection(chatRoomId).add(messageData);

      // 채팅방 업데이트 (마지막 메시지, 업데이트 시간)
      await _updateChatRoomLastMessage(chatRoomId, messageData);

      final message = Message(
        id: docRef.id,
        chatRoomId: chatRoomId,
        senderId: _currentUserId!,
        senderName: _currentUserName,
        content: content,
        type: type,
        timestamp: now,
        isRead: false,
        metadata: metadata,
      );

      return message;
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
      throw Exception('메시지 전송에 실패했습니다: $e');
    }
  }

  /// 메시지 읽음 처리
  Future<bool> markMessagesAsRead(String chatRoomId) async {
    try {
      if (_currentUserId == null) return false;

      // 읽지 않은 메시지들을 일괄 업데이트
      final unreadSnapshot =
          await _messagesCollection(chatRoomId)
              .where('isRead', isEqualTo: false)
              .where('senderId', isNotEqualTo: _currentUserId)
              .get();

      if (unreadSnapshot.docs.isEmpty) return true;

      final batch = _firestore.batch();
      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // 채팅방의 읽지 않은 메시지 수 리셋
      await _chatRoomsCollection.doc(chatRoomId).update({'unreadCount': 0});

      return true;
    } catch (e) {
      debugPrint('메시지 읽음 처리 오류: $e');
      return false;
    }
  }

  // === 파일/이미지 전송 관련 ===

  /// 이미지 업로드 및 메시지 전송
  Future<Message> sendImageMessage({
    required String chatRoomId,
    required File imageFile,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // Firebase Storage에 이미지 업로드
      final imageUrl = await _uploadImageToStorage(chatRoomId, imageFile);

      // 이미지 메시지 전송
      return await sendMessage(
        chatRoomId: chatRoomId,
        content: imageUrl,
        type: MessageType.image,
        metadata: {
          'fileName': imageFile.path.split('/').last,
          'fileSize': await imageFile.length(),
        },
      );
    } catch (e) {
      debugPrint('이미지 메시지 전송 오류: $e');
      throw Exception('이미지 전송에 실패했습니다: $e');
    }
  }

  /// 파일 업로드 및 메시지 전송
  Future<Message> sendFileMessage({
    required String chatRoomId,
    required File file,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // Firebase Storage에 파일 업로드
      final fileUrl = await _uploadFileToStorage(chatRoomId, file);

      // 파일 메시지 전송
      return await sendMessage(
        chatRoomId: chatRoomId,
        content: fileUrl,
        type: MessageType.file,
        metadata: {
          'fileName': file.path.split('/').last,
          'fileSize': await file.length(),
        },
      );
    } catch (e) {
      debugPrint('파일 메시지 전송 오류: $e');
      throw Exception('파일 전송에 실패했습니다: $e');
    }
  }

  // === Private Helper Methods ===

  /// Firebase Storage에 이미지 업로드
  Future<String> _uploadImageToStorage(
    String chatRoomId,
    File imageFile,
  ) async {
    try {
      final fileName =
          'images/${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg';
      final ref = _storage.ref().child('chat_files/$chatRoomId/$fileName');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('이미지 업로드 오류: $e');
      throw Exception('이미지 업로드에 실패했습니다: $e');
    }
  }

  /// Firebase Storage에 파일 업로드
  Future<String> _uploadFileToStorage(String chatRoomId, File file) async {
    try {
      final fileName =
          'files/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('chat_files/$chatRoomId/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('파일 업로드 오류: $e');
      throw Exception('파일 업로드에 실패했습니다: $e');
    }
  }

  /// 채팅방 마지막 메시지 업데이트
  Future<void> _updateChatRoomLastMessage(
    String chatRoomId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      final updateData = {
        'lastMessage': messageData,
        'updatedAt': Timestamp.now(),
      };

      await _chatRoomsCollection.doc(chatRoomId).update(updateData);
    } catch (e) {
      debugPrint('채팅방 마지막 메시지 업데이트 오류: $e');
    }
  }

  /// 기본 AI 채팅방 생성
  Future<ChatRoom> _createDefaultAIChatRoom() async {
    try {
      return await createChatRoom(
        title: 'AI 상담',
        type: ChatRoomType.ai,
        topic: '일반 상담',
      );
    } catch (e) {
      // 생성 실패 시 로컬 객체 반환
      return ChatRoom(
        id: 'ai_chat_default',
        title: 'AI 상담',
        type: ChatRoomType.ai,
        participantIds: [_currentUserId ?? 'guest', 'ai'],
        topic: '일반 상담',
        unreadCount: 0,
        status: ChatRoomStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// 폴백 채팅방 생성
  ChatRoom _createFallbackChatRoom(String chatRoomId) {
    return ChatRoom(
      id: chatRoomId,
      title: '채팅방',
      type: ChatRoomType.ai,
      participantIds: [_currentUserId ?? 'guest'],
      unreadCount: 0,
      status: ChatRoomStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 특정 채팅방의 스트림 정리
  void _cleanupChatRoomStreams(String chatRoomId) {
    // 메시지 스트림 정리
    _streamSubscriptions['messages_$chatRoomId']?.cancel();
    _streamSubscriptions.remove('messages_$chatRoomId');

    _messageStreamControllers[chatRoomId]?.close();
    _messageStreamControllers.remove(chatRoomId);

    _newMessageControllers[chatRoomId]?.close();
    _newMessageControllers.remove(chatRoomId);
  }

  /// 리소스 정리
  Future<void> dispose() async {
    try {
      // 모든 스트림 구독 취소
      for (final subscription in _streamSubscriptions.values) {
        await subscription.cancel();
      }
      _streamSubscriptions.clear();

      // 모든 스트림 컨트롤러 종료
      for (final controller in _messageStreamControllers.values) {
        await controller.close();
      }
      _messageStreamControllers.clear();

      for (final controller in _newMessageControllers.values) {
        await controller.close();
      }
      _newMessageControllers.clear();

      debugPrint('✅ FirebaseChatService 리소스 정리 완료');
    } catch (e) {
      debugPrint('❌ FirebaseChatService 정리 오류: $e');
    }
  }
}
