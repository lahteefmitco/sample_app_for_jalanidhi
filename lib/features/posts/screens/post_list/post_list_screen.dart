import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/widgets/post_author_filter.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/widgets/post_list_view.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/widgets/post_search_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Post list page.
///
/// Search + author filter on top, the paginated list/grid below ("Load more"
/// reveals the next page) and a floating button to create a post. Edit and
/// delete are in each item's menu; delete asks for confirmation first.
///
/// The [PostListCubit] is provided above this widget by the route.
class PostListScreen extends StatelessWidget {
  /// Creates the post list page.
  const PostListScreen({super.key});

  /// Builds the static page layout. The parts that change are separate
  /// widgets that each select their own piece of state.
  @override
  Widget build(BuildContext context) {
    // Listens to one-time effects of PostListCubit (snackbars, the delete
    // confirmation dialog, navigation). It does not rebuild anything itself.
    return ScreenEffectListener<PostListCubit, PostListBuildState>(
      screenName: 'PostListScreen',
      child: Scaffold(
        // Title bar.
        appBar: AppBar(title: const Text(AppStrings.posts)),
        // Opens the empty post form.
        floatingActionButton: BusyGuard<PostListCubit, PostListBuildState>(
          // Disabled while a request is running.
          child: FloatingActionButton.extended(
            onPressed: context.read<PostListCubit>().onCreatePressed,
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.newPost),
          ),
        ),
        body: BusyGuard<PostListCubit, PostListBuildState>(
          // Disabled while a request is running.
          child: Column(
            children: <Widget>[
              // Header: search box and author filter.
              MaxWidthContainer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding,
                    AppDimensions.gap,
                    AppDimensions.pagePadding,
                    0,
                  ),
                  // Search box takes the free width; filter button on the right.
                  child: const Row(
                    children: <Widget>[
                      Expanded(child: PostSearchField()),
                      PostAuthorFilter(),
                    ],
                  ),
                ),
              ),
              // Content: loader / error / empty / paginated posts.
              const Expanded(child: PostListView()),
            ],
          ),
        ),
      ),
    );
  }
}
