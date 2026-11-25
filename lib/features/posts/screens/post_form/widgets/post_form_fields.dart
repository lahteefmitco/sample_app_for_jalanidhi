import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_button.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_text_field.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// The form body: author dropdown, title, body and the save button.
///
/// Validation errors and the selected author come from the Cubit's state;
/// the typed text lives in the Cubit's controllers.
class PostFormFields extends StatelessWidget {
  /// Creates the form fields.
  const PostFormFields({super.key});

  /// Builds the fields in a column, stretched to the full width.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): used for the controllers and callbacks.
    final PostFormCubit cubit = context.read<PostFormCubit>();
    // Rebuilds whenever the Cubit emits a new build state (e.g. validation
    // errors or a new author); `buildStateChanged` skips effect-only states
    // such as showing the progress dialog.
    return BlocBuilder<PostFormCubit, PostFormState>(
      buildWhen: buildStateChanged,
      builder: (BuildContext context, PostFormState state) {
        final PostFormBuildState form = state.build;
        // Same vertical space between the fields, reused below.
        final SizedBox gap = SizedBox(height: AppDimensions.gap);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Author dropdown, one entry per user.
            DropdownButtonFormField<int>(
              initialValue: form.selectedUserId,
              decoration: const InputDecoration(
                labelText: AppStrings.author,
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<int>>[
                for (final UserModel user in form.users)
                  DropdownMenuItem<int>(value: user.id, child: Text(user.name)),
              ],
              onChanged: cubit.onUserChanged,
            ),
            gap,
            // Title field; "next" on the keyboard moves to the body field.
            CommonTextField(
              controller: cubit.titleController,
              label: AppStrings.postTitle,
              errorText: form.titleError,
              textInputAction: TextInputAction.next,
            ),
            gap,
            // Body field: multi-line text, up to 8 visible lines.
            CommonTextField(
              controller: cubit.bodyController,
              label: AppStrings.postBody,
              errorText: form.bodyError,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: AppDimensions.gapLarge),
            // Save button: validates and saves (see PostFormCubit.submit).
            CommonButton(
              label: AppStrings.save,
              icon: Icons.save_outlined,
              onPressed: cubit.submit,
            ),
          ],
        );
      },
    );
  }
}
