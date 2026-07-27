import 'package:kongsi/core/network/auth_token_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthTokenProvider implements AuthTokenProvider {
  const SupabaseAuthTokenProvider(this._auth);

  final GoTrueClient _auth;

  @override
  String? get accessToken => _auth.currentSession?.accessToken;

  @override
  Future<bool> refreshToken() async {
    try {
      final session = await _auth.refreshSession();
      return session.session != null;
    } on Object catch (_) {
      // ! Never throw: the interceptor reads false as "give up".
      return false;
    }
  }
}
