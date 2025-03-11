import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool isReceiverTyping;
  final bool isReceiverOnline;
  final Timestamp? receiverLastSeen;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final bool isUserBloced;
  final bool amIBlocked;

  const ChatState({
    this.isReceiverTyping = false,
    this.isReceiverOnline = false,
    this.receiverLastSeen,
    this.hasMoreMessages = false,
    this.isLoadingMore = false,
    this.isUserBloced = false,
    this.amIBlocked = false,
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
    bool? isReceiverTyping,
    bool? isReceiverOnline,
    Timestamp? receiverLastSeen,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    bool? isUserBloced,
    bool? amIBlocked,
  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiveID: receiveID ?? this.receiveID,
      chatRoomID: chatRoomID ?? this.chatRoomID,
      messages: messages ?? this.messages,
      isReceiverTyping: isReceiverTyping ?? this.isReceiverTyping,
      isReceiverOnline: isReceiverOnline ?? this.isReceiverOnline,
      receiverLastSeen: receiverLastSeen ?? this.receiverLastSeen,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUserBloced: isUserBloced ?? this.isUserBloced,
      amIBlocked: amIBlocked ?? this.amIBlocked,
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
      isReceiverTyping,
      isReceiverOnline,
      receiverLastSeen,
      hasMoreMessages,
      isLoadingMore,
      isUserBloced,
      amIBlocked,
    ];
  }
}
