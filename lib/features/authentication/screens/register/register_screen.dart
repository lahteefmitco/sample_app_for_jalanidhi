import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_state.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/widgets/register_button.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/widgets/register_form.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/widgets/auth_header.dart';

/// Registration page (local account simulation).
///
/// Same structure as the login page: header, form and buttons inside a
/// centered, scrollable column. Validation and sign-up are done by
/// `RegisterCubit`; one-time effects are handled by `ScreenEffectListener`.
class RegisterScreen extends StatelessWidget {
  /// Creates the register page. The `RegisterCubit` must already be
  /// provided above it (the route does that).
  const RegisterScreen({super.key});

  /// Builds the static page layout; only `RegisterForm` rebuilds on state
  /// changes.
  @override
  Widget build(BuildContext context) {
    // Listens to RegisterCubit and executes the one-time effects (progress,
    // snackbar, navigation, pop) it requests. It does not rebuild the page.
    return ScreenEffectListener<RegisterCubit, RegisterBuildState>(
      screenName: 'RegisterScreen',
      child: Scaffold(
        // Empty app bar: gives the user a back arrow to the login page.
        appBar: AppBar(),
        body: BusyGuard<RegisterCubit, RegisterBuildState>(
          // Disabled while a request is running.
          child: SafeArea(
            // Centered + scrollable so the keyboard never hides the form.
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppDimensions.pagePadding),
                // Caps the width so the form does not stretch on wide screens.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Title and the "simulated accounts" disclaimer.
                      const AuthHeader(
                        title: AppStrings.createAccount,
                        subtitle: AppStrings.authDisclaimer,
                      ),
                      SizedBox(height: AppDimensions.gapLarge),
                      // Name, email, password and confirmation fields.
                      const RegisterForm(),
                      SizedBox(height: AppDimensions.gapLarge),
                      // Register button and link back to login.
                      const RegisterButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
