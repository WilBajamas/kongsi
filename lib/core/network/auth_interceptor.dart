import 'dart:async';

import 'package:dio/dio.dart';
import 'package:kongsi/core/network/auth_token_provider.dart';

const _retriedKey = 'retried';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor(this._dio, this._tokenProvider);

  final Dio _dio;
  final AuthTokenProvider _tokenProvider;

  // The lock: ensures only the FIRST 401 triggers a refresh; the rest wait.
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Attach the current token to every outgoing request.
    final token = _tokenProvider.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Moves onto the next step: sending request
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;

    // The infinite-loop guard: if we already retried this once and it STILL
    // 401s, the problem isn't an expired token — give up.
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err); // not our problem → pass to next interceptor
      return;
    }

    // Only the first request here starts the refresh; others fall through
    // to await the same completer below
    if (!_isRefreshing) {
      _isRefreshing = true;
      _refreshCompleter = Completer<void>();

      final refreshed = await _tokenProvider.refreshToken();

      if (refreshed) {
        _refreshCompleter?.complete();
      } else {
        _refreshCompleter?.completeError(err);
      }
      _isRefreshing = false;
    }

    try {
      // Everyone waits on the one refresh to finish.
      await _refreshCompleter?.future;

      // Retry the original request, marked so it can't loop.
      final retryOptions = err.requestOptions..extra[_retriedKey] = true;
      final token = _tokenProvider.accessToken;
      if (token != null) {
        retryOptions.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on Object catch (_) {
      handler.next(err); // refresh failed → let the error flow onward
    }
  }
}
