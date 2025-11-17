import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialsStorage {
  CredentialsStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const _emailKey = 'credentials_email';
  static const _passwordKey = 'credentials_password';

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  Future<({String email, String password})?> readCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    if (email == null || password == null) {
      return null;
    }
    return (email: email, password: password);
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }
}
