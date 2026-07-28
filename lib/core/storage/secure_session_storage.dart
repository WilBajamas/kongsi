import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// This file's responsibility is to override the default storage of supabase
/// session tokens - switching from default SharedPref to Flutter Secure Storage
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage([
    this._storage = const FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  ]);

  static const _sessionKey = 'supabase_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
}
