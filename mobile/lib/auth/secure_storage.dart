import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage chiffré pour le JWT.
/// - Android : utilise EncryptedSharedPreferences
/// - iOS : utilise Keychain
/// Le token n'est jamais en clair, même si le téléphone est rooté/jailbreaké.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'jwt_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
