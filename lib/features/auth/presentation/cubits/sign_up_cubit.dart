import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';
import 'package:kongsi/features/auth/domain/repositories/auth_repository.dart';
import 'package:kongsi/features/auth/presentation/cubits/sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._repository) : super(const SignUpIdle());

  final AuthRepository _repository;

  Future<void> submit({
    required String email,
    required String password,
  }) async {
    if (state is SignUpSubmitting) return;
    emit(const SignUpSubmitting());

    final result = await _repository.signUp(email: email, password: password);

    emit(switch (result) {
      Success() => const SignUpSucceeded(),
      Failure(:final error) => _classify(error),
    });
  }

  // The only place that reads AppError for this screen.
  SignUpState _classify(AppError error) => switch (error) {
    AuthError() => const SignUpRejected(),
    NetworkError() => const SignUpUnavailable(),
    _ => SignUpFailed(error),
  };
}
