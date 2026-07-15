// The `message` strings below are fallback defaults only — they are never
// shown to users directly. Presentation maps error type to localized text;
// this is just what gets logged when the backend doesn't supply its own
// message.
import 'package:dio/dio.dart';
import 'package:kongsi/core/error/app_error.dart';

AppError mapCustomErrorCode(
  String errorCode,
  DioException cause, {
  String? apiMessage,
}) {
  switch (errorCode) {
    case 'SESSION_EXPIRED':
      return AuthError(
        message: apiMessage ?? 'Your session has expired.',
        cause: cause,
      );
    case 'INVALID_CREDENTIALS':
      return AuthError(
        message: apiMessage ?? 'Invalid email or password.',
        cause: cause,
      );
    case 'VALIDATION_FAILED':
      return ValidationError(
        message: apiMessage ?? 'Please check your input.',
        cause: cause,
      );
    default:
      return UnknownError(
        message: apiMessage ?? 'Unexpected error ($errorCode).',
        cause: cause,
      );
  }
}
