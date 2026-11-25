import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';

/// What the login form renders. Navigation, progress and snackbars are NOT
/// part of it; they are `UiEffect`s of the surrounding `ScreenState`.
///
/// It is immutable: `LoginCubit` creates a new instance for every change, so
/// widgets can tell that something changed just by comparing instances.
@immutable
class LoginBuildState {
  /// Creates the state; the defaults describe an untouched form
  /// (password hidden, no errors).
  const LoginBuildState({
    this.obscurePassword = true,
    this.emailError,
    this.passwordError,
  });

  /// `true` while the password field shows dots instead of the text.
  final bool obscurePassword;

  /// Message shown under the email field, or `null` when there is no error.
  final String? emailError;

  /// Message shown under the password field, or `null` when there is no
  /// error.
  final String? passwordError;

  /// Readable description used in logs and while debugging.
  @override
  String toString() =>
      'LoginBuildState(obscurePassword: $obscurePassword, '
      'emailError: $emailError, passwordError: $passwordError)';
}

/// Full state of the login screen: the [LoginBuildState] plus the one-time
/// effect. Short name so widgets can write `BlocBuilder<LoginCubit, LoginState>`.
typedef LoginState = ScreenState<LoginBuildState>;
