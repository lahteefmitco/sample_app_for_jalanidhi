import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_state.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/widgets/login_button.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/widgets/login_form.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/widgets/auth_header.dart';
import 'package:sample_app_for_jalanidhi/global/widgets/theme_mode_button.dart';

/// Login page.
///
/// Layout: a centered, scrollable column (max 440 px wide, so it stays
/// readable on desktop/web) with the header, the form and the buttons.
/// All logic lives in `LoginCubit`; this widget only wires the pieces and
/// the `ScreenEffectListener`, which performs navigation, progress and
/// snackbars requested by the Cubit.
class LoginScreen extends StatelessWidget {
  /// Creates the login page. The `LoginCubit` must already be provided above
  /// it (the route does that).
  const LoginScreen({super.key});

  /// Builds the static page layout; only `LoginForm` rebuilds on state
  /// changes.
  @override
  Widget build(BuildContext context) {
    // Listens to LoginCubit and executes the one-time effects (progress,
    // snackbar, navigation) it requests. It does not rebuild the page.
    return ScreenEffectListener<LoginCubit, LoginBuildState>(
      screenName: 'LoginScreen',
      child: Scaffold(
        // The theme can be changed even before signing in.
        appBar: AppBar(actions: const <Widget>[ThemeModeButton()]),
        body: BusyGuard<LoginCubit, LoginBuildState>(
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
                      // Logo, title and app name.
                      const AuthHeader(
                        title: AppStrings.welcomeBack,
                        subtitle: AppConstants.appName,
                      ),
                      SizedBox(height: AppDimensions.gapLarge),
                      // Email + password fields (state-driven errors).
                      const LoginForm(),
                      SizedBox(height: AppDimensions.gapLarge),
                      // Login button and link to the register page.
                      const LoginButton(),
                      SizedBox(height: AppDimensions.gap),
                      // Explains that auth is simulated and shows the demo account.
                      Text(
                        '${AppStrings.authDisclaimer}\n'
                        'Demo: ${AppConstants.demoEmail} / '
                        '${AppConstants.demoPassword}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSmall,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
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
