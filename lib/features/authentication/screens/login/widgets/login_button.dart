import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_button.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';

/// Login button and the "register" link.
///
/// It does not depend on the state, so it never rebuilds; it only forwards
/// taps to `LoginCubit`.
class LoginButton extends StatelessWidget {
  /// Creates the button column. Needs a `LoginCubit` above it in the tree.
  const LoginButton({super.key});

  /// Builds the login button and the link to the register page.
  @override
  Widget build(BuildContext context) {
    // `read` (not `watch`): we only call methods, we do not listen to state.
    final LoginCubit cubit = context.read<LoginCubit>();
    return Column(
      children: <Widget>[
        // Main action: validates the form and signs in.
        CommonButton(
          label: AppStrings.login,
          icon: Icons.login,
          onPressed: cubit.submit,
        ),
        // "No account yet?" link: opens the register page.
        TextButton(
          onPressed: cubit.onRegisterTapped,
          child: const Text(AppStrings.noAccountYet),
        ),
      ],
    );
  }
}
