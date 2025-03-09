import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pop_chat/data/models/chat_message_model.dart';
import 'package:pop_chat/data/models/chat_room_model.dart';
import 'package:pop_chat/data/services/base_repository.dart';

class ChatRepository extends BaseRepository {
  CollectionReference get _charRooms => firestore.collection("chatRooms");

  CollectionReference getChatRoomMessage(String charRoomId) {
    return _charRooms.doc(charRoomId).collection("messages");
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

    final roomDoc = await _charRooms.doc(roomId).get();

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

    await _charRooms.doc(roomId).set(newRoom.toMap());
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
    batch.update(_charRooms.doc(chatRoomId), {
      "lastMessage": content,
      "lastMessageSenderID": senderID,
      "lastMessageTime": message.timestamp,
    });

    await batch.commit();
  }
}
