import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_state.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/widgets/post_form_fields.dart';

/// Create / edit post page (edit when the Cubit has a post id).
///
/// The shell rebuilds only when the loading status changes; the fields
/// (`PostFormFields`) rebuild for every form change (validation errors,
/// selected author). Saving pops the page with the result `'saved'`.
///
/// The [PostFormCubit] is provided above this widget by the route.
class PostFormScreen extends StatelessWidget {
  /// Creates the post form page.
  const PostFormScreen({super.key});

  /// Builds the app bar and the part of the page that follows the status.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): used for the title and the retry callback.
    final PostFormCubit cubit = context.read<PostFormCubit>();
    // Listens to one-time effects of PostFormCubit: shows progress while
    // saving, error snackbars, and pops the page when done. It does not
    // rebuild anything itself.
    return ScreenEffectListener<PostFormCubit, PostFormBuildState>(
      screenName: 'PostFormScreen',
      child: Scaffold(
        appBar: AppBar(
          // "New post" or "Edit post" depending on the Cubit's mode.
          title: Text(cubit.isEdit ? AppStrings.editPost : AppStrings.newPost),
        ),
        body: BusyGuard<PostFormCubit, PostFormBuildState>(
          // Disabled while a request is running.
          child: BlocBuilder<PostFormCubit, PostFormState>(
            // Rebuild the shell only when the loading status changes; the
            // fields below rebuild themselves on every form state change.
            buildWhen: (PostFormState previous, PostFormState current) =>
                previous.build.status != current.build.status,
            builder: (BuildContext context, PostFormState state) {
              switch (state.build.status) {
                // Nothing loaded yet or a load is running: show a spinner.
                case ViewStatus.initial:
                case ViewStatus.loading:
                  return const CommonLoader();
                // Load failed: show the message and a retry button.
                case ViewStatus.error:
                  return CommonErrorWidget(
                    message: state.build.errorMessage ?? '',
                    onRetry: cubit.load,
                  );
                // Loaded: show the form, narrow and scrollable.
                case ViewStatus.empty:
                case ViewStatus.loaded:
                  return MaxWidthContainer(
                    maxWidth: 640,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(AppDimensions.pagePadding),
                      child: const PostFormFields(),
                    ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}
