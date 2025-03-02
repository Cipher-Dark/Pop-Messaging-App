import 'package:flutter/material.dart';
import 'package:pop_chat/config/theme/app_theme.dart';
import 'package:pop_chat/presentation/screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POP CHAT',
      theme: AppTheme.lightTheme,
      home: LoginScreen(),
    );
  }
}
