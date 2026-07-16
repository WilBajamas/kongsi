import 'package:kongsi/core/network/auth_token_provider.dart';

class NoAuthTokenProvider implements AuthTokenProvider {
  const NoAuthTokenProvider();

  @override
  String? get accessToken => null;

  @override
  Future<bool> refreshToken() => Future.value(false);
}
