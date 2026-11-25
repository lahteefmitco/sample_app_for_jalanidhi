import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// Card with the post title, author line and body text.
class PostContentCard extends StatelessWidget {
  /// Creates the card for [post]; [author] is optional.
  const PostContentCard({super.key, required this.post, this.author});

  /// The post to show.
  final PostModel post;

  /// Who wrote the post; when `null` the "by …" line is hidden.
  final UserModel? author;

  /// Builds the title, the optional author line and the full body.
  @override
  Widget build(BuildContext context) {
    // Theme colours, used for the author line.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Title in bold.
            Text(
              post.title,
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppDimensions.gapSmall),
            // "by Name (email)", only when the author is known.
            if (author != null)
              Text(
                'by ${author!.name} (${author!.email})',
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall,
                  color: colors.primary,
                ),
              ),
            SizedBox(height: AppDimensions.gap),
            // Full post body (not shortened).
            Text(post.body, style: TextStyle(fontSize: AppDimensions.fontBody)),
          ],
        ),
      ),
    );
  }
}
