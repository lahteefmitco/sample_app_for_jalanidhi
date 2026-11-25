import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';

/// One comment tile: name, email/post, and a two-line body preview.
///
/// It is a plain widget (no Cubit access): the parent passes the comment and
/// what to do on tap, which keeps the tile easy to reuse and test.
class CommentListItem extends StatelessWidget {
  /// Creates a tile for [comment] that calls [onTap] when tapped.
  const CommentListItem({
    super.key,
    required this.comment,
    required this.onTap,
  });

  /// The comment to show.
  final CommentModel comment;

  /// Called when the user taps the tile (opens the full comment).
  final VoidCallback onTap;

  /// Builds the card with the three text lines.
  @override
  Widget build(BuildContext context) {
    // Theme colors, so the tile follows light/dark mode.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      // Clips the InkWell ripple to the card's rounded corners.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Comment name (its "subject"), one line.
              Text(
                comment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppDimensions.fontBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Author email and the post the comment belongs to.
              Text(
                '${comment.email} · post #${comment.postId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall,
                  color: colors.primary,
                ),
              ),
              SizedBox(height: AppDimensions.gapSmall / 2),
              // Body preview: line breaks become spaces so two lines show as
              // much text as possible.
              Text(
                comment.body.replaceAll('\n', ' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: AppDimensions.fontSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
