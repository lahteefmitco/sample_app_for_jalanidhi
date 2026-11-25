/// Base class of every exception the app throws on purpose.
///
/// [message] is safe to show to end users (no stack traces, no secrets).
class AppException implements Exception {
  /// Creates an exception carrying a user-friendly [message].
  const AppException(this.message);

  /// Text that can be shown to the user as is.
  final String message;

  /// Readable description, handy in logs.
  @override
  String toString() => 'AppException(message: $message)';
}

/// Thrown by the local authentication simulation.
class AuthException extends AppException {
  /// Creates an authentication error (e.g. wrong password).
  const AuthException(super.message);

  /// Readable description, handy in logs.
  @override
  String toString() => 'AuthException(message: $message)';
}

/// Thrown when a storage backend fails.
class StorageException extends AppException {
  /// Creates a storage error (e.g. keychain unavailable).
  const StorageException(super.message);

  /// Readable description, handy in logs.
  @override
  String toString() => 'StorageException(message: $message)';
}
