import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pop_chat/core/common/custom_button.dart';
import 'package:pop_chat/core/common/custom_text_filed.dart';
import 'package:pop_chat/core/utils/ui_utils.dart';
import 'package:pop_chat/data/services/service_locator.dart';
import 'package:pop_chat/logic/cubits/auth/auth_cubit.dart';
import 'package:pop_chat/logic/cubits/auth/auth_state.dart';
import 'package:pop_chat/presentation/home/home_screen.dart';
import 'package:pop_chat/presentation/screens/auth/signup_screen.dart';
import 'package:pop_chat/router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswardVisable = true;
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter Password.";
    }

    return null;
  }

  Future<void> handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      try {
        await getIt<AuthCubit>().signIn(
          email: emailController.text,
          password: passwordController.text,
        );
      } catch (e) {
        UiUtils.showSnackBar(context, message: e.toString(), isError: true);
      }
    } else {
      log("Form validation fail");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      listener: (context, state) {
        if (state.status == AuthStatus.auhtentication) {
          getIt<AppRouter>().pushAndRemoveUntil(HomeScreen());
        } else if (state.status == AuthStatus.error && state.error != null) {
          UiUtils.showSnackBar(context, message: state.error!, isError: true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(height: 30),
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
                      controller: passwordController,
                      hintText: "Password",
                      obscureText: _isPasswardVisable,
                      validator: _validatePassword,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(
                            () {
                              _isPasswardVisable = !_isPasswardVisable;
                            },
                          );
                        },
                        child: _isPasswardVisable
                            ? Icon(Icons.visibility)
                            : Icon(
                                Icons.visibility_off,
                              ),
                      ),
                      prefixIcon: Icon(Icons.lock_outline),
                      focusNode: _passwordFocus,
                    ),
                    SizedBox(height: 30),
                    CustomButton(
                      onPressed: handleSignIn,
                      text: "Login",
                      child: state.status == AuthStatus.loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.grey.shade600),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen()));
                                  getIt<AppRouter>().push(const SignupScreen());
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
          ),
        );
      },
    );
  }
}
