import 'package:equatable/equatable.dart';
import 'package:kongsi/core/error/app_error.dart';

/// Outcomes this screen can act on — not `AppError`'s shape. The cubit
/// classifies; the widget never sees the app-wide error taxonomy.
sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

final class SignInIdle extends SignInState {
  const SignInIdle();
}

final class SignInSubmitting extends SignInState {
  const SignInSubmitting();
}

final class SignInSucceeded extends SignInState {
  const SignInSucceeded();
}

/// The server refused the credentials.
final class SignInRejected extends SignInState {
  const SignInRejected();
}

/// We never reached the server.
final class SignInUnavailable extends SignInState {
  const SignInUnavailable();
}

/// Unexpected. Keeps the `AppError` so it can still reach a crash reporter.
final class SignInFailed extends SignInState {
  const SignInFailed(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}
