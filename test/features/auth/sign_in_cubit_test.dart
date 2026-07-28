import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/domain/entities/app_user.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_in_cubit.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_in_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SignInCubit cubit;

  setUp(() {
    repository = _MockAuthRepository();
    cubit = SignInCubit(repository);
  });

  void stubSignIn(Future<Result<AppUser>> Function() answer) {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> submit() =>
      cubit.submit(email: 'ali@example.com', password: 'hunter22');

  test('a successful sign-in ends in success', () async {
    stubSignIn(() async => const Success(AppUser(id: 'user-1')));

    await submit();

    expect(cubit.state, const SignInSucceeded());
  });

  // The whole reason this is not a CommandCubit: the repository reports failure
  // by returning it, not by throwing, so a wrapper that catches would miss it.
  test('a rejected credential becomes SignInRejected, not a success', () async {
    stubSignIn(
      () async =>
          const Failure(AuthError(message: 'Invalid login credentials')),
    );

    await submit();

    expect(cubit.state, const SignInRejected());
  });

  test('a network failure stays distinguishable from a bad password', () async {
    stubSignIn(
      () async => const Failure(NetworkError(message: 'no route to host')),
    );

    await submit();

    expect(cubit.state, const SignInUnavailable());
  });

  // The cubit is the only place that reads AppError for this screen; anything
  // it does not recognise still reaches the user, tagged as unexpected.
  test(
    'an unrecognised error becomes SignInFailed, carrying the cause',
    () async {
      const error = ConflictError(message: 'unexpected');
      stubSignIn(() async => const Failure(error));

      await submit();

      expect(cubit.state, isA<SignInFailed>());
      expect((cubit.state as SignInFailed).error, error);
    },
  );

  test('a second submit while one is running is ignored', () async {
    stubSignIn(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Success(AppUser(id: 'user-1'));
    });

    await Future.wait([submit(), submit()]);

    verify(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
  });
}
