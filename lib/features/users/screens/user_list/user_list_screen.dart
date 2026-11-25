import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/widgets/user_city_filter.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/widgets/user_list_view.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/widgets/user_search_field.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/widgets/user_sort_menu.dart';

/// User list page.
///
/// Top: search field + sort menu + city chips (the "header" group of the
/// state). Below: the list/grid of users (the "content" group). Each part
/// listens to its own group, so typing in the search box never rebuilds
/// the whole screen. Tapping a user opens the user details page.
///
/// The [UserListCubit] is provided above this widget by the route.
class UserListScreen extends StatelessWidget {
  /// Creates the user list page.
  const UserListScreen({super.key});

  /// Builds the static page layout. The parts that change are separate
  /// widgets that each select their own piece of state.
  @override
  Widget build(BuildContext context) {
    // Listens to one-time effects of UserListCubit (snackbars, navigation to
    // the details page). It does not rebuild anything itself.
    return ScreenEffectListener<UserListCubit, UserListBuildState>(
      screenName: 'UserListScreen',
      child: Scaffold(
        // Title bar.
        appBar: AppBar(title: const Text(AppStrings.users)),
        body: BusyGuard<UserListCubit, UserListBuildState>(
          // Disabled while a request is running.
          child: Column(
            children: <Widget>[
              // Header: search, sort and city filter (kept narrow on desktop).
              MaxWidthContainer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding,
                    AppDimensions.gap,
                    AppDimensions.pagePadding,
                    0,
                  ),
                  child: Column(
                    children: <Widget>[
                      // Search box takes the free width; sort button on the right.
                      const Row(
                        children: <Widget>[
                          Expanded(child: UserSearchField()),
                          UserSortMenu(),
                        ],
                      ),
                      SizedBox(height: AppDimensions.gapSmall),
                      // Row of city chips below the search box.
                      const UserCityFilter(),
                    ],
                  ),
                ),
              ),
              // Content: loader / error / empty / list, filling the rest.
              const Expanded(child: UserListView()),
            ],
          ),
        ),
      ),
    );
  }
}
