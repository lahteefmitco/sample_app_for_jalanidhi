import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// Popup menu that filters the post list by author.
///
/// The icon changes when a filter is active, so the user can see that the
/// list is filtered.
class PostAuthorFilter extends StatelessWidget {
  /// Creates the author filter button.
  const PostAuthorFilter({super.key});

  /// Builds the filter icon button and its menu of authors.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used to report the chosen author.
    final PostListCubit cubit = context.read<PostListCubit>();
    // Rebuilds when the header group changes: it needs both the list of
    // users (menu entries) and the selected author (icon). The list of posts
    // (content group) is ignored.
    return BlocSelector<PostListCubit, PostListState, PostListHeaderState>(
      selector: (PostListState state) => state.build.header,
      builder: (BuildContext context, PostListHeaderState header) {
        // `int?` because the "All authors" entry has the value `null`.
        return PopupMenuButton<int?>(
          tooltip: AppStrings.author,
          // Filled filter icon while an author is selected.
          icon: Icon(
            header.selectedUserId == null
                ? Icons.filter_list
                : Icons.filter_list_alt,
          ),
          onSelected: cubit.onAuthorChanged,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int?>>[
            // First entry removes the filter.
            const PopupMenuItem<int?>(
              value: null,
              child: Text(AppStrings.allAuthors),
            ),
            // One entry per user.
            for (final UserModel user in header.users)
              PopupMenuItem<int?>(value: user.id, child: Text(user.name)),
          ],
        );
      },
    );
  }
}
