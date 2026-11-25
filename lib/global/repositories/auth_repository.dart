import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/core/storage/secure_storage_service.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/models/auth_user_model.dart';

/// LOCAL authentication simulation.
///
/// JSONPlaceholder has no authentication endpoint, so accounts live on this
/// device only: a random salt + SHA-256 hash of the password (never the
/// password itself) in secure storage, plus a locally generated session token.
/// This is a demo, not a production-grade scheme.
class AuthRepository {
  /// Creates the repository.
  ///
  /// [simulatedLatency] fakes a network delay; tests pass [Duration.zero]
  /// and a seeded [random] to get fast, repeatable results.
  AuthRepository({
    required SecureStorageService secureStorage,
    Duration simulatedLatency = AppConstants.authLatency,
    Random? random,
  }) : _storage = secureStorage,
       _latency = simulatedLatency,
       _random = random ?? Random.secure();

  /// Where accounts and the session token are saved.
  final SecureStorageService _storage;

  /// Artificial delay of [register] and [login], to feel like a server call.
  final Duration _latency;

  /// Source of random salts and tokens (secure by default).
  final Random _random;

  /// Whether a session token is stored (i.e. someone is logged in).
  Future<bool> isLoggedIn() async {
    final String? token = await _storage.read(StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  /// The logged-in account, or null when nobody is logged in or the
  /// account no longer exists.
  Future<AuthUserModel?> currentUser() async {
    if (!await isLoggedIn()) return null;
    final String? email = await _storage.read(StorageKeys.sessionEmail);
    if (email == null) return null;
    // Saved data of that account (name, salt, hash), or null if missing.
    final Map<String, dynamic>? account = (await _readAccounts())[email];
    if (account == null) return null;
    return AuthUserModel(name: account['name'] as String, email: email);
  }

  /// Creates the demo account on first launch (does nothing if it exists).
  Future<void> ensureDemoAccount() async {
    final Map<String, Map<String, dynamic>> accounts = await _readAccounts();
    if (accounts.containsKey(AppConstants.demoEmail)) return;
    accounts[AppConstants.demoEmail] = _newAccount(
      AppConstants.demoName,
      AppConstants.demoPassword,
    );
    await _writeAccounts(accounts);
  }

  /// Creates a new account and logs it in.
  ///
  /// Throws [AuthException] if an account with [email] already exists.
  Future<AuthUserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    // Accounts are keyed by the trimmed, lower-case email.
    final String key = _normalise(email);
    final Map<String, Map<String, dynamic>> accounts = await _readAccounts();
    if (accounts.containsKey(key)) {
      throw const AuthException(AppStrings.accountExists);
    }
    accounts[key] = _newAccount(name.trim(), password);
    await _writeAccounts(accounts);
    repositoryLog(
      'register: account created',
      funtionName: 'AuthRepository.register',
    );
    return _startSession(key, name.trim());
  }

  /// Checks the credentials and starts a session.
  ///
  /// Throws [AuthException] when the email is unknown or the password is
  /// wrong (one message for both, so attackers cannot probe emails).
  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    // Accounts are keyed by the trimmed, lower-case email.
    final String key = _normalise(email);
    final Map<String, dynamic>? account = (await _readAccounts())[key];
    // Hash the typed password with the saved salt and compare the hashes.
    if (account == null ||
        _hash(account['salt'] as String, password) != account['hash']) {
      throw const AuthException(AppStrings.invalidCredentials);
    }
    repositoryLog('login: success', funtionName: 'AuthRepository.login');
    return _startSession(key, account['name'] as String);
  }

  /// Ends the session; the account itself is kept.
  Future<void> logout() async {
    await _storage.delete(StorageKeys.accessToken);
    await _storage.delete(StorageKeys.sessionEmail);
    repositoryLog('logout', funtionName: 'AuthRepository.logout');
  }

  /// Saves a new random session token and the logged-in email.
  Future<AuthUserModel> _startSession(String email, String name) async {
    await _storage.write(StorageKeys.accessToken, _randomToken());
    await _storage.write(StorageKeys.sessionEmail, email);
    return AuthUserModel(name: name, email: email);
  }

  /// Builds the saved data of a new account: name, random salt and the
  /// salted password hash (never the password itself).
  Map<String, dynamic> _newAccount(String name, String password) {
    final String salt = _randomToken(bytes: 16);
    return <String, dynamic>{
      'name': name,
      'salt': salt,
      'hash': _hash(salt, password),
    };
  }

  /// SHA-256 hash of `salt:password`, as a hex string.
  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// A URL-safe random string made of [bytes] random bytes.
  String _randomToken({int bytes = 32}) => base64UrlEncode(
    List<int>.generate(bytes, (int _) => _random.nextInt(256)),
  );

  /// Trims and lower-cases [email], so `A@x.com ` and `a@x.com` match.
  String _normalise(String email) => email.trim().toLowerCase();

  /// Loads every saved account, keyed by email (empty map if none).
  Future<Map<String, Map<String, dynamic>>> _readAccounts() async {
    // The accounts are stored as one JSON string.
    final String? raw = await _storage.read(StorageKeys.accounts);
    if (raw == null || raw.isEmpty) return <String, Map<String, dynamic>>{};
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    return <String, Map<String, dynamic>>{
      for (final MapEntry<String, dynamic> entry in decoded.entries)
        entry.key: Map<String, dynamic>.from(
          entry.value as Map<dynamic, dynamic>,
        ),
    };
  }

  /// Saves every account as one JSON string, replacing the old value.
  Future<void> _writeAccounts(Map<String, Map<String, dynamic>> accounts) {
    return _storage.write(StorageKeys.accounts, jsonEncode(accounts));
  }
}
