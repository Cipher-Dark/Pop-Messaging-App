import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pop_chat/data/repository/auth_repository.dart';
import 'package:pop_chat/data/repository/chat_repository.dart';
import 'package:pop_chat/data/repository/contact_repository.dart';
import 'package:pop_chat/firebase_options.dart';
import 'package:pop_chat/logic/cubits/auth/auth_cubit.dart';
import 'package:pop_chat/logic/cubits/chat/chat_cubit.dart';
import 'package:pop_chat/router/app_router.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  getIt.registerLazySingleton(() => AppRouter());
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  getIt.registerLazySingleton(() => AuthRepository());
  getIt.registerLazySingleton(() => ContactRepository());

  getIt.registerLazySingleton(() => AuthCubit(authRepositary: AuthRepository()));
  getIt.registerLazySingleton(
    () => ChatCubit(
      chatRepository: ChatRepository(),
      currentUserID: getIt<FirebaseAuth>().currentUser!.uid,
    ),
  );
}
