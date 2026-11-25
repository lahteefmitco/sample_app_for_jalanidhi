import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/models/todo_filter.dart';

/// All / Pending / Completed selector with live counts.
///
/// It has its own BlocBuilder so it only rebuilds when the filter or a
/// counter changes, not on every change of the list.
class TodoFilterBar extends StatelessWidget {
  /// Creates the filter bar.
  const TodoFilterBar({super.key});

  /// Builds a [SegmentedButton] with one segment per [TodoFilter].
  @override
  Widget build(BuildContext context) {
    // Used only to report the selected segment; never rebuilds this widget.
    final TodoListCubit cubit = context.read<TodoListCubit>();
    // Rebuilds only when something the bar shows changed: the selected
    // filter or one of the counters. A new list with the same counts (e.g.
    // after a refresh) does not rebuild the bar.
    return BlocBuilder<TodoListCubit, TodoListState>(
      buildWhen: (TodoListState previous, TodoListState current) =>
          previous.build.filter != current.build.filter ||
          previous.build.totalCount != current.build.totalCount ||
          previous.build.completedCount != current.build.completedCount,
      builder: (BuildContext context, TodoListState state) {
        // The part of the state this bar renders.
        final TodoListBuildState build = state.build;

        /// Segment text for [filter], e.g. `Pending (12)`.
        String label(TodoFilter filter) {
          // The counter that belongs to this segment.
          final int count = switch (filter) {
            TodoFilter.all => build.totalCount,
            TodoFilter.pending => build.pendingCount,
            TodoFilter.completed => build.completedCount,
          };
          return '${filter.label} ($count)';
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.pagePadding,
            AppDimensions.gap,
            AppDimensions.pagePadding,
            0,
          ),
          // Three-segment selector; exactly one segment is selected.
          child: SegmentedButton<TodoFilter>(
            segments: <ButtonSegment<TodoFilter>>[
              for (final TodoFilter filter in TodoFilter.values)
                ButtonSegment<TodoFilter>(
                  value: filter,
                  label: Text(label(filter)),
                ),
            ],
            selected: <TodoFilter>{build.filter},
            // No check mark: the highlighted segment is enough.
            showSelectedIcon: false,
            // Single selection, so the set always holds exactly one filter.
            onSelectionChanged: (Set<TodoFilter> selection) =>
                cubit.onFilterChanged(selection.first),
          ),
        );
      },
    );
  }
}
