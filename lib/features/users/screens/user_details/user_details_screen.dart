import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_state.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/widgets/user_details_body.dart';

/// User details page: contact info, address, company and the user's posts.
///
/// Shows a loader, an error view with retry, or the body depending on the
/// Cubit's `ViewStatus`. The body is two columns on wide windows.
///
/// The [UserDetailsCubit] is provided above this widget by the route.
class UserDetailsScreen extends StatelessWidget {
  /// Creates the user details page.
  const UserDetailsScreen({super.key});

  /// Builds the app bar and the part of the page that follows the status.
  @override
  Widget build(BuildContext context) {
    // Listens to one-time effects of UserDetailsCubit (snackbars, opening a
    // post). It does not rebuild anything itself.
    return ScreenEffectListener<UserDetailsCubit, UserDetailsBuildState>(
      screenName: 'UserDetailsScreen',
      child: Scaffold(
        // Title bar.
        appBar: AppBar(title: const Text(AppStrings.userDetails)),
        // Rebuilds only when the Cubit emits a new build state;
        // `buildStateChanged` skips states that only carry a new effect.
        body: BusyGuard<UserDetailsCubit, UserDetailsBuildState>(
          // Disabled while a request is running.
          child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
            buildWhen: buildStateChanged,
            builder: (BuildContext context, UserDetailsState state) {
              final UserDetailsBuildState build = state.build;
              switch (build.status) {
                // Nothing loaded yet or a load is running: show a spinner.
                case ViewStatus.initial:
                case ViewStatus.loading:
                  return const CommonLoader();
                // Load failed: show the message and a retry button.
                case ViewStatus.error:
                  return CommonErrorWidget(
                    message: build.errorMessage ?? '',
                    onRetry: context.read<UserDetailsCubit>().load,
                  );
                // Loaded: show the info card and the posts.
                case ViewStatus.empty:
                case ViewStatus.loaded:
                  return UserDetailsBody(details: build);
              }
            },
          ),
        ),
      ),
    );
  }
}
