import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_in_state.dart';

/// Not `CommandCubit`: that one reports failure by catching an exception, and
/// `AuthRepository` returns a typed `Result` instead of throwing.
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._repository) : super(const SignInIdle());

  final AuthRepository _repository;

  Future<void> submit({
    required String email,
    required String password,
  }) async {
    if (state is SignInSubmitting) return;
    emit(const SignInSubmitting());

    final result = await _repository.signIn(email: email, password: password);

    emit(switch (result) {
      Success() => const SignInSucceeded(),
      Failure(:final error) => _classify(error),
    });
  }

  // The only place that reads AppError for this screen. Widening AppError's
  // taxonomy means widening this switch, not every screen that shows an error.
  SignInState _classify(AppError error) => switch (error) {
    AuthError() => const SignInRejected(),
    NetworkError() => const SignInUnavailable(),
    _ => SignInFailed(error),
  };
}
