import 'package:dio/dio.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';

Future<Result<T>> safeApiCall<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } on DioException catch (e) {
    final appError = e.error;
    if (appError is AppError) {
      return Failure(appError);
    }
    return Failure(UnknownError(message: 'Something went wrong.', cause: e));
  }
}
