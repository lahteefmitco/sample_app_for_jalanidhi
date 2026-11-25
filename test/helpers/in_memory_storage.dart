import 'package:sample_app_for_jalanidhi/core/storage/local_storage_service.dart';
import 'package:sample_app_for_jalanidhi/core/storage/secure_storage_service.dart';

/// Fake [LocalStorageService] that keeps values in a map, so tests never
/// touch the real device storage.
class InMemoryLocalStorage implements LocalStorageService {
  /// Everything stored so far, by key. Tests may read or prefill it.
  final Map<String, Object> values = <String, Object>{};

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Fake [SecureStorageService] that keeps values in a map, so tests never
/// touch the real secure storage (keychain / keystore).
class InMemorySecureStorage implements SecureStorageService {
  /// Everything stored so far, by key. Tests may read or prefill it.
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
