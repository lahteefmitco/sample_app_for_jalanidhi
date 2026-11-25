import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_state.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/widgets/post_details_body.dart';

/// Post details page: the post, its author and its comments.
///
/// The app bar has edit and delete actions (delete is confirmed through a
/// dialog requested by the Cubit). Tapping a comment opens a bottom sheet.
///
/// The [PostDetailsCubit] is provided above this widget by the route.
class PostDetailsScreen extends StatelessWidget {
  /// Creates the post details page.
  const PostDetailsScreen({super.key});

  /// Builds the app bar with its actions and the part of the page that
  /// follows the loading status.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used for button and retry callbacks.
    final PostDetailsCubit cubit = context.read<PostDetailsCubit>();
    // Listens to one-time effects of PostDetailsCubit (delete confirmation,
    // comment bottom sheet, snackbars, closing the page after a delete).
    // It does not rebuild anything itself.
    return ScreenEffectListener<PostDetailsCubit, PostDetailsBuildState>(
      screenName: 'PostDetailsScreen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.postDetails),
          // Edit opens the form; delete asks for confirmation first.
          actions: <Widget>[
            BusyGuard<PostDetailsCubit, PostDetailsBuildState>(
              // App-bar action: disabled while a request is running.
              child: IconButton(
                tooltip: AppStrings.edit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: cubit.onEditPressed,
              ),
            ),
            BusyGuard<PostDetailsCubit, PostDetailsBuildState>(
              // App-bar action: disabled while a request is running.
              child: IconButton(
                tooltip: AppStrings.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: cubit.onDeletePressed,
              ),
            ),
          ],
        ),
        // Rebuilds only when the Cubit emits a new build state;
        // `buildStateChanged` skips states that only carry a new effect.
        body: BusyGuard<PostDetailsCubit, PostDetailsBuildState>(
          // Disabled while a request is running.
          child: BlocBuilder<PostDetailsCubit, PostDetailsState>(
            buildWhen: buildStateChanged,
            builder: (BuildContext context, PostDetailsState state) {
              final PostDetailsBuildState build = state.build;
              switch (build.status) {
                // Nothing loaded yet or a load is running: show a spinner.
                case ViewStatus.initial:
                case ViewStatus.loading:
                  return const CommonLoader();
                // Load failed: show the message and a retry button.
                case ViewStatus.error:
                  return CommonErrorWidget(
                    message: build.errorMessage ?? '',
                    onRetry: cubit.load,
                  );
                // Loaded: show the post card and the comments.
                case ViewStatus.empty:
                case ViewStatus.loaded:
                  return PostDetailsBody(details: build);
              }
            },
          ),
        ),
      ),
    );
  }
}
