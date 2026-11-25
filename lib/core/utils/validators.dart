import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';

/// Pure validation functions. Each returns an error message or `null`.
///
/// They match the `validator:` signature of `TextFormField`, so a form can
/// use them directly, e.g. `validator: Validators.email`.
abstract final class Validators {
  /// Simple "something@something.something" check, without spaces.
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Fails when [value] is null, empty or only spaces.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  /// Fails when [value] is empty or not shaped like an email address.
  static String? email(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    return _email.hasMatch(value!.trim()) ? null : AppStrings.invalidEmail;
  }

  /// Fails when [value] is empty or shorter than
  /// [AppConstants.minPasswordLength].
  static String? password(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    return value!.length >= AppConstants.minPasswordLength
        ? null
        : '${AppStrings.passwordTooShort} '
              '(min ${AppConstants.minPasswordLength})';
  }

  /// Fails when [value] is empty or differs from [original] (the first
  /// password field).
  static String? confirmPassword(String? value, String? original) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    return value == original ? null : AppStrings.passwordsDoNotMatch;
  }
}
