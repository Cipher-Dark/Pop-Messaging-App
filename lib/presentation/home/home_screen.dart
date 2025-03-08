import 'package:flutter/material.dart';
import 'package:pop_chat/data/repos/contact_repositary.dart';
import 'package:pop_chat/data/services/service_locator.dart';
import 'package:pop_chat/logic/cubits/auth/auth_cubit.dart';
import 'package:pop_chat/presentation/screens/auth/login_screen.dart';
import 'package:pop_chat/router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ContactRepositary _contactRepositary;

  @override
  void initState() {
    super.initState();
    _contactRepositary = getIt<ContactRepositary>();
  }

  void _showContactsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Contacts",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _contactRepositary.getRegisteredContacts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error : ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator(
                      color: Colors.white,
                    );
                  }
                  final contacts = snapshot.data!;
                  if (contacts.isEmpty) {
                    return const Center(
                      child: Text("No Contacts found"),
                    );
                  }
                  return ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: .1),
                          child: Text(contact["name"][0].toUpperCase()),
                        ),
                      );
                    },
                  );
                },
              )
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
        child: Text("Home"),
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
