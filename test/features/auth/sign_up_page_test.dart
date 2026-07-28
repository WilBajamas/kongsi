import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/auth_providers.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:kongsi/features/auth/presentation/pages/sign_up_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  Future<void> pumpAndSubmit(WidgetTester tester) async {
    await tester.pumpApp(
      const SignUpPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.enterText(find.byType(TextFormField).first, 'new@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'hunter22');
    await tester.tap(find.text('Continue'));
  }

  testWidgets('submitting creates an account, it never signs in', (
    tester,
  ) async {
    when(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Failure(AuthError(message: 'taken')));

    await pumpAndSubmit(tester);
    await tester.pumpAndSettle();

    verify(
      () => repository.signUp(
        email: 'new@example.com',
        password: 'hunter22',
      ),
    ).called(1);
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('a rejected sign-up shows an error and re-enables the form', (
    tester,
  ) async {
    when(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Failure(NetworkError(message: 'no route to host')),
    );

    await pumpAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('an invalid email never reaches the repository', (tester) async {
    await tester.pumpApp(
      const SignUpPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.enterText(find.byType(TextFormField).first, 'nope');
    await tester.enterText(find.byType(TextFormField).last, 'hunter22');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email to continue.'), findsOneWidget);
    verifyNever(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });
}
