import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/storage/local_storage_service.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/utils/validators.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_state.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

/// Cubit of the register screen: validates the form, creates the local
/// account and signs the new user in.
///
/// Like every screen Cubit it only emits state: a [RegisterBuildState] for
/// the form and one-time effects (progress, snackbar, navigation).
class RegisterCubit extends ScreenCubit<RegisterBuildState> {
  /// Creates the Cubit with its dependencies and starts from an empty form.
  ///
  /// Called by the route when the register page is opened.
  RegisterCubit({required this._authRepository, required this._preferences})
    : super(const RegisterBuildState(), name: 'RegisterCubit');

  /// Creates the (simulated) account and signs the user in.
  final AuthRepository _authRepository;

  /// Local key-value storage; used to remember the email for the next login.
  final LocalStorageService _preferences;

  /// Text of the "full name" field. Owned by the Cubit, disposed in [close].
  final TextEditingController nameController = TextEditingController();

  /// Text of the email field. Owned by the Cubit, disposed in [close].
  final TextEditingController emailController = TextEditingController();

  /// Text of the password field. Owned by the Cubit, disposed in [close].
  final TextEditingController passwordController = TextEditingController();

  /// Text of the "confirm password" field. Owned by the Cubit, disposed in
  /// [close].
  final TextEditingController confirmController = TextEditingController();

  // Working data. The immutable build state is rebuilt from these fields.

  /// `true` while both password fields show dots instead of the text.
  bool _obscurePassword = true;

  /// Validation message for the name field, or `null` when valid.
  String? _nameError;

  /// Validation message for the email field, or `null` when valid.
  String? _emailError;

  /// Validation message for the password field, or `null` when valid.
  String? _passwordError;

  /// Validation message for the confirmation field, or `null` when valid.
  String? _confirmError;

  /// Copies the working fields into a fresh, immutable [RegisterBuildState]
  /// and emits it, so the `BlocBuilder` in `RegisterForm` rebuilds.
  void _render() {
    emitBuild(
      RegisterBuildState(
        obscurePassword: _obscurePassword,
        nameError: _nameError,
        emailError: _emailError,
        passwordError: _passwordError,
        confirmError: _confirmError,
      ),
    );
  }

  /// Shows or hides both password fields.
  ///
  /// Triggered by the eye icon in the password field; emits a new build
  /// state with the flipped `obscurePassword` value.
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    _render();
  }

  /// "Already have an account?" link: go back to the login page.
  ///
  /// Triggered by the text button under the register button; emits a
  /// [PopEffect] that closes this page.
  void onLoginTapped() => emitEffect(const PopEffect());

  /// Validates every field, then registers. Errors appear under the fields;
  /// progress, failures and navigation are one-time effects.
  ///
  /// Triggered by the register button or the keyboard "done" key in the
  /// confirmation field. Emits a build state with the field errors first;
  /// on success it opens the home page and clears the back stack.
  Future<void> submit() async {
    // A request is already running: ignore a second tap / Enter key press.
    if (isBusy) {
      return;
    }
    // Trim accidental spaces around name and email.
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    // Passwords are used exactly as typed.
    final String password = passwordController.text;

    _nameError = Validators.required(name);
    _emailError = Validators.email(email);
    _passwordError = Validators.password(password);
    _confirmError = Validators.confirmPassword(
      confirmController.text,
      password,
    );
    _render();
    // Stop when any field is invalid; the errors are already visible.
    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }

    cubitLog('submit: registering $email', funtionName: 'submit');
    showProgress();
    try {
      await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      // Remember the email so the next login can pre-fill it.
      await _preferences.setString(StorageKeys.lastLoginEmail, email);
      hideProgress();
      // clearStack: login/register must not stay behind the home page.
      navigateTo(RouteNames.home, mode: NavigationStyle.clearStack);
    } on Object catch (error) {
      hideProgress();
      showError(error);
    }
  }

  /// Disposes the four text controllers, then closes the Cubit.
  ///
  /// Called automatically by `BlocProvider` when the register route is
  /// removed.
  @override
  Future<void> close() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    return super.close();
  }
}
