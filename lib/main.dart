import 'package:flutter/material.dart';
import 'package:pop_chat/config/theme/app_theme.dart';
import 'package:pop_chat/data/services/service_locator.dart';
import 'package:pop_chat/presentation/screens/auth/login_screen.dart';
import 'package:pop_chat/router/app_router.dart';

Future<void> main() async {
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POP CHAT',
      navigatorKey: getIt<AppRouter>().navigatorKey,
      theme: AppTheme.lightTheme,
      home: LoginScreen(),
    );
  }
}
