// The `message` strings below are fallback defaults only — they are never
// shown to users directly. Presentation maps error type to localized text;
// this is just what gets logged when the backend doesn't supply its own
// message.
import 'package:dio/dio.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/network/custom_error_code_mapper.dart';

class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = _mapError(err);
    handler.next(err.copyWith(error: appError));
  }

  AppError _mapError(DioException err) {
    if (err.type == DioExceptionType.badResponse) {
      final errorCode = _extractErrorCode(err.response);
      if (errorCode != null) {
        final apiMessage = _extractMessage(err.response);
        return mapCustomErrorCode(errorCode, err, apiMessage: apiMessage);
      }
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return NetworkError(message: 'No internet connection.', cause: err);

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          return AuthError(message: 'Session expired.', cause: err);
        }
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return ValidationError(
            message: 'Request was invalid.',
            cause: err,
          );
        }
        return UnknownError(message: 'Server error.', cause: err);

      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnknownError(message: 'Something went wrong.', cause: err);
    }
  }

  String? _extractErrorCode(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic> && data['errorCode'] is String) {
      return data['errorCode'] as String;
    }
    return null;
  }

  String? _extractMessage(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
