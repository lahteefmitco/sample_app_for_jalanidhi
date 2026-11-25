/// Keys used to save values in local and secure storage.
///
/// Keeping them in one place avoids typos and accidental key clashes.
abstract final class StorageKeys {
  // Shared preferences (non-sensitive).

  /// Email of the last successful login, used to pre-fill the login form.
  static const String lastLoginEmail = 'last_login_email';

  /// The chosen theme mode (`system`, `light` or `dark`).
  static const String themeMode = 'theme_mode';

  // Secure storage (sensitive).

  /// JSON map of every local account (name, salt and password hash).
  static const String accounts = 'auth_accounts';

  /// Session token; its presence means "logged in".
  static const String accessToken = 'auth_access_token';

  /// Email of the account that is currently logged in.
  static const String sessionEmail = 'auth_session_email';
}
