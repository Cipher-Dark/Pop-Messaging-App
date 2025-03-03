import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pop_chat/core/common/custom_button.dart';
import 'package:pop_chat/core/common/custom_text_filed.dart';
import 'package:pop_chat/data/repos/auth_repositary.dart';
import 'package:pop_chat/data/services/service_locator.dart';
import 'package:pop_chat/router/app_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswardVisable = true;
  final _nameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    userNameController.dispose();
    phoneController.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your Full name.";
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your Username.";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter Email.";
    }
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return "Please enter valid email address.";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your Phone Number.";
    }
    final RegExp phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');

    if (!phoneRegex.hasMatch(value)) {
      return "Please enter valid Phone number.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your Password.";
    }
    if (value.length < 6) {
      return "Passward must be at least 6 characters long.";
    }
    return null;
  }

  Future<void> handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      try {
        getIt<AuthRepositary>().signUp(
          fullName: nameController.text,
          username: userNameController.text,
          email: emailController.text,
          phoneNumber: phoneController.text,
          password: passwordController.text,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
            ),
          ),
        );
      }
    } else {
      log("Form validation fail");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create a Account",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 10),
              Text(
                "Please fill in the details to continue",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              CustomTextFiled(
                controller: nameController,
                hintText: "Full Name",
                obscureText: false,
                prefixIcon: Icon(Icons.person_outline),
                focusNode: _nameFocus,
                validator: _validateName,
              ),
              SizedBox(height: 16),
              CustomTextFiled(
                controller: userNameController,
                hintText: "Username",
                obscureText: false,
                prefixIcon: Icon(Icons.alternate_email),
                focusNode: _usernameFocus,
                validator: _validateUsername,
              ),
              SizedBox(height: 16),
              CustomTextFiled(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
                prefixIcon: Icon(Icons.email_outlined),
                focusNode: _emailFocus,
                validator: _validateEmail,
              ),
              SizedBox(height: 16),
              CustomTextFiled(
                controller: phoneController,
                hintText: "Phone Number",
                obscureText: false,
                prefixIcon: Icon(Icons.phone_outlined),
                focusNode: _phoneFocus,
                validator: _validatePhone,
              ),
              SizedBox(height: 16),
              CustomTextFiled(
                controller: passwordController,
                hintText: "Password",
                obscureText: _isPasswardVisable,
                prefixIcon: Icon(Icons.password_outlined),
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPasswardVisable = !_isPasswardVisable;
                    });
                  },
                  child: _isPasswardVisable
                      ? Icon(Icons.visibility)
                      : Icon(
                          Icons.visibility_off,
                        ),
                ),
                focusNode: _passwordFocus,
                validator: _validatePassword,
              ),
              SizedBox(height: 30),
              CustomButton(
                onPressed: handleSignUp,
                text: "Create Account",
              ),
              SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.grey.shade600),
                    children: [
                      TextSpan(
                        text: "Login",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            getIt<AppRouter>().pop();
                          },
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
