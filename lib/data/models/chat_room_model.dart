import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSenderID;
  final Timestamp? lastMessageTime;
  final Map<String, Timestamp>? lastReadTime;
  final Map<String, String>? participantsName;
  final bool isTyping;
  final String? typingUserID;
  final bool isCallActive;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderID,
    this.lastMessageTime,
    Map<String, Timestamp>? lastReadTime,
    Map<String, String>? participantsName,
    this.isTyping = false,
    this.typingUserID,
    this.isCallActive = false,
  })  : lastReadTime = lastReadTime ?? {},
        participantsName = participantsName ?? {};

  Map<String, dynamic> toMap() {
    return {
      "participants": participants,
      "lastMessage": lastMessage,
      "lastMessageSenderID": lastMessageSenderID,
      "lastMessageTime": lastMessageTime,
      "lastReadTime": lastReadTime,
      "isTyping": isTyping,
      "participantsName": participantsName,
      "isTypingUserID": typingUserID,
      "isCallActive": isCallActive,
    };
  }

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      participants: List<String>.from(data["participants"]),
      lastMessage: data["lastMessage"] ?? "",
      lastMessageSenderID: data["lastMessageSenderID"] ?? "",
      lastMessageTime: data["lastMessageTime"],
      lastReadTime: Map<String, Timestamp>.from(
        data["lastReadTime"] ?? {},
      ),
      participantsName: Map<String, String>.from(
        data["participantsName"] ?? {},
      ),
      isTyping: data["isTyping"] ?? "",
      typingUserID: data["isTypingUserID"],
      isCallActive: data["isCallActive"],
    );
  }
}
