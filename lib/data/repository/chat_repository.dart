import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pop_chat/data/models/chat_message_model.dart';
import 'package:pop_chat/data/models/chat_room_model.dart';
import 'package:pop_chat/data/services/base_repository.dart';

class ChatRepository extends BaseRepository {
  CollectionReference get _chatRooms => firestore.collection("chatRooms");

  CollectionReference getChatRoomMessage(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).collection("messages");
  }

  Future<ChatRoomModel> getOrCreateChatRoom(
    String currentUserID,
    String otherUserId,
  ) async {
    final users = [
      currentUserID,
      otherUserId
    ]..sort();
    final roomId = users.join("_");

    final roomDoc = await _chatRooms.doc(roomId).get();

    if (roomDoc.exists) {
      return ChatRoomModel.fromFirestore(roomDoc);
    }
    final currentUserData = (await firestore.collection("users").doc(currentUserID).get()).data() as Map<String, dynamic>;

    final otherUserData = (await firestore.collection("users").doc(otherUserId).get()).data() as Map<String, dynamic>;

    final participantsName = {
      currentUserID: currentUserData['fullName']?.toString() ?? "",
      otherUserId: otherUserData['fullName']?.toString() ?? "",
    };
    final newRoom = ChatRoomModel(
      id: roomId,
      participants: users,
      participantsName: participantsName,
      lastReadTime: {
        currentUserID: Timestamp.now(),
        otherUserId: Timestamp.now(),
      },
    );

    await _chatRooms.doc(roomId).set(newRoom.toMap());
    return newRoom;
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderID,
    required String receiverID,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    //batch
    final batch = firestore.batch();

    //get message sub collection
    final messageRef = getChatRoomMessage(chatRoomId);
    final messageDoc = messageRef.doc();

    //chat message
    final message = ChatMessageModel(
      id: messageDoc.id,
      chatRoomId: chatRoomId,
      senderID: senderID,
      type: type,
      receiverID: receiverID,
      content: content,
      timestamp: Timestamp.now(),
      readBy: [
        senderID
      ],
    );

    // add message to sub collection
    batch.set(messageDoc, message.toMap());

    //update chatroom
    batch.update(_chatRooms.doc(chatRoomId), {
      "lastMessage": content,
      "lastMessageSenderID": senderID,
      "lastMessageTime": message.timestamp,
    });

    await batch.commit();
  }

  Stream<List<ChatMessageModel>> getMessages(
    String chatRoomId, {
    DocumentSnapshot? lastDocument,
  }) {
    var query = getChatRoomMessage(chatRoomId)
        .orderBy(
          'timestamp',
          descending: true,
        )
        .limit(20);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList(),
        );
  }

  Future<List<ChatMessageModel>> getMoreMessages(
    String chatRoomId, {
    required DocumentSnapshot lastDocument,
  }) async {
    final query = getChatRoomMessage(chatRoomId)
        .orderBy(
          'timestamp',
          descending: true,
        )
        .startAfterDocument(lastDocument)
        .limit(20);

    final snapshot = await query.get();

    return snapshot.docs
        .map(
          (doc) => ChatMessageModel.fromFirestore(doc),
        )
        .toList();
  }

  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    // chatRoom --> participants --> userID
    return _chatRooms.where("participants", arrayContains: userId).orderBy("lastMessageTime", descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ChatRoomModel.fromFirestore(doc),
              )
              .toList(),
        );
  }

  Stream<int> getUnreadCount(String chatRoomId, String userId) {
    return getChatRoomMessage(chatRoomId).where("receiverID", isEqualTo: userId).where("status", isEqualTo: MessageStatus.sent.toString()).snapshots().map(
          (snapshot) => snapshot.docs.length,
        );
  }

  Future<void> markMessageAsRead(String chatRoomId, String userId) async {
    try {
      final batch = firestore.batch();

      // get all unread message where user is receiver

      final unreadMessage = await getChatRoomMessage(chatRoomId)
          .where("receiverID", isEqualTo: userId)
          .where(
            "status",
            isEqualTo: MessageStatus.sent.toString(),
          )
          .get();

      for (final doc in unreadMessage.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([
            userId
          ]),
          'status': MessageStatus.read.toString(),
        });
        await batch.commit();
        log("Marked messages as read for user id $userId");
      }
    } catch (e) {}
  }
}
