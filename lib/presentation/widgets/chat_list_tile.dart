import 'package:flutter/material.dart';
import 'package:pop_chat/data/models/chat_room_model.dart';
import 'package:pop_chat/data/repository/chat_repository.dart';
import 'package:pop_chat/data/services/service_locator.dart';

class ChatListTile extends StatelessWidget {
  final ChatRoomModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  String _getOtherUserName() {
    final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);
    return chat.participantsName![otherUserId] ?? "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
        child: Text(_getOtherUserName()[0].toUpperCase()),
      ),
      title: Text(
        _getOtherUserName(),
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.lastMessage ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      trailing: StreamBuilder<int>(
        stream: getIt<ChatRepository>().getUnreadCount(chat.id, currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == 0) {
            return const SizedBox();
          }
          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              snapshot.data.toString(),
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
