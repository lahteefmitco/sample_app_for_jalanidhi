import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_empty_view.dart';

/// Shown when no user matches the search/filter.
class UserListEmptyView extends StatelessWidget {
  /// Creates the empty view of the user list.
  const UserListEmptyView({super.key});

  /// Builds the shared empty view with a "no users" message and icon.
  @override
  Widget build(BuildContext context) {
    // Reuses the app-wide empty view so all empty screens look the same.
    return const CommonEmptyView(
      message: AppStrings.noUsers,
      icon: Icons.person_search_outlined,
    );
  }
}
