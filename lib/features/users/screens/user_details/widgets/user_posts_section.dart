import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';

/// Header plus the (non-scrolling) list of the user's posts.
///
/// It does not scroll on its own because the whole page body already
/// scrolls (see `UserDetailsBody`).
class UserPostsSection extends StatelessWidget {
  /// Creates the section for [posts].
  const UserPostsSection({super.key, required this.posts});

  /// The posts written by the user.
  final List<PostModel> posts;

  /// Builds the title with the post count and one card per post.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used when a post is tapped.
    final UserDetailsCubit cubit = context.read<UserDetailsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section title, e.g. "Posts (10)".
        Text(
          '${AppStrings.userPosts} (${posts.length})',
          style: TextStyle(
            fontSize: AppDimensions.fontTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.gapSmall),
        // One card per post: title and a two-line preview of the body.
        for (final PostModel post in posts)
          Card(
            margin: EdgeInsets.only(bottom: AppDimensions.gapSmall),
            child: ListTile(
              title: Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Opens the post details page.
              onTap: () => cubit.onPostTapped(post),
            ),
          ),
      ],
    );
  }
}
