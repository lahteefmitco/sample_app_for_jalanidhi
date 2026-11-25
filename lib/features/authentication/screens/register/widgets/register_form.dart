import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_text_field.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_state.dart';

/// The four registration fields; errors and the password visibility come from the Cubit state.
///
/// The typed text lives in the Cubit's `TextEditingController`s, so
/// rebuilding this widget never loses what the user typed.
class RegisterForm extends StatelessWidget {
  /// Creates the form. Needs a `RegisterCubit` above it in the tree.
  const RegisterForm({super.key});

  /// Builds the fields inside a `BlocBuilder` so errors and the eye icon
  /// update when the Cubit emits a new build state.
  @override
  Widget build(BuildContext context) {
    // Used to reach the controllers and call Cubit methods (no listening).
    final RegisterCubit cubit = context.read<RegisterCubit>();
    // Rebuilds the fields when RegisterCubit emits a new RegisterBuildState.
    // buildWhen = buildStateChanged: effects (snackbar, progress) reuse the
    // same build state, so they do not cause a useless rebuild.
    return BlocBuilder<RegisterCubit, RegisterState>(
      buildWhen: buildStateChanged<RegisterBuildState>,
      builder: (BuildContext context, RegisterState state) {
        // Only the build part matters here; effects are handled elsewhere.
        final RegisterBuildState form = state.build;
        // One spacer instance reused between all fields.
        final SizedBox gap = SizedBox(height: AppDimensions.gap);
        return Column(
          children: <Widget>[
            // Full name field.
            CommonTextField(
              controller: cubit.nameController,
              label: AppStrings.fullName,
              errorText: form.nameError,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline,
            ),
            gap,
            // Email field.
            CommonTextField(
              controller: cubit.emailController,
              label: AppStrings.email,
              errorText: form.emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
            ),
            gap,
            // Password field with the eye icon that shows / hides both
            // password fields.
            CommonTextField(
              controller: cubit.passwordController,
              label: AppStrings.password,
              errorText: form.passwordError,
              obscureText: form.obscurePassword,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline,
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
            gap,
            // Confirmation field; "done" on the keyboard submits the form.
            CommonTextField(
              controller: cubit.confirmController,
              label: AppStrings.confirmPassword,
              errorText: form.confirmError,
              obscureText: form.obscurePassword,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              onSubmitted: (String _) => cubit.submit(),
            ),
          ],
        );
      },
    );
  }
}
