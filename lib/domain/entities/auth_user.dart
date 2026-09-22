import 'package:equatable/equatable.dart';

/// Minimal, provider-agnostic representation of the signed-in user.
///
/// Deliberately small: the app only needs a stable identifier and the
/// primary email for display and account management. Keeping this free of
/// any Supabase type lets the domain/BLoC layers stay decoupled from the
/// authentication backend.
class AuthUser extends Equatable {
  const AuthUser({required this.id, this.email});

  /// The unique user identifier (Supabase `auth.users.id`).
  final String id;

  /// The user's primary email address, when available.
  final String? email;

  @override
  List<Object?> get props => [id, email];
}
