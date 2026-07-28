import 'package:equatable/equatable.dart';
import 'package:kongsi/core/error/app_error.dart';

/// Outcomes this screen can act on — not `AppError`'s shape. The cubit
/// classifies; the widget never sees the app-wide error taxonomy.
sealed class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

final class SignUpIdle extends SignUpState {
  const SignUpIdle();
}

final class SignUpSubmitting extends SignUpState {
  const SignUpSubmitting();
}

final class SignUpSucceeded extends SignUpState {
  const SignUpSucceeded();
}

/// The server refused the sign-up (usually: email already registered).
final class SignUpRejected extends SignUpState {
  const SignUpRejected();
}

/// We never reached the server.
final class SignUpUnavailable extends SignUpState {
  const SignUpUnavailable();
}

/// Unexpected. Keeps the `AppError` so it can still reach a crash reporter.
final class SignUpFailed extends SignUpState {
  const SignUpFailed(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}
