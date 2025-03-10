import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pop_chat/data/repository/chat_repository.dart';
import 'package:pop_chat/logic/cubits/chat/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  final String currentUserID;

  StreamSubscription? _messageSubscription;

  ChatCubit({
    required ChatRepository chatRepository,
    required this.currentUserID,
  })  : _chatRepository = chatRepository,
        super(const ChatState());

  void enterChat(String recieverID) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final chatRoom = await _chatRepository.getOrCreateChatRoom(
        currentUserID,
        recieverID,
      );
      emit(state.copyWith(
        chatRoomID: chatRoom.id,
        receiveID: recieverID,
        status: ChatStatus.loaded,
      ));

      _subscribeToMessages(chatRoom.id);
    } catch (e) {
      emit(
        state.copyWith(status: ChatStatus.error, error: "Failed to create chat room $e"),
      );
    }
  }

  Future<void> sendMessage({
    required String content,
    required String receiverID,
  }) async {
    if (state.chatRoomID == null) return;

    try {
      await _chatRepository.sendMessage(
        chatRoomId: state.chatRoomID!,
        senderID: currentUserID,
        receiverID: receiverID,
        content: content,
      );
    } catch (e) {
      emit(state.copyWith(error: "Fail to send message", status: ChatStatus.inital));
    }
  }

  void _subscribeToMessages(String chatRoomId) {
    _messageSubscription?.cancel();
    _messageSubscription = _chatRepository.getMessages(chatRoomId).listen((messages) {
      emit(
        state.copyWith(
          messages: messages,
          error: null,
        ),
      );
    }, onError: (error) {
      emit(
        state.copyWith(error: "Failed to load messages $error", status: ChatStatus.error),
      );
    });
  }
}
