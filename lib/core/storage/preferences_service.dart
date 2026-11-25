import 'package:sample_app_for_jalanidhi/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [LocalStorageService] backed by `shared_preferences`.
class PreferencesService implements LocalStorageService {
  /// Wraps an already loaded [SharedPreferences]; prefer [create].
  PreferencesService(this._preferences);

  /// The plugin instance that actually reads and writes the values.
  final SharedPreferences _preferences;

  /// Loads shared preferences from disk and returns a ready service.
  static Future<PreferencesService> create() async {
    return PreferencesService(await SharedPreferences.getInstance());
  }

  /// Reads a text value (synchronous: values are cached in memory).
  @override
  String? getString(String key) => _preferences.getString(key);

  /// Saves a text value.
  @override
  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  /// Reads a flag (synchronous: values are cached in memory).
  @override
  bool? getBool(String key) => _preferences.getBool(key);

  /// Saves a flag.
  @override
  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  /// Deletes a value.
  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
