import 'package:flutter/material.dart';
import 'package:pop_chat/core/common/custom_text_filed.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          child: Column(
            children: [
              SizedBox(height: 30),
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 10),
              Text(
                "Sign in to continue",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              CustomTextFiled(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
                prefixIcon: Icon(Icons.email_rounded),
              ),
              CustomTextFiled(
                controller: passwordController,
                hintText: "Password",
                obscureText: true,
                suffixIcon: Icon(Icons.visibility),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
