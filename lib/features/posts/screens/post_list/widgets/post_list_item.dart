import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';

/// One post tile: title, body preview, author and an edit/delete menu.
///
/// It has no state of its own: the parent passes the data and what to do
/// for each action.
class PostListItem extends StatelessWidget {
  /// Creates a tile for [post] written by [authorName].
  const PostListItem({
    super.key,
    required this.post,
    required this.authorName,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  /// The post shown in this tile.
  final PostModel post;

  /// Name of the post's author, shown on the last line.
  final String authorName;

  /// Called when the tile is tapped (opens the post details page).
  final VoidCallback onTap;

  /// Called when "Edit" is chosen in the menu (opens the post form).
  final VoidCallback onEdit;

  /// Called when "Delete" is chosen in the menu (asks for confirmation).
  final VoidCallback onDelete;

  /// Builds the card with the three text lines and the "more" menu.
  @override
  Widget build(BuildContext context) {
    // Theme colours, used for the author name.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      // Makes the whole card tappable with a ripple effect.
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // No right padding: the menu button has its own padding.
          padding: EdgeInsets.only(
            left: AppDimensions.gap,
            top: AppDimensions.gapSmall,
            bottom: AppDimensions.gapSmall,
          ),
          child: Row(
            children: <Widget>[
              // Text lines take all the width left of the menu button.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Title in bold, at most two lines.
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppDimensions.fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDimensions.gapSmall / 2),
                    // Body preview; line breaks become spaces so the two
                    // lines are filled with text.
                    Text(
                      post.body.replaceAll('\n', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: AppDimensions.fontSmall),
                    ),
                    SizedBox(height: AppDimensions.gapSmall / 2),
                    // Author name in the primary colour.
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSmall,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // "More" menu with Edit and Delete.
              PopupMenuButton<String>(
                tooltip: 'More',
                // Anything that is not 'edit' is 'delete'.
                onSelected: (String value) =>
                    value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text(AppStrings.edit),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(AppStrings.delete),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
