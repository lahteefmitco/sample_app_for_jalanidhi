import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_empty_view.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/responsive_list_grid.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/widgets/post_list_item.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';

/// Renders the content group of the post list state.
///
/// Switches between loader, error, empty and the post list/grid, and shows
/// the "Load more" button while more matching posts exist.
class PostListView extends StatelessWidget {
  /// Creates the list area of the post list page.
  const PostListView({super.key});

  /// Builds the view that matches the current loading status.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used to call methods on taps/refresh.
    final PostListCubit cubit = context.read<PostListCubit>();
    // Rebuilds only when the content group changes. The header group (search
    // text, author) is ignored here, so the list does not rebuild for
    // header-only changes.
    return BlocSelector<PostListCubit, PostListState, PostListContentState>(
      selector: (PostListState state) => state.build.content,
      builder: (BuildContext context, PostListContentState content) {
        switch (content.status) {
          // Nothing loaded yet or a load is running: show a spinner.
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const CommonLoader();
          // Load failed: show the message and a retry button.
          case ViewStatus.error:
            return CommonErrorWidget(
              message: content.errorMessage ?? '',
              onRetry: () => cubit.load(forceRefresh: true),
            );
          // Loaded, but no post matches the search/filter.
          case ViewStatus.empty:
            return const CommonEmptyView(
              message: AppStrings.noPosts,
              icon: Icons.article_outlined,
            );
          // Loaded: show the posts; pull down to reload from the server.
          case ViewStatus.loaded:
            return RefreshIndicator(
              onRefresh: () => cubit.load(forceRefresh: true),
              // List on phones, grid on wider screens.
              child: ResponsiveListGrid(
                itemCount: content.posts.length,
                tileHeight: 136,
                minTileWidth: 420,
                // "Load more (shown/total)" button below the last tile, only
                // while there are hidden matches left.
                footer: content.hasMore
                    ? OutlinedButton(
                        onPressed: cubit.loadMore,
                        child: Text(
                          '${AppStrings.loadMore} '
                          '(${content.posts.length}/${content.totalMatches})',
                        ),
                      )
                    : null,
                itemBuilder: (BuildContext context, int index) {
                  final PostModel post = content.posts[index];
                  // One tile per post; falls back to "User <id>" when the
                  // author is unknown.
                  return PostListItem(
                    post: post,
                    authorName:
                        content.authors[post.userId] ?? 'User ${post.userId}',
                    onTap: () => cubit.onPostTapped(post),
                    onEdit: () => cubit.onEditPressed(post),
                    onDelete: () => cubit.onDeletePressed(post),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
