import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/auth_user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

import '../../helpers/effects.dart';
import '../../helpers/in_memory_storage.dart';

/// A mocktail mock of [AuthRepository]; each test decides what it returns.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Unit tests for [RegisterCubit]: field validation, successful and failed
/// registration, the "login" link and the password toggle.
void main() {
  /// Mocked [AuthRepository]; each test decides what it returns.
  late MockAuthRepository auth;

  /// In-memory stand-in for the device preferences.
  late InMemoryLocalStorage prefs;

  /// The [RegisterCubit] under test.
  late RegisterCubit cubit;

  /// Types values into the four form fields; the defaults are all valid.
  void fill({
    String name = 'Jane',
    String email = 'jane@mail.test',
    String password = 'secret1',
    String confirm = 'secret1',
  }) {
    cubit.nameController.text = name;
    cubit.emailController.text = email;
    cubit.passwordController.text = password;
    cubit.confirmController.text = confirm;
  }

  setUp(() {
    auth = MockAuthRepository();
    prefs = InMemoryLocalStorage();
    cubit = RegisterCubit(authRepository: auth, preferences: prefs);
  });

  tearDown(() => cubit.close());

  test('empty form reports every field error', () async {
    await cubit.submit();
    final RegisterBuildState build = cubit.state.build;
    expect(build.nameError, isNotNull);
    expect(build.emailError, isNotNull);
    expect(build.passwordError, isNotNull);
    expect(build.confirmError, isNotNull);
  });

  test('short password and mismatching confirmation are rejected', () async {
    fill(password: '123', confirm: '1234');
    await cubit.submit();
    expect(cubit.state.build.passwordError, contains('too short'));
    expect(cubit.state.build.confirmError, AppStrings.passwordsDoNotMatch);
    expect(cubit.state.build.nameError, isNull);
    verifyNever(
      () => auth.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('fixing the input clears the errors on the next submit', () async {
    // First submit with a bad email.
    fill(email: 'bad');
    await cubit.submit();
    expect(cubit.state.build.emailError, isNotNull);

    // Then submit again with valid input (registration succeeds).
    when(
      () => auth.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (Invocation _) async =>
          const AuthUserModel(name: 'Jane', email: 'jane@mail.test'),
    );
    fill();
    await cubit.submit();
    expect(cubit.state.build.emailError, isNull);
  });

  test('successful registration: progress, hide, navigate home', () async {
    // Arrange
    when(
      () => auth.register(
        name: 'Jane',
        email: 'jane@mail.test',
        password: 'secret1',
      ),
    ).thenAnswer(
      (Invocation _) async =>
          const AuthUserModel(name: 'Jane', email: 'jane@mail.test'),
    );
    fill();

    // Act
    final List<UiEffect> effects = await collectEffects(cubit, cubit.submit);

    // Assert
    expect(effects[0], isA<ShowProgressEffect>());
    expect(effects[1], isA<HideProgressEffect>());
    final NavigateEffect navigate = effects[2] as NavigateEffect;
    expect(navigate.routeName, RouteNames.home);
    expect(navigate.mode, NavigationStyle.clearStack);
    expect(prefs.getString(StorageKeys.lastLoginEmail), 'jane@mail.test');
  });

  test(
    'an existing account shows an error snackbar and no navigation',
    () async {
      // Arrange: the repository says the account already exists.
      when(
        () => auth.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException(AppStrings.accountExists));
      fill();

      // Act
      final List<UiEffect> effects = await collectEffects(cubit, cubit.submit);

      // Assert
      expect(effects[1], isA<HideProgressEffect>());
      expect(
        (effects[2] as ShowSnackbarEffect).message,
        AppStrings.accountExists,
      );
      expect(effects.whereType<NavigateEffect>(), isEmpty);
    },
  );

  test('"login" link pops the page and the password toggle works', () async {
    cubit.togglePasswordVisibility();
    expect(cubit.state.build.obscurePassword, isFalse);
    cubit.onLoginTapped();
    expect(cubit.state.effect, isA<PopEffect>());
  });
}
