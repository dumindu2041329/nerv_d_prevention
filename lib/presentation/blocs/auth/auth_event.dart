part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const [];
}

/// Internal event bridging the repository's auth-state stream into the
/// bloc's event loop so every transition is serialized.
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final AuthUser? user;

  @override
  List<Object?> get props => [user];
}

/// Email/password sign-in request from the login screen.
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// New-account registration request from the login screen.
class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Sign the current user out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Clears any lingering error/message on the signed-out (login) screen —
/// typically dispatched when the user toggles between sign-in and sign-up.
class AuthClearErrorRequested extends AuthEvent {
  const AuthClearErrorRequested();
}

/// Change the signed-in user's password (used from the Profile screen).
class AuthPasswordChangeRequested extends AuthEvent {
  const AuthPasswordChangeRequested({required this.newPassword});

  final String newPassword;

  @override
  List<Object?> get props => [newPassword];
}
