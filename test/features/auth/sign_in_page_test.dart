import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/auth_providers.dart';
import 'package:kongsi/features/auth/domain/entities/app_user.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:kongsi/features/auth/presentation/pages/sign_in_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  void stubSignIn(Future<Result<AppUser>> Function() answer) {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> pumpAndSubmit(WidgetTester tester) async {
    await tester.pumpApp(
      const SignInPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'ali@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'hunter22');
    await tester.tap(find.text('Continue'));
  }

  testWidgets('a rejected sign-in shows the credentials message', (
    tester,
  ) async {
    stubSignIn(
      () async =>
          const Failure(AuthError(message: 'Invalid login credentials')),
    );

    await pumpAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  // The mapping built in chunk 1 finally reaching a person: a right password on
  // a dead connection must not read as a wrong password.
  testWidgets('a network failure shows the connection message', (tester) async {
    stubSignIn(
      () async => const Failure(NetworkError(message: 'no route to host')),
    );

    await pumpAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('the submit button is disabled while submitting', (tester) async {
    stubSignIn(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return const Failure(AuthError(message: 'nope'));
    });

    await pumpAndSubmit(tester);
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.pumpAndSettle();
  });

  testWidgets('an invalid email never reaches the repository', (tester) async {
    await tester.pumpApp(
      const SignInPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'hunter22');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email to continue.'), findsOneWidget);
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  // The validation timing rule: quiet until submit, then live until fixed.
  testWidgets('validation stays quiet until submit, then follows typing', (
    tester,
  ) async {
    await tester.pumpApp(
      const SignInPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email to continue.'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email to continue.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'ali@example.com',
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email to continue.'), findsNothing);
  });
}
