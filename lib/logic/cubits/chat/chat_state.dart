import 'package:equatable/equatable.dart';
import 'package:pop_chat/data/models/chat_message_model.dart';

enum ChatStatus {
  loading,
  loaded,
  error,
  inital
}

class ChatState extends Equatable {
  final ChatStatus status;
  final String? error;
  final String? receiveID;
  final String? chatRoomID;
  final List<ChatMessageModel> messages;

  const ChatState({
    this.status = ChatStatus.inital,
    this.error,
    this.receiveID,
    this.chatRoomID,
    this.messages = const [],
  });

  ChatState copyWith({
    ChatStatus? status,
    String? error,
    String? receiveID,
    String? chatRoomID,
    List<ChatMessageModel>? messages,
  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiveID: receiveID ?? this.receiveID,
      chatRoomID: chatRoomID ?? this.chatRoomID,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props {
    return [
      status,
      error,
      receiveID,
      chatRoomID,
      messages,
    ];
  }
}
