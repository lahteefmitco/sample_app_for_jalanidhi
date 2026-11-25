import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';

/// "Comments (n)" heading and the list of comments of the post.
///
/// It does not scroll on its own because the whole page body already
/// scrolls (see `PostDetailsBody`).
class PostCommentsSection extends StatelessWidget {
  /// Creates the section for [comments].
  const PostCommentsSection({super.key, required this.comments});

  /// The comments of the post.
  final List<CommentModel> comments;

  /// Builds the heading, an empty message if needed, and one card per comment.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used when a comment is tapped.
    final PostDetailsCubit cubit = context.read<PostDetailsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section title, e.g. "Comments (5)".
        Text(
          '${AppStrings.comments} (${comments.length})',
          style: TextStyle(
            fontSize: AppDimensions.fontTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.gapSmall),
        // Message shown when the post has no comments.
        if (comments.isEmpty) const Text(AppStrings.noComments),
        // One card per comment: name, then email and body (max 3 lines).
        for (final CommentModel comment in comments)
          Card(
            margin: EdgeInsets.only(bottom: AppDimensions.gapSmall),
            child: ListTile(
              title: Text(
                comment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${comment.email}\n${comment.body}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              // Opens a bottom sheet with the full comment.
              onTap: () => cubit.onCommentTapped(comment),
            ),
          ),
      ],
    );
  }
}
