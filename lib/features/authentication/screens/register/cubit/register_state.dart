import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';

/// What the register form renders: password visibility and field errors.
///
/// It is immutable: `RegisterCubit` creates a new instance for every change.
/// Progress, snackbars and navigation are one-time effects, not part of it.
@immutable
class RegisterBuildState {
  /// Creates the state; the defaults describe an untouched form
  /// (passwords hidden, no errors).
  const RegisterBuildState({
    this.obscurePassword = true,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmError,
  });

  /// `true` while both password fields show dots instead of the text.
  final bool obscurePassword;

  /// Message under the name field, or `null` when there is no error.
  final String? nameError;

  /// Message under the email field, or `null` when there is no error.
  final String? emailError;

  /// Message under the password field, or `null` when there is no error.
  final String? passwordError;

  /// Message under the "confirm password" field, or `null` when there is no
  /// error.
  final String? confirmError;

  /// Readable description used in logs and while debugging.
  @override
  String toString() =>
      'RegisterBuildState(obscurePassword: $obscurePassword, '
      'nameError: $nameError, emailError: $emailError, '
      'passwordError: $passwordError, confirmError: $confirmError)';
}

/// Full state of the register screen: the [RegisterBuildState] plus the
/// one-time effect. Short name for `BlocBuilder<RegisterCubit, RegisterState>`.
typedef RegisterState = ScreenState<RegisterBuildState>;
