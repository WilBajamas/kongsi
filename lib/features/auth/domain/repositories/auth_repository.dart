import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/domain/entities/app_user.dart';
import 'package:kongsi/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  /// Emits on sign-in, sign-out and each silent token refresh.
  Stream<AuthSession> watchSession();

  /// Safe to read after startup — the SDK restores a saved session first.
  AuthSession get currentSession;
}
