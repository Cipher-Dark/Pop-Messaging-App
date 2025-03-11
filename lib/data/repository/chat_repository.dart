import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pop_chat/data/models/chat_message_model.dart';
import 'package:pop_chat/data/models/chat_room_model.dart';
import 'package:pop_chat/data/models/user_model.dart';
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
      }
    } catch (e) {
      log("error in read message");
    }
  }

  Stream<Map<String, dynamic>> getUserOnlineStatus(String userId) {
    return firestore.collection("users").doc(userId).snapshots().map(
      (snapshot) {
        final data = snapshot.data();
        return {
          'isOnline': data?['isOnline'] ?? false,
          'lastSeen': data?['lastSeen'],
        };
      },
    );
  }

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await firestore.collection("users").doc(userId).update(
      {
        "isOnline": isOnline,
        'lastSeen': Timestamp.now(),
      },
    );
  }

  Future<void> updateTypingStatus(String chatRoomId, String userId, bool isTyping) async {
    try {
      final doc = await _chatRooms.doc(chatRoomId).get();
      if (!doc.exists) {
        return;
      }

      await _chatRooms.doc(chatRoomId).update(
        {
          'isTyping': isTyping,
          'isTypingUserID': isTyping ? userId : null,
        },
      );
    } catch (e) {
      log("Error in updateing typing status $e");
    }
  }

  Stream<Map<String, dynamic>> getTypingStatus(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {
          'isTyping': false,
          'isTypingUserID': null,
        };
      }
      final data = snapshot.data() as Map<String, dynamic>;
      return {
        "isTyping": data['isTyping'] ?? false,
        "isTypingUserID": data['isTypingUserID'],
      };
    });
  }

  Future<void> blockUser(String currentUserID, String blockUserId) async {
    final userRef = firestore.collection("users").doc(currentUserID);
    await userRef.update({
      'blockedUsers': FieldValue.arrayUnion(
        [
          blockUserId
        ],
      )
    });
  }

  Future<void> unBlockUser(String currentUserID, String blockUserId) async {
    final userRef = firestore.collection("users").doc(currentUserID);
    await userRef.update({
      'blockedUsers': FieldValue.arrayRemove(
        [
          blockUserId
        ],
      )
    });
  }

  Stream<bool> isUserBlocked(String currentUserId, String otherUserID) {
    return firestore.collection("users").doc(currentUserId).snapshots().map(
      (doc) {
        final userData = UserModel.fromFirestore(doc);
        return userData.blockedUsers.contains(otherUserID);
      },
    );
  }

  Stream<bool> amIBlocked(String currentUserId, String otherUserID) {
    return firestore.collection("users").doc(otherUserID).snapshots().map(
      (doc) {
        final userData = UserModel.fromFirestore(doc);
        return userData.blockedUsers.contains(currentUserId);
      },
    );
  }
}
