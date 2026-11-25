/// The locally simulated, signed-in account. Never holds the password.
class AuthUserModel {
  /// Creates the signed-in account's public data.
  const AuthUserModel({required this.name, required this.email});

  /// Name entered when the account was registered.
  final String name;

  /// Email used to log in (stored lower-case).
  final String email;

  /// Readable description, handy in logs.
  @override
  String toString() => 'AuthUserModel(name: $name, email: $email)';
}
