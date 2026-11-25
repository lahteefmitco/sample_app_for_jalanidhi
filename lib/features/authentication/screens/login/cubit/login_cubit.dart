import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/storage/local_storage_service.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/utils/validators.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_state.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

/// Cubit of the login screen: validates the form, signs in through the
/// (simulated) [AuthRepository] and tells the screen where to go next.
///
/// It never touches widgets directly: it emits a [LoginBuildState] for the
/// form and one-time effects (progress, snackbar, navigation) that
/// `ScreenEffectListener` executes.
class LoginCubit extends ScreenCubit<LoginBuildState> {
  /// Creates the Cubit with its dependencies and starts from an empty form.
  ///
  /// Called by the route when the login page is opened, so the Cubit lives
  /// exactly as long as the page.
  LoginCubit({required this._authRepository, required this._preferences})
    : super(const LoginBuildState(), name: 'LoginCubit') {
    // Pre-fill the email used for the previous successful login, so a
    // returning user only has to type the password.
    emailController.text =
        _preferences.getString(StorageKeys.lastLoginEmail) ?? '';
  }

  /// Performs the actual (simulated) sign-in.
  final AuthRepository _authRepository;

  /// Local key-value storage; used to remember the last login email.
  final LocalStorageService _preferences;

  /// Text of the email field. Owned by the Cubit (so the text survives
  /// rebuilds) and disposed in [close].
  final TextEditingController emailController = TextEditingController();

  /// Text of the password field. Owned by the Cubit and disposed in [close].
  final TextEditingController passwordController = TextEditingController();

  // Working data. The immutable build state is rebuilt from these fields.

  /// `true` while the password is hidden behind dots.
  bool _obscurePassword = true;

  /// Validation message shown under the email field, or `null` when valid.
  String? _emailError;

  /// Validation message shown under the password field, or `null` when valid.
  String? _passwordError;

  /// Copies the working fields into a fresh, immutable [LoginBuildState] and
  /// emits it, so the `BlocBuilder` in `LoginForm` rebuilds.
  void _render() {
    emitBuild(
      LoginBuildState(
        obscurePassword: _obscurePassword,
        emailError: _emailError,
        passwordError: _passwordError,
      ),
    );
  }

  /// Shows or hides the password text.
  ///
  /// Triggered by the eye icon in the password field; emits a new build
  /// state with the flipped `obscurePassword` value.
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    _render();
  }

  /// "Register" link: asks the screen to open the register page.
  ///
  /// Triggered by the text button under the login button; emits a
  /// navigation effect (no build state change).
  void onRegisterTapped() => navigateTo(RouteNames.register);

  /// Validates the form, then logs in. Progress, errors and navigation are
  /// emitted as one-time effects, never stored in the build state.
  ///
  /// Triggered by the login button or the keyboard "done" key in the
  /// password field. Emits a build state with the field errors first; on
  /// success it opens the home page and removes login from the back stack.
  Future<void> submit() async {
    // A request is already running: ignore a second tap / Enter key press.
    if (isBusy) {
      return;
    }
    // Spaces around the email are a common typing mistake, so trim them.
    final String email = emailController.text.trim();
    // Passwords are used exactly as typed (spaces may be intentional).
    final String password = passwordController.text;

    _emailError = Validators.email(email);
    _passwordError = Validators.required(password);
    _render();
    // Stop here when any field is invalid; the errors are already visible.
    if (_emailError != null || _passwordError != null) return;

    cubitLog('submit: logging in $email', funtionName: 'submit');
    showProgress();
    try {
      await _authRepository.login(email: email, password: password);
      // Remember the email so the next login can pre-fill it.
      await _preferences.setString(StorageKeys.lastLoginEmail, email);
      hideProgress();
      // clearStack: the user must not be able to go "back" to the login page.
      navigateTo(RouteNames.home, mode: NavigationStyle.clearStack);
    } on Object catch (error) {
      hideProgress();
      showError(error);
    }
  }

  /// Disposes the text controllers, then closes the Cubit.
  ///
  /// Called automatically by `BlocProvider` when the login route is removed.
  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
