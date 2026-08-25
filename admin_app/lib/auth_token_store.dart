import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStore {
  const AuthTokenStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const String _key = 'momoweb_update_auth_token';

  final FlutterSecureStorage _storage;

  Future<String> read() async {
    return (await _storage.read(key: _key)) ?? '';
  }

  Future<void> save(String token) async {
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
