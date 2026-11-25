import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_state.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/widgets/post_comments_section.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/widgets/post_content_card.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';

/// Loaded content of the post details page.
///
/// Post above the comments on phones, side by side on wide layouts.
class PostDetailsBody extends StatelessWidget {
  /// Creates the body from the loaded [details].
  const PostDetailsBody({super.key, required this.details});

  /// The loaded state (post, author and comments) to show.
  final PostDetailsBuildState details;

  /// Builds a one- or two-column layout depending on the available width.
  @override
  Widget build(BuildContext context) {
    final PostModel? post = details.post;
    // Safety net: nothing to show without a post.
    if (post == null) return const SizedBox.shrink();
    // Built once here and placed in either layout below.
    final PostContentCard content = PostContentCard(
      post: post,
      author: details.author,
    );
    final PostCommentsSection comments = PostCommentsSection(
      comments: details.comments,
    );
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
                // Wide: post card (2/5 of the width) beside comments (3/5).
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 2, child: content),
                      SizedBox(width: AppDimensions.gapLarge),
                      Expanded(flex: 3, child: comments),
                    ],
                  )
                // Narrow: post card above the comments.
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      content,
                      SizedBox(height: AppDimensions.gap),
                      comments,
                    ],
                  ),
          );
        },
      ),
    );
  }
}
