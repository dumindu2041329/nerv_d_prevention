import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../remote/supabase/supabase_service.dart';

/// [AuthRepository] backed by Supabase Auth (GoTrue).
///
/// Email/password is the app's "normal" authentication mechanism after
/// removing Clerk. The underlying session is persisted and auto-refreshed by
/// `supabase_flutter` (configured in [SupabaseService.init]).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required SupabaseService supabase})
      : _auth = supabase.auth;

  final GoTrueClient _auth;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    // The first event (`initialSession`) reflects the restored session at
    // startup; subsequent events fire on sign-in/out/refresh.
    return _auth.onAuthStateChange.map((state) => _map(state.session?.user));
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e));
    } catch (_) {
      throw const AuthFailure(
        'Could not sign in. Check your connection and try again.',
      );
    }
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
      );
      // A null session means the project requires email confirmation before
      // the user can sign in.
      return response.session != null;
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e));
    } catch (_) {
      throw const AuthFailure(
        'Could not create your account. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e));
    } catch (_) {
      throw const AuthFailure('Could not sign out. Please try again.');
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e));
    } catch (_) {
      throw const AuthFailure(
        'Could not update your password. Please try again.',
      );
    }
  }

  AuthUser? _map(User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email);
  }

  /// Maps a Supabase [AuthException] to a concise, user-facing message,
  /// falling back to the raw message when we don't recognise the code.
  String _friendly(AuthException e) {
    final msg = e.message.trim();
    if (msg.isEmpty) return 'Something went wrong. Please try again.';
    return msg;
  }
}
