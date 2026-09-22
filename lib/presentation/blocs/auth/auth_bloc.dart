import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_user.dart';
import '../../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Drives the app's email/password authentication (Supabase Auth), replacing
/// the previous Clerk integration.
///
/// A single instance lives for the whole app lifetime: it mirrors the
/// repository's auth-state stream into [AuthState] and executes sign-in /
/// sign-up / sign-out / password-change commands.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthStatusLoading()) {
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordChangeRequested>(_onPasswordChange);
    on<AuthClearErrorRequested>(_onClearError);

    // Bridge the repository stream into the bloc's event loop. The first
    // event reflects the restored session at startup.
    _subscription = _repository.authStateChanges().listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _subscription;

  Future<void> _onUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      // Only fall back to a plain signed-out state when we aren't already
      // showing one (preserves an in-flight submitting/error message).
      if (state is AuthUnauthenticated) return;
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthAuthenticated(user: user));
    }
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnauthenticated(isSubmitting: true));
    try {
      await _repository.signIn(email: event.email, password: event.password);
      // Success surfaces through the auth-state stream (_AuthUserChanged).
    } on AuthFailure catch (f) {
      emit(AuthUnauthenticated(errorMessage: f.message));
    } catch (_) {
      emit(
        const AuthUnauthenticated(
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnauthenticated(isSubmitting: true));
    try {
      final signedInImmediately = await _repository.signUp(
        email: event.email,
        password: event.password,
      );
      if (!signedInImmediately) {
        emit(
          const AuthUnauthenticated(
            errorMessage:
                'Account created! Check your email to confirm your address, '
                'then sign in.',
          ),
        );
        return;
      }
      // Otherwise the auth-state stream will move us to AuthAuthenticated.
    } on AuthFailure catch (f) {
      emit(AuthUnauthenticated(errorMessage: f.message));
    } catch (_) {
      emit(
        const AuthUnauthenticated(
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.signOut();
      // The auth-state stream emits signedOut → AuthUnauthenticated.
    } on AuthFailure catch (f) {
      emit(
        AuthAuthenticated(
          user: (state as AuthAuthenticated).user,
          notice: f.message,
        ),
      );
    }
  }

  Future<void> _onPasswordChange(
    AuthPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    try {
      await _repository.updatePassword(newPassword: event.newPassword);
      emit(
        AuthAuthenticated(user: current.user, notice: 'Password updated.'),
      );
    } on AuthFailure catch (f) {
      emit(
        AuthAuthenticated(user: current.user, notice: f.message),
      );
    } catch (_) {
      emit(
        AuthAuthenticated(
          user: current.user,
          notice: 'Could not update your password. Please try again.',
        ),
      );
    }
  }

  Future<void> _onClearError(
    AuthClearErrorRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthUnauthenticated) {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
