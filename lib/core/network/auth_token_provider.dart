abstract class AuthTokenProvider {
  String? get accessToken;
  Future<bool> refreshToken();
}
