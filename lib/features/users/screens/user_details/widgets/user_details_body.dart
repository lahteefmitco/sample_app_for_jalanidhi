import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_state.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/widgets/user_info_card.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/widgets/user_posts_section.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// Loaded content of the user details page.
///
/// Single column on phones; info card beside the posts on wide layouts.
class UserDetailsBody extends StatelessWidget {
  /// Creates the body from the loaded [details].
  const UserDetailsBody({super.key, required this.details});

  /// The loaded state (user and posts) to show.
  final UserDetailsBuildState details;

  /// Builds a one- or two-column layout depending on the available width.
  @override
  Widget build(BuildContext context) {
    final UserModel? user = details.user;
    // Safety net: nothing to show without a user.
    if (user == null) return const SizedBox.shrink();
    // Built once here and placed in either layout below.
    final UserInfoCard info = UserInfoCard(user: user);
    final UserPostsSection posts = UserPostsSection(posts: details.posts);
    // Keeps the content from getting too wide on big screens.
    return MaxWidthContainer(
      // Gives us the real available width to choose the layout.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // 800 logical pixels or more: enough room for two columns.
          final bool wide = constraints.maxWidth >= 800;
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppDimensions.pagePadding),
            child: wide
                // Wide: info card (2/5 of the width) beside the posts (3/5).
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 2, child: info),
                      SizedBox(width: AppDimensions.gapLarge),
                      Expanded(flex: 3, child: posts),
                    ],
                  )
                // Narrow: info card above the posts.
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      info,
                      SizedBox(height: AppDimensions.gap),
                      posts,
                    ],
                  ),
          );
        },
      ),
    );
  }
}
