part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const [];
}

/// Session status is still being resolved (startup restore / sign-in flight).
class AuthStatusLoading extends AuthState {
  const AuthStatusLoading();
}

/// A user is signed in.
///
/// [notice] carries a one-shot, user-presentable message (e.g. "Password
/// updated") that the Profile screen surfaces via a SnackBar. It is `null`
/// for ordinary authenticated states.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, this.notice});

  final AuthUser user;
  final String? notice;

  @override
  List<Object?> get props => [user, notice];
}

/// No active session. The login screen is shown.
///
/// [isSubmitting] disables the form while a sign-in/sign-up call is in
/// flight; [errorMessage] surfaces the reason for the last failed attempt.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage, this.isSubmitting = false});

  final String? errorMessage;
  final bool isSubmitting;

  AuthUnauthenticated copyWith({String? errorMessage, bool? isSubmitting}) {
    return AuthUnauthenticated(
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [errorMessage, isSubmitting];
}
