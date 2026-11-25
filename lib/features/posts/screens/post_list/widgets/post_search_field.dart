import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_state.dart';

/// Search box of the post list.
///
/// The text controller is owned by the Cubit (so the Cubit can clear it).
/// Only the clear button depends on state.
class PostSearchField extends StatelessWidget {
  /// Creates the search box.
  const PostSearchField({super.key});

  /// Builds the text field with a search icon and an optional clear button.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): used for the controller and callbacks.
    final PostListCubit cubit = context.read<PostListCubit>();
    // Rebuilds only when "is there any search text?" flips between true and
    // false, to show or hide the clear button. The TextField keeps its own
    // controller (owned by the cubit), so typing does not need a rebuild.
    return BlocSelector<PostListCubit, PostListState, bool>(
      selector: (PostListState state) => state.build.header.query.isNotEmpty,
      builder: (BuildContext context, bool hasQuery) {
        return TextField(
          controller: cubit.searchController,
          // Every keystroke goes to the Cubit, which filters the list.
          onChanged: cubit.onSearchChanged,
          decoration: InputDecoration(
            hintText: AppStrings.search,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            isDense: true,
            // Clear button, only when there is text to clear.
            suffixIcon: hasQuery
                ? IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: cubit.clearSearch,
                  )
                : null,
          ),
        );
      },
    );
  }
}
