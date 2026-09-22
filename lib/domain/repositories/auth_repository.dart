import '../entities/auth_user.dart';

/// Thrown by [AuthRepository] for any authentication failure.
///
/// Wraps backend-specific errors (e.g. Supabase's `AuthException`) so the
/// presentation layer only ever deals with a plain, user-presentable
/// [message].
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contract for email/password authentication.
///
/// Implemented over Supabase Auth in [AuthRepositoryImpl]; kept free of any
/// third-party types so the BLoC layer stays backend-agnostic.
abstract class AuthRepository {
  /// The currently signed-in user, or `null` when signed out.
  AuthUser? get currentUser;

  /// Emits the active user on every sign-in / sign-out / session refresh.
  /// The first event reflects the restored session at startup.
  Stream<AuthUser?> authStateChanges();

  /// Signs in with email + password. Throws [AuthFailure] on bad credentials
  /// or network errors.
  Future<void> signIn({required String email, required String password});

  /// Registers a new account. Returns `true` when the user is signed in
  /// immediately, or `false` when email confirmation is required first.
  /// Throws [AuthFailure] when registration is rejected.
  Future<bool> signUp({required String email, required String password});

  /// Signs the current user out (invalidating the persisted session).
  Future<void> signOut();

  /// Updates the signed-in user's password. Throws [AuthFailure] on failure.
  Future<void> updatePassword({required String newPassword});
}
