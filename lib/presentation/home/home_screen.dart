import 'package:flutter/material.dart';
import 'package:pop_chat/data/repository/auth_repository.dart';
import 'package:pop_chat/data/repository/chat_repository.dart';
import 'package:pop_chat/data/repository/contact_repository.dart';
import 'package:pop_chat/data/services/service_locator.dart';
import 'package:pop_chat/logic/cubits/auth/auth_cubit.dart';
import 'package:pop_chat/presentation/chat/chat_message_screen.dart';
import 'package:pop_chat/presentation/screens/auth/login_screen.dart';
import 'package:pop_chat/presentation/widgets/chat_list_tile.dart';
import 'package:pop_chat/router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ContactRepository _contactRepositary;
  late final ChatRepository _chatRepository;
  late final String _currentUserID;

  @override
  void initState() {
    super.initState();
    _contactRepositary = getIt<ContactRepository>();
    _chatRepository = getIt<ChatRepository>();
    _currentUserID = getIt<AuthRepository>().currentUser?.uid ?? "";
  }

  void _showContactsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Contacts",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _contactRepositary.getRegisteredContacts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error: ${snapshot.error}"),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }
                    final contacts = snapshot.data ?? [];
                    if (contacts.isEmpty) {
                      return const Center(
                        child: Text("No Contacts found"),
                      );
                    }
                    return ListView.builder(
                      itemCount: contacts.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: .1),
                            child: Text(contact["name"][0].toUpperCase()),
                          ),
                          title: Text(contact["name"]),
                          onTap: () {
                            getIt<AppRouter>().push(
                              ChatMessageScreen(
                                receiverID: contact['id'],
                                receiverName: contact['name'],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        actions: [
          InkWell(
            onTap: () async {
              await getIt<AuthCubit>().signOut();
              getIt<AppRouter>().pushAndRemoveUntil(const LoginScreen());
            },
            child: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: StreamBuilder(
          stream: _chatRepository.getChatRooms(_currentUserID),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error"));
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final chats = snapshot.data!;
            if (chats.isEmpty) {
              return Center(
                child: Text("No recent chats"),
              );
            }
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ChatListTile(
                  chat: chat,
                  currentUserId: _currentUserID,
                  onTap: () {
                    final receiverID = chat.participants.firstWhere(
                      (element) => element != _currentUserID,
                    );
                    final receiverName = chat.participantsName![receiverID] ?? "Unknown";
                    getIt<AppRouter>().push(
                      ChatMessageScreen(receiverID: receiverID, receiverName: receiverName),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactsList(context),
        child: Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }
}
