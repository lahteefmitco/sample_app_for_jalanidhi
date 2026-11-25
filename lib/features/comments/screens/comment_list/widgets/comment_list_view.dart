import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_empty_view.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/responsive_list_grid.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/widgets/comment_list_item.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';

/// Switches between loader, error, empty and the comment list/grid, and shows
/// the "Load more" button.
///
/// It is a separate widget so only this part of the page rebuilds when the
/// comments change; the search box above it stays untouched.
class CommentListView extends StatelessWidget {
  /// Creates the comment content area.
  const CommentListView({super.key});

  /// Builds the view that matches the current status.
  @override
  Widget build(BuildContext context) {
    // Used for callbacks only (retry, refresh, load more, tap); never
    // rebuilds this widget.
    final CommentListCubit cubit = context.read<CommentListCubit>();
    // Rebuilds whenever a new BuildState is emitted. `buildStateChanged`
    // skips rebuilds caused only by effects (bottom sheet, snackbar),
    // because those reuse the same BuildState.
    return BlocBuilder<CommentListCubit, CommentListState>(
      buildWhen: buildStateChanged,
      builder: (BuildContext context, CommentListState state) {
        // The part of the state this view renders.
        final CommentListBuildState build = state.build;
        switch (build.status) {
          // Nothing loaded yet: show a spinner.
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const CommonLoader();
          // Loading failed: show the message and a "Retry" button that
          // bypasses the cache.
          case ViewStatus.error:
            return CommonErrorWidget(
              message: build.errorMessage ?? '',
              onRetry: () => cubit.load(forceRefresh: true),
            );
          // No comment at all, or none matches the search.
          case ViewStatus.empty:
            return const CommonEmptyView(
              message: AppStrings.noComments,
              icon: Icons.comment_outlined,
            );
          // Comments are ready: pull down to refresh, list on phones and
          // grid on wider screens.
          case ViewStatus.loaded:
            return RefreshIndicator(
              onRefresh: () => cubit.load(forceRefresh: true),
              child: ResponsiveListGrid(
                itemCount: build.comments.length,
                tileHeight: 120,
                minTileWidth: 420,
                // "Load more (shown/total)" button under the last tile; hidden
                // (`null`) once every match is shown.
                footer: build.hasMore
                    ? OutlinedButton(
                        onPressed: cubit.loadMore,
                        child: Text(
                          '${AppStrings.loadMore} '
                          '(${build.comments.length}/${build.totalMatches})',
                        ),
                      )
                    : null,
                itemBuilder: (BuildContext context, int index) {
                  final CommentModel comment = build.comments[index];
                  // One tappable comment tile; a tap opens the full comment.
                  return CommentListItem(
                    comment: comment,
                    onTap: () => cubit.onCommentTapped(comment),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
