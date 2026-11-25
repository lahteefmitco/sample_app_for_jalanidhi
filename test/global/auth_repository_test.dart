import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/global/models/auth_user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

import '../helpers/in_memory_storage.dart';

/// Tests for [AuthRepository]: registering, logging in and out, duplicate
/// accounts and the demo account. Accounts live in in-memory secure storage.
void main() {
  /// Fake secure storage, so the test can look at what was saved.
  late InMemorySecureStorage storage;

  /// The repository under test, recreated before every test.
  late AuthRepository repository;

  // Fresh storage and repository for every test. `Random(1)` makes the
  // generated salts the same on every run.
  setUp(() {
    storage = InMemorySecureStorage();
    repository = AuthRepository(
      secureStorage: storage,
      simulatedLatency: Duration.zero,
      random: Random(1),
    );
  });

  test('register stores a salted hash, never the password', () async {
    await repository.register(
      name: 'Jane',
      email: 'Jane@Mail.test',
      password: 'secret-pass',
    );
    // Assert on the raw text saved in secure storage.
    final String raw = storage.values[StorageKeys.accounts]!;
    expect(raw, isNot(contains('secret-pass')));
    expect(raw, contains('jane@mail.test'));
    expect(await repository.isLoggedIn(), isTrue);
    expect((await repository.currentUser())!.name, 'Jane');
  });

  test('login succeeds with the right password and fails otherwise', () async {
    await repository.register(
      name: 'Jane',
      email: 'jane@mail.test',
      password: 'secret-pass',
    );
    await repository.logout();
    expect(await repository.isLoggedIn(), isFalse);

    expect(
      repository.login(email: 'jane@mail.test', password: 'wrong-pass'),
      throwsA(isA<AuthException>()),
    );
    final AuthUserModel user = await repository.login(
      email: ' JANE@mail.test ', // spaces and case are ignored
      password: 'secret-pass',
    );
    expect(user.email, 'jane@mail.test');
    expect(await repository.isLoggedIn(), isTrue);
  });

  test('duplicate registration is rejected', () async {
    await repository.register(name: 'A', email: 'a@b.co', password: '123456');
    expect(
      repository.register(name: 'A', email: 'A@b.co', password: '123456'),
      throwsA(isA<AuthException>()),
    );
  });

  test('demo account can log in', () async {
    await repository.ensureDemoAccount();
    final AuthUserModel user = await repository.login(
      email: AppConstants.demoEmail,
      password: AppConstants.demoPassword,
    );
    expect(user.name, AppConstants.demoName);
  });
}
