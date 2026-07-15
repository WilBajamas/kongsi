sealed class AppError {
  const AppError({required this.message, this.cause});

  final String message;
  final Object? cause;
}

final class NetworkError extends AppError {
  const NetworkError({required super.message, super.cause});
}

final class AuthError extends AppError {
  const AuthError({required super.message, super.cause});
}

final class ValidationError extends AppError {
  const ValidationError({required super.message, super.cause});
}

final class ConflictError extends AppError {
  const ConflictError({required super.message, super.cause});
}

final class UnknownError extends AppError {
  const UnknownError({required super.message, super.cause});
}
