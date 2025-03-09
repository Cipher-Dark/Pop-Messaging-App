import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

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

  const ChatState({
    this.status = ChatStatus.inital,
    this.error,
    this.receiveID,
    this.chatRoomID,
  });

  ChatState copyWith({
    ChatStatus? status,
    String? error,
    String? receiveID,
    String? chatRoomID,
  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiveID: receiveID ?? this.receiveID,
      chatRoomID: chatRoomID ?? this.chatRoomID,
    );
  }

  @override
  List<Object?> get props => [
        status,
        error,
        receiveID,
        chatRoomID
      ];
}
