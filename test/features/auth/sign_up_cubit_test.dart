import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/domain/entities/app_user.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_up_cubit.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_up_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SignUpCubit cubit;

  setUp(() {
    repository = _MockAuthRepository();
    cubit = SignUpCubit(repository);
  });

  void stubSignUp(Future<Result<AppUser>> Function() answer) {
    when(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> submit() =>
      cubit.submit(email: 'ali@example.com', password: 'hunter22');

  test('a successful sign-up ends in success', () async {
    stubSignUp(() async => const Success(AppUser(id: 'user-1')));

    await submit();

    expect(cubit.state, const SignUpSucceeded());
  });

  test('sign-up never calls sign-in', () async {
    stubSignUp(() async => const Success(AppUser(id: 'user-1')));

    await submit();

    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  // An already-registered email comes back as an auth failure, not a throw.
  test('an already-registered email becomes SignUpRejected', () async {
    stubSignUp(
      () async => const Failure(AuthError(message: 'User already registered')),
    );

    await submit();

    expect(cubit.state, const SignUpRejected());
  });

  test('a network failure becomes SignUpUnavailable', () async {
    stubSignUp(
      () async => const Failure(NetworkError(message: 'no route to host')),
    );

    await submit();

    expect(cubit.state, const SignUpUnavailable());
  });

  test(
    'an unrecognised error becomes SignUpFailed, carrying the cause',
    () async {
      const error = ConflictError(message: 'unexpected');
      stubSignUp(() async => const Failure(error));

      await submit();

      expect(cubit.state, isA<SignUpFailed>());
      expect((cubit.state as SignUpFailed).error, error);
    },
  );

  test('a second submit while one is running is ignored', () async {
    stubSignUp(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Success(AppUser(id: 'user-1'));
    });

    await Future.wait([submit(), submit()]);

    verify(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
  });
}
