import 'package:equatable/equatable.dart';
import 'package:pop_chat/data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  auhtentication,
  unauthentication,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    // ValueGetter<UserModel?>? user,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        error
      ];
}
