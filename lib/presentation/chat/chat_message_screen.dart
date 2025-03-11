import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pop_chat/data/models/chat_message_model.dart';
import 'package:pop_chat/data/services/service_locator.dart';
import 'package:pop_chat/logic/cubits/chat/chat_cubit.dart';
import 'package:pop_chat/logic/cubits/chat/chat_state.dart';

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

  @override
  void initState() {
    _chatCubit = getIt<ChatCubit>();
    _chatCubit.enterChat(widget.receiverID);
    _messageController.addListener(_onTextChange);

    super.initState();
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
                return Text(
                  "Typing...",
                  style: TextStyle(color: Theme.of(context).primaryColor),
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
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        bloc: _chatCubit,
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
              Expanded(
                child: ListView.builder(
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.emoji_emotions),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
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
                          onPressed: _handleSendMessage,
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      ],
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
