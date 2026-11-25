import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/auth_user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

import '../../helpers/in_memory_storage.dart';

/// A mocktail mock of [AuthRepository]; each test decides what it returns.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Unit tests for [LoginCubit]: prefilling the last email, validation,
/// successful and failed logins, and the password visibility toggle.
void main() {
  /// Mocked [AuthRepository]; each test decides what it returns.
  late MockAuthRepository auth;

  /// In-memory stand-in for the device preferences.
  late InMemoryLocalStorage prefs;

  /// The [LoginCubit] under test.
  late LoginCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    prefs = InMemoryLocalStorage();
    cubit = LoginCubit(authRepository: auth, preferences: prefs);
  });

  tearDown(() => cubit.close());

  /// Collects every effect the cubit emits while [action] runs.
  Future<List<UiEffect>> effectsOf(Future<void> Function() action) async {
    final List<UiEffect> effects = <UiEffect>[];
    final StreamSubscription<ScreenState<LoginBuildState>> sub = cubit.stream
        .listen((ScreenState<LoginBuildState> s) {
          if (s.effect != null) effects.add(s.effect!);
        });
    await action();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return effects;
  }

  test('prefills the last used email', () async {
    // Arrange: an email saved by an earlier login, before the cubit exists.
    await prefs.setString(StorageKeys.lastLoginEmail, 'me@mail.test');
    final LoginCubit other = LoginCubit(
      authRepository: auth,
      preferences: prefs,
    );
    expect(other.emailController.text, 'me@mail.test');
    await other.close();
  });

  test('invalid input sets field errors and does not call the API', () async {
    cubit.emailController.text = 'bad';
    final List<UiEffect> effects = await effectsOf(cubit.submit);
    expect(cubit.state.build.emailError, isNotNull);
    expect(cubit.state.build.passwordError, isNotNull);
    expect(effects, isEmpty);
    verifyNever(
      () => auth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('successful login: progress, hide, then navigate to home', () async {
    // Arrange: the mock accepts these exact (trimmed) credentials.
    when(() => auth.login(email: 'a@b.co', password: 'pw')).thenAnswer(
      (Invocation _) async => const AuthUserModel(name: 'A', email: 'a@b.co'),
    );
    cubit.emailController.text = ' a@b.co ';
    cubit.passwordController.text = 'pw';

    // Act
    final List<UiEffect> effects = await effectsOf(cubit.submit);

    // Assert
    expect(effects[0], isA<ShowProgressEffect>());
    expect(effects[1], isA<HideProgressEffect>());
    final NavigateEffect navigate = effects[2] as NavigateEffect;
    expect(navigate.routeName, RouteNames.home);
    expect(navigate.mode, NavigationStyle.clearStack);
    expect(prefs.getString(StorageKeys.lastLoginEmail), 'a@b.co');
  });

  test('failed login hides progress and shows an error snackbar', () async {
    // Arrange: the mock rejects every login.
    when(
      () => auth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthException('Invalid email or password'));
    cubit.emailController.text = 'a@b.co';
    cubit.passwordController.text = 'pw';

    // Act
    final List<UiEffect> effects = await effectsOf(cubit.submit);

    // Assert
    expect(effects[0], isA<ShowProgressEffect>());
    expect(effects[1], isA<HideProgressEffect>());
    final ShowSnackbarEffect snack = effects[2] as ShowSnackbarEffect;
    expect(snack.type, SnackbarType.error);
    expect(snack.message, 'Invalid email or password');
    expect(effects.whereType<NavigateEffect>(), isEmpty);
  });

  test('password visibility toggles in the build state', () {
    expect(cubit.state.build.obscurePassword, isTrue);
    cubit.togglePasswordVisibility();
    expect(cubit.state.build.obscurePassword, isFalse);
  });
}
