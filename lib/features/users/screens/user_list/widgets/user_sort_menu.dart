import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/models/user_sort_option.dart';

/// Popup menu to choose the sort order; the current choice is checked.
class UserSortMenu extends StatelessWidget {
  /// Creates the sort button.
  const UserSortMenu({super.key});

  /// Builds the sort icon button and its popup menu.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used to report the chosen option.
    final UserListCubit cubit = context.read<UserListCubit>();
    // Rebuilds only when the sort order changes, so the menu always marks
    // the current choice. Search text and city changes are ignored.
    return BlocSelector<UserListCubit, UserListState, UserSortOption>(
      selector: (UserListState state) => state.build.header.sort,
      builder: (BuildContext context, UserSortOption sort) {
        return PopupMenuButton<UserSortOption>(
          tooltip: AppStrings.sortBy,
          icon: const Icon(Icons.sort),
          // Highlights the current sort order when the menu opens.
          initialValue: sort,
          onSelected: cubit.onSortChanged,
          // One menu entry per sort option.
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<UserSortOption>>[
                for (final UserSortOption option in UserSortOption.values)
                  PopupMenuItem<UserSortOption>(
                    value: option,
                    child: Text(option.label),
                  ),
              ],
        );
      },
    );
  }
}
