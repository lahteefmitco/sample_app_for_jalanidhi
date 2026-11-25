import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';

/// Storage for SENSITIVE data (tokens, credentials hashes).
///
/// Features depend on this abstraction, never on `flutter_secure_storage`.
abstract interface class SecureStorageService {
  /// Returns the secret saved under [key], or null if nothing is saved.
  Future<String?> read(String key);

  /// Saves the secret [value] under [key], replacing any previous value.
  Future<void> write(String key, String value);

  /// Deletes the secret saved under [key].
  Future<void> delete(String key);
}

/// [SecureStorageService] backed by `flutter_secure_storage`.
///
/// Every method converts plugin failures into a [StorageException], so
/// callers only have to handle our own exception type.
class FlutterSecureStorageService implements SecureStorageService {
  /// Uses [storage] if given (tests pass a fake), otherwise the real plugin.
  FlutterSecureStorageService([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          // macOS: the legacy keychain needs neither the keychain-access-
          // groups entitlement nor a provisioning profile. The option is
          // ignored on every other platform.
          const FlutterSecureStorage(
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  /// The plugin instance that talks to the keychain / keystore.
  final FlutterSecureStorage _storage;

  /// Reads a secret; throws [StorageException] if the storage fails.
  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Object catch (error) {
      errorLog(
        'read($key) failed: ${error.runtimeType}',
        funtionName: 'SecureStorage.read',
      );
      throw const StorageException('Secure storage is unavailable.');
    }
  }

  /// Saves a secret; throws [StorageException] if the storage fails.
  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on Object catch (error) {
      errorLog(
        'write($key) failed: ${error.runtimeType}',
        funtionName: 'SecureStorage.write',
      );
      throw const StorageException('Secure storage is unavailable.');
    }
  }

  /// Deletes a secret; throws [StorageException] if the storage fails.
  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on Object catch (error) {
      errorLog(
        'delete($key) failed: ${error.runtimeType}',
        funtionName: 'SecureStorage.delete',
      );
      throw const StorageException('Secure storage is unavailable.');
    }
  }
}
