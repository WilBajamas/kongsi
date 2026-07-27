import 'package:dio/dio.dart';
import 'package:kongsi/core/network/auth_interceptor.dart';
import 'package:kongsi/core/network/auth_token_provider.dart';
import 'package:kongsi/core/network/error_mapping_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

Dio createDioClient({
  required String baseUrl,
  required Talker talker,
  required AuthTokenProvider tokenProvider,
}) {
  final options = BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  final dio = Dio(options);

  dio.interceptors.addAll([
    // Dio runs every hook in FIFO list order — errors included.
    // Dio interceptors is a pipeline, and doesn't run in parallel.
    TalkerDioLogger(talker: talker),
    ErrorMappingInterceptor(),
    AuthInterceptor(dio, tokenProvider),
  ]);

  return dio;
}
