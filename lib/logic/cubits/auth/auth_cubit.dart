import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pop_chat/data/repository/auth_repository.dart';
import 'package:pop_chat/logic/cubits/auth/auth_state.dart';
import 'package:pop_chat/logic/cubits/chat/chat_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepositary;
  StreamSubscription<User?>? _authStateSubscription;

  AuthCubit({
    required AuthRepository authRepositary,
  })  : _authRepositary = authRepositary,
        super(const AuthState()) {
    _init();
  }

  void _init() {
    emit(state.copyWith(status: AuthStatus.initial));
    _authStateSubscription = _authRepositary.authStateChnages.listen((user) async {
      if (user != null) {
        try {
          final userData = await _authRepositary.getUserData(user.uid);
          emit(state.copyWith(
            status: AuthStatus.auhtentication,
            user: userData,
          ));
        } catch (e) {
          emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
        }
      } else {
        emit(state.copyWith(status: AuthStatus.unauthentication));
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      final user = await _authRepositary.signIn(email: email, password: password);
      emit(state.copyWith(
        status: AuthStatus.auhtentication,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  Future<void> signUp({
    required String fullName,
    required String userName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      final user = await _authRepositary.signUp(fullName: fullName, userName: userName, email: email, phoneNumber: phoneNumber, password: password);
      emit(state.copyWith(
        status: AuthStatus.auhtentication,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepositary.signOut();
      emit(state.copyWith(status: AuthStatus.unauthentication));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }
}
