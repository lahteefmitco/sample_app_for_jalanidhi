import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/responsive_list_grid.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/widgets/user_list_empty_view.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/widgets/user_list_item.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// Renders the content group of the user list state: a loader, an error
/// view, an empty view or the list of users, depending on the status.
class UserListView extends StatelessWidget {
  /// Creates the list area of the user list page.
  const UserListView({super.key});

  /// Builds the view that matches the current loading status.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used to call methods on tap/refresh.
    final UserListCubit cubit = context.read<UserListCubit>();
    // Rebuilds only when the content group changes. The header group (search
    // text, sort, city) is ignored here, so typing alone never rebuilds the
    // list unless the visible users change too.
    return BlocSelector<UserListCubit, UserListState, UserListContentState>(
      selector: (UserListState state) => state.build.content,
      builder: (BuildContext context, UserListContentState content) {
        switch (content.status) {
          // Nothing loaded yet or a load is running: show a spinner.
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const CommonLoader();
          // Load failed: show the message and a retry button.
          case ViewStatus.error:
            return CommonErrorWidget(
              message: content.errorMessage ?? '',
              onRetry: () => cubit.load(forceRefresh: true),
            );
          // Loaded, but no user matches the search/filter.
          case ViewStatus.empty:
            return const UserListEmptyView();
          // Loaded: show the users; pull down to reload from the server.
          case ViewStatus.loaded:
            return RefreshIndicator(
              onRefresh: () => cubit.load(forceRefresh: true),
              // List on phones, grid on wider screens.
              child: ResponsiveListGrid(
                itemCount: content.users.length,
                tileHeight: 104,
                itemBuilder: (BuildContext context, int index) {
                  final UserModel user = content.users[index];
                  // One tile per user; tapping it opens the details page.
                  return UserListItem(
                    user: user,
                    onTap: () => cubit.onUserTapped(user),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
