abstract interface class AuthTokenProvider {
  String? get accessToken;
  Future<bool> refreshToken();
}
