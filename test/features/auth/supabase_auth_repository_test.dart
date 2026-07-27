import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:kongsi/features/auth/domain/entities/app_user.dart';
import 'package:kongsi/features/auth/domain/entities/auth_session.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGoTrueClient extends Mock implements GoTrueClient {}

const _user = User(
  id: 'user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  email: 'ali@example.com',
  createdAt: '2026-07-28T00:00:00Z',
);

final _session = Session(
  accessToken: 'access-token',
  tokenType: 'bearer',
  user: _user,
);

void main() {
  late _MockGoTrueClient auth;
  late SupabaseAuthRepository repository;

  setUp(() {
    auth = _MockGoTrueClient();
    repository = SupabaseAuthRepository(auth);
  });

  Future<Result<AppUser>> signIn() =>
      repository.signIn(email: 'ali@example.com', password: 'hunter2');

  void stubSignInThrowing(Object error) {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(error);
  }

  group('signIn', () {
    test('a successful sign-in returns the user', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: _session));

      final result = await signIn();

      expect(result, isA<Success<AppUser>>());
      final user = (result as Success<AppUser>).value;
      expect(user.id, 'user-1');
      expect(user.email, 'ali@example.com');
    });

    test('a wrong password is an auth failure', () async {
      stubSignInThrowing(
        const AuthApiException('Invalid login credentials', statusCode: '400'),
      );

      final result = await signIn();

      expect((result as Failure).error, isA<AuthError>());
    });

    // A right password on a bad connection must not read as a wrong one.
    test('no connection is a network failure, not an auth failure', () async {
      stubSignInThrowing(AuthRetryableFetchException());

      final result = await signIn();

      expect((result as Failure).error, isA<NetworkError>());
    });

    test('a non-auth error falls through to unknown', () async {
      stubSignInThrowing(StateError('something else entirely'));

      final result = await signIn();

      expect((result as Failure).error, isA<UnknownError>());
    });

    test('a response with no user is a failure, not a crash', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      expect(await signIn(), isA<Failure<dynamic>>());
    });
  });

  test('a weak password on sign-up is a validation failure', () async {
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      AuthWeakPasswordException(
        message: 'Password is too short',
        statusCode: '422',
        reasons: const ['length'],
      ),
    );

    final result = await repository.signUp(
      email: 'ali@example.com',
      password: 'x',
    );

    expect((result as Failure).error, isA<ValidationError>());
  });

  group('session', () {
    test('no session reads as signed out', () {
      when(() => auth.currentSession).thenReturn(null);

      expect(repository.currentSession, const SignedOut());
    });

    test('a session reads as signed in', () {
      when(() => auth.currentSession).thenReturn(_session);

      final session = repository.currentSession;

      expect(session, isA<SignedIn>());
      expect((session as SignedIn).user.id, 'user-1');
    });

    test('the stream follows the SDK, sign-in then sign-out', () {
      when(() => auth.onAuthStateChange).thenAnswer(
        (_) => Stream.fromIterable([
          AuthState(AuthChangeEvent.signedIn, _session),
          const AuthState(AuthChangeEvent.signedOut, null),
        ]),
      );

      expect(
        repository.watchSession(),
        emitsInOrder([
          const SignedIn(AppUser(id: 'user-1', email: 'ali@example.com')),
          const SignedOut(),
        ]),
      );
    });
  });
}
