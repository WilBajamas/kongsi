import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/domain/entities/app_user.dart';
import 'package:kongsi/features/auth/domain/entities/auth_session.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  AuthSession get currentSession => _toSession(_auth.currentSession);

  @override
  Stream<AuthSession> watchSession() =>
      _auth.onAuthStateChange.map((state) => _toSession(state.session));

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) => _userCall(
    () => _auth.signInWithPassword(email: email, password: password),
  );

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  }) => _userCall(() => _auth.signUp(email: email, password: password));

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Success<void>(null);
    } on Object catch (e) {
      return Failure<void>(_toAppError(e));
    }
  }

  Future<Result<AppUser>> _userCall(
    Future<AuthResponse> Function() call,
  ) async {
    try {
      final user = (await call()).user;
      if (user == null) {
        // Null instead of a throw when sign-up needs an email confirmation.
        return const Failure<AppUser>(
          AuthError(message: 'Auth call returned no user'),
        );
      }
      return Success(_toAppUser(user));
    } on Object catch (e) {
      return Failure<AppUser>(_toAppError(e));
    }
  }

  AuthSession _toSession(Session? session) {
    final user = session?.user;
    return user == null ? const SignedOut() : SignedIn(_toAppUser(user));
  }

  AppUser _toAppUser(User user) => AppUser(id: user.id, email: user.email);

  // ! `message` is the SDK's English text — log it, never show it. Screens
  // ! translate from the error type, and read `cause` for the exact reason.
  AppError _toAppError(Object error) => switch (error) {
    AuthRetryableFetchException() => NetworkError(
      message: error.message,
      cause: error,
    ),
    AuthWeakPasswordException() => ValidationError(
      message: error.message,
      cause: error,
    ),
    final AuthException e => AuthError(message: e.message, cause: e),
    _ => UnknownError(message: '$error', cause: error),
  };
}
