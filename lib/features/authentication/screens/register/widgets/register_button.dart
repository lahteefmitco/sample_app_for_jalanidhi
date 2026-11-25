import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_button.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_cubit.dart';

/// Register button and the "already have an account" link.
///
/// It does not depend on the state, so it never rebuilds; it only forwards
/// taps to `RegisterCubit`.
class RegisterButton extends StatelessWidget {
  /// Creates the button column. Needs a `RegisterCubit` above it in the tree.
  const RegisterButton({super.key});

  /// Builds the register button and the link back to the login page.
  @override
  Widget build(BuildContext context) {
    // `read` (not `watch`): we only call methods, we do not listen to state.
    final RegisterCubit cubit = context.read<RegisterCubit>();
    return Column(
      children: <Widget>[
        // Main action: validates the form and creates the account.
        CommonButton(
          label: AppStrings.register,
          icon: Icons.person_add_alt_1,
          onPressed: cubit.submit,
        ),
        // "Already have an account?" link: goes back to the login page.
        TextButton(
          onPressed: cubit.onLoginTapped,
          child: const Text(AppStrings.haveAccount),
        ),
      ],
    );
  }
}
