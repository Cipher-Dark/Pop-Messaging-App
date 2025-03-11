import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pop_chat/data/models/chat_message_model.dart';
import 'package:pop_chat/data/services/service_locator.dart';
import 'package:pop_chat/logic/cubits/chat/chat_cubit.dart';
import 'package:pop_chat/logic/cubits/chat/chat_state.dart';
import 'package:pop_chat/presentation/widgets/loading_dots.dart';

class ChatMessageScreen extends StatefulWidget {
  final String receiverID;
  final String receiverName;
  const ChatMessageScreen({
    super.key,
    required this.receiverID,
    required this.receiverName,
  });
  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final ChatCubit _chatCubit;
  bool _isComposing = false;
  final _scrollContoller = ScrollController();
  List<ChatMessageModel> _previousMessages = [];
  bool _showEmojie = false;

  @override
  void initState() {
    _chatCubit = getIt<ChatCubit>();
    _chatCubit.enterChat(widget.receiverID);
    _messageController.addListener(_onTextChange);
    _scrollContoller.addListener(_onScroll);

    super.initState();
  }

  void _onScroll() {
    // load message when reaching top
    if (_scrollContoller.position.pixels >= _scrollContoller.position.maxScrollExtent - 200) {
      _chatCubit.loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollContoller.hasClients) {
      _scrollContoller.animateTo(0, duration: Duration(microseconds: 300), curve: Curves.easeOut);
    }
  }

  void _hasNewMessages(List<ChatMessageModel> messages) {
    if (messages.length != _previousMessages.length) {
      _scrollToBottom();
      _previousMessages = messages;
    }
  }

  Future<void> _handleSendMessage() async {
    final messageText = _messageController.text.trim();
    _messageController.clear();
    await _chatCubit.sendMessage(
      content: messageText,
      receiverID: widget.receiverID,
    );
  }

  void _onTextChange() {
    final isComposing = _messageController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
    if (isComposing) {
      _chatCubit.startTyping();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    _chatCubit.leaveChat();
    _scrollContoller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withValues(
                  alpha: .1,
                ),
            child: Text(widget.receiverName[0].toUpperCase()),
          ),
          title: Text(widget.receiverName),
          subtitle: BlocBuilder<ChatCubit, ChatState>(
            bloc: _chatCubit,
            builder: (context, state) {
              if (state.isReceiverTyping) {
                return Row(
                  spacing: 4,
                  children: [
                    Text(
                      "Typing",
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    LoadingDots(),
                  ],
                );
              }
              if (state.isReceiverOnline) {
                return Text(
                  "Online",
                  style: TextStyle(color: Colors.green, fontSize: 12),
                );
              }
              if (state.receiverLastSeen != null) {
                final lastSeen = state.receiverLastSeen!.toDate();
                return Text(
                  "last seen at ${DateFormat('h:mm a').format(lastSeen)}",
                  style: TextStyle(color: Colors.grey.shade600),
                );
              }
              return SizedBox();
            },
          ),
        ),
        actions: [
          BlocBuilder<ChatCubit, ChatState>(
            bloc: _chatCubit,
            builder: (context, state) {
              if (state.isUserBloced) {
                return TextButton.icon(
                  onPressed: () {
                    _chatCubit.unBlockUser(widget.receiverID);
                  },
                  label: Text("Unblock"),
                  icon: Icon(Icons.block),
                );
              }
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'block') {
                    final bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Are you sure you want to block ${widget.receiverName}"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Block",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _chatCubit.blockUser(widget.receiverID);
                    }
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: 'block',
                    child: Text("Block User"),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        bloc: _chatCubit,
        listener: (context, state) {
          _hasNewMessages(state.messages);
        },
        builder: (context, state) {
          if (state.status == ChatStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state.status == ChatStatus.error) {
            return Center(
              child: Text(state.error ?? "Somethisng went wrong"),
            );
          }
          return Column(
            children: [
              if (state.amIBlocked)
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.red.withAlpha(25),
                  child: Text(
                    "You have been blocked by ${widget.receiverName}",
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollContoller,
                  reverse: true,
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isME = message.senderID == _chatCubit.currentUserID;
                    return MessageBubble(
                      message: message,
                      isME: isME,
                    );
                  },
                ),
              ),
              if (!state.amIBlocked && !state.isUserBloced)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showEmojie = !_showEmojie;
                              });
                              if (_showEmojie) {
                                FocusScope.of(context).unfocus();
                              }
                            },
                            icon: Icon(Icons.emoji_emotions),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onTap: () {
                                if (_showEmojie) {
                                  setState(() {
                                    _showEmojie = false;
                                  });
                                }
                              },
                              controller: _messageController,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: "Type a message",
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                fillColor: Theme.of(context).cardColor,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 14),
                          IconButton(
                            onPressed: _isComposing ? _handleSendMessage : null,
                            icon: Icon(
                              Icons.send,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        ],
                      ),
                      if (_showEmojie)
                        SizedBox(
                          height: 250,
                          child: EmojiPicker(
                            textEditingController: _messageController,
                            onEmojiSelected: (category, emoji) {
                              _messageController
                                ..text += emoji.emoji
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(offset: _messageController.text.length),
                                );
                              setState(() {
                                _isComposing = _messageController.text.isNotEmpty;
                              });
                            },
                            config: Config(
                              height: 250,
                              emojiViewConfig: EmojiViewConfig(
                                columns: 7,
                                emojiSizeMax: 32.0 * (Platform.isIOS ? 1.30 : 1.0),
                                verticalSpacing: 0,
                                horizontalSpacing: 0,
                                gridPadding: EdgeInsets.zero,
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                loadingIndicator: const SizedBox.shrink(),
                              ),
                              categoryViewConfig: const CategoryViewConfig(
                                initCategory: Category.RECENT,
                              ),
                              bottomActionBarConfig: BottomActionBarConfig(
                                enabled: true,
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                buttonColor: Theme.of(context).primaryColor,
                              ),
                              skinToneConfig: const SkinToneConfig(
                                enabled: true,
                                dialogBackgroundColor: Colors.white,
                                indicatorColor: Colors.grey,
                              ),
                              searchViewConfig: SearchViewConfig(
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                buttonIconColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isME;
  // final showTime;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isME,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isME ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isME ? 64 : 8,
          right: isME ? 8 : 64,
          bottom: 4,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isME ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isME ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isME ? Colors.white : Colors.black,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp.toDate()),
                  style: TextStyle(
                    color: isME ? Colors.white : Colors.black,
                    fontSize: 10,
                  ),
                ),
                if (isME)
                  Icon(
                    Icons.done_all,
                    color: message.status == MessageStatus.read ? Colors.green : Colors.white,
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
