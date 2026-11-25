/// Key/value storage for NON-sensitive data (preferences, simple settings).
///
/// Features depend on this abstraction, never on `shared_preferences`.
abstract interface class LocalStorageService {
  /// Returns the text saved under [key], or null if nothing is saved.
  String? getString(String key);

  /// Saves [value] under [key], replacing any previous value.
  Future<void> setString(String key, String value);

  /// Returns the flag saved under [key], or null if nothing is saved.
  bool? getBool(String key);

  /// Saves the flag [value] under [key], replacing any previous value.
  Future<void> setBool(String key, bool value);

  /// Deletes whatever is saved under [key].
  Future<void> remove(String key);
}
