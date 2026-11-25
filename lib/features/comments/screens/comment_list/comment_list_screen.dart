import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/widgets/comment_list_view.dart';

/// Comment list page with search and "Load more" pagination.
///
/// Tapping a comment opens a bottom sheet with the full text.
///
/// The [CommentListCubit] is created and provided by the route in
/// `app_routes.dart` (which also calls `load()`), so this widget only reads it.
class CommentListScreen extends StatelessWidget {
  /// Creates the comment list screen.
  const CommentListScreen({super.key});

  /// Builds the app bar, the search box and the comment content below it.
  @override
  Widget build(BuildContext context) {
    // `read` (not `watch`): this widget only needs the search controller and
    // callbacks; the content rebuilds inside CommentListView.
    final CommentListCubit cubit = context.read<CommentListCubit>();
    // Listens to the Cubit's one-time effects: opens the comment bottom
    // sheet and shows the error snackbar when loading fails.
    return ScreenEffectListener<CommentListCubit, CommentListBuildState>(
      screenName: 'CommentListScreen',
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.comments)),
        body: BusyGuard<CommentListCubit, CommentListBuildState>(
          // Disabled while a request is running.
          child: Column(
            children: <Widget>[
              // Search box (controller owned by the Cubit, so the typed text
              // survives rebuilds).
              MaxWidthContainer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding,
                    AppDimensions.gap,
                    AppDimensions.pagePadding,
                    0,
                  ),
                  child: TextField(
                    controller: cubit.searchController,
                    onChanged: cubit.onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: AppStrings.search,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              // Content: loader / error / empty / paginated comments. Expanded
              // gives it all the height left under the search box.
              const Expanded(child: CommentListView()),
            ],
          ),
        ),
      ),
    );
  }
}
