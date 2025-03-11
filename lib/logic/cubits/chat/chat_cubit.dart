import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pop_chat/data/repository/chat_repository.dart';
import 'package:pop_chat/logic/cubits/chat/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  final String currentUserID;
  bool _isInChat = false;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _onlineStatusSubscription;
  StreamSubscription? _typingSubscription;
  Timer? typingTimer;

  ChatCubit({
    required ChatRepository chatRepository,
    required this.currentUserID,
  })  : _chatRepository = chatRepository,
        super(const ChatState());

  void enterChat(String recieverID) async {
    _isInChat = true;
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
      _subscribeToOnlineStatus(recieverID);
      _subscribeToTypingStatus(chatRoom.id);
      await _chatRepository.updateOnlineStatus(currentUserID, true);
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
      if (_isInChat) {
        _markMessagesAsRead(chatRoomId);
      }
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

  void _subscribeToOnlineStatus(String userId) {
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = _chatRepository.getUserOnlineStatus(userId).listen((status) {
      final isOnline = status["isOnline"] as bool;
      final lastSeen = status["lastSeen"] as Timestamp?;
      emit(
        state.copyWith(
          isReceiverOnline: isOnline,
          receiverLastSeen: lastSeen,
        ),
      );
    }, onError: (error) {
      log("error getting online status");
    });
  }

  void _subscribeToTypingStatus(String chatRoomId) {
    _typingSubscription?.cancel();
    _typingSubscription = _chatRepository.getTypingStatus(chatRoomId).listen((status) {
      final isTyping = status["isTyping"] as bool;
      final typingUserId = status["isTypingUserID"] as String?;

      emit(
        state.copyWith(isReceiverTyping: isTyping && typingUserId != currentUserID),
      );
    }, onError: (error) {
      log("error getting online status");
    });
  }

  void startTyping() {
    if (state.chatRoomID == null) return;

    typingTimer?.cancel();
    _updateTypingStatus(true);
    typingTimer = Timer(
      Duration(seconds: 3),
      () {
        _updateTypingStatus(false);
      },
    );
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (state.chatRoomID == null) return;

    try {
      await _chatRepository.updateTypingStatus(
        state.chatRoomID!,
        currentUserID,
        isTyping,
      );
    } catch (e) {
      log("error updating typing stauts");
    }
  }

  Future<void> _markMessagesAsRead(String chatRoomId) async {
    try {
      await _chatRepository.markMessageAsRead(chatRoomId, currentUserID);
    } catch (e) {
      log("Error in mark message $e");
    }
  }

  Future<void> leaveChat() async {
    _isInChat = false;
  }
}
