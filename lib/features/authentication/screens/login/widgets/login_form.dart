import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_text_field.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_state.dart';

/// Email and password fields; errors and the password visibility come from the Cubit state.
///
/// The typed text itself lives in the Cubit's `TextEditingController`s, so
/// rebuilding this widget never loses what the user typed.
class LoginForm extends StatelessWidget {
  /// Creates the form. Needs a `LoginCubit` above it in the tree.
  const LoginForm({super.key});

  /// Builds both fields inside a `BlocBuilder` so errors and the eye icon
  /// update when the Cubit emits a new build state.
  @override
  Widget build(BuildContext context) {
    // Used to reach the controllers and call Cubit methods (no listening).
    final LoginCubit cubit = context.read<LoginCubit>();
    // Rebuilds the fields when LoginCubit emits a new LoginBuildState.
    // buildWhen = buildStateChanged: effects (snackbar, progress) reuse the
    // same build state, so they do not cause a useless rebuild.
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: buildStateChanged<LoginBuildState>,
      builder: (BuildContext context, LoginState state) {
        // Only the build part matters here; effects are handled elsewhere.
        final LoginBuildState form = state.build;
        return Column(
          children: <Widget>[
            // Email field; "next" on the keyboard jumps to the password.
            CommonTextField(
              controller: cubit.emailController,
              label: AppStrings.email,
              errorText: form.emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
              autofillHints: const <String>[AutofillHints.email],
            ),
            SizedBox(height: AppDimensions.gap),
            // Password field; "done" on the keyboard submits the form.
            CommonTextField(
              controller: cubit.passwordController,
              label: AppStrings.password,
              errorText: form.passwordError,
              obscureText: form.obscurePassword,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              autofillHints: const <String>[AutofillHints.password],
              onSubmitted: (String _) => cubit.submit(),
              // Eye icon that shows / hides the password text.
              suffixIcon: IconButton(
                tooltip: 'Toggle password visibility',
                icon: Icon(
                  form.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: cubit.togglePasswordVisibility,
              ),
            ),
          ],
        );
      },
    );
  }
}
