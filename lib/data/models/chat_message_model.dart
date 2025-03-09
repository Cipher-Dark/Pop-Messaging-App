import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
}

enum MessageStatus {
  sent,
  read
}

class ChatMessageModel {
  final String id;
  final String chatRoomId;
  final String senderID;
  final String receiverID;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final Timestamp timestamp;
  final List<String> readBy;

  ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderID,
    required this.receiverID,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    required this.readBy,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      chatRoomId: data["chatRoomId"] as String,
      senderID: data["senderID"] as String,
      receiverID: data["receiverID"] as String,
      content: data["content"] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == data["type"],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == data["status"],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: data["timestamp"] as Timestamp,
      readBy: List<String>.from(data["readBy"] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "charRoomId": chatRoomId,
      "senderID": senderID,
      "receiverID": receiverID,
      "content": content,
      "type": type.toString(),
      "status": status.toString(),
      "timestamp": timestamp,
      "readBy": readBy,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? chatRoomId,
    String? senderID,
    String? receiverID,
    String? content,
    MessageType? type,
    MessageStatus? status,
    Timestamp? timestamp,
    List<String>? readBy,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderID: senderID ?? this.senderID,
      receiverID: receiverID ?? this.receiverID,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
    );
  }
}
