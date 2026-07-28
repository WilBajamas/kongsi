import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/storage/secure_session_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage secureStorage;
  late SecureSessionStorage storage;

  setUp(() {
    secureStorage = _MockSecureStorage();
    storage = SecureSessionStorage(secureStorage);
  });

  test('a session is written under one key', () async {
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: 'session-json',
      ),
    ).thenAnswer((_) async {});

    await storage.persistSession('session-json');

    verify(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: 'session-json',
      ),
    ).called(1);
  });

  test('reading returns what was stored', () async {
    when(
      () => secureStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'session-json');

    expect(await storage.accessToken(), 'session-json');
  });

  test('presence is a key check, not a read', () async {
    when(
      () => secureStorage.containsKey(key: any(named: 'key')),
    ).thenAnswer((_) async => true);

    expect(await storage.hasAccessToken(), isTrue);
    verifyNever(() => secureStorage.read(key: any(named: 'key')));
  });

  // Sign-out has to erase it; leaving a live refresh token behind is the bug.
  test('removing deletes the key', () async {
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer(
      (_) async {},
    );

    await storage.removePersistedSession();

    verify(() => secureStorage.delete(key: any(named: 'key'))).called(1);
  });
}
