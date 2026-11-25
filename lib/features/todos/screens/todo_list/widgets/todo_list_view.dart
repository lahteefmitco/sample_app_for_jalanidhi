import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_empty_view.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/responsive_list_grid.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/widgets/todo_list_item.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';

/// Switches between loader, error, empty and the list of todos.
///
/// It is a separate widget so only this part of the page rebuilds when the
/// todos change; the filter bar above it has its own builder.
class TodoListView extends StatelessWidget {
  /// Creates the todo content area.
  const TodoListView({super.key});

  /// Builds the view that matches the current status.
  @override
  Widget build(BuildContext context) {
    // Used for callbacks only (retry, refresh, toggle, tap); never rebuilds
    // this widget.
    final TodoListCubit cubit = context.read<TodoListCubit>();
    // Rebuilds whenever a new BuildState is emitted. `buildStateChanged`
    // skips rebuilds caused only by effects (bottom sheet, snackbar),
    // because those reuse the same BuildState.
    return BlocBuilder<TodoListCubit, TodoListState>(
      buildWhen: buildStateChanged,
      builder: (BuildContext context, TodoListState state) {
        // The part of the state this view renders.
        final TodoListBuildState build = state.build;
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
          // No todo at all, or none matches the selected filter.
          case ViewStatus.empty:
            return const CommonEmptyView(
              message: AppStrings.noTodos,
              icon: Icons.checklist_outlined,
            );
          // Todos are ready: pull down to refresh, list on phones and grid
          // on wider screens.
          case ViewStatus.loaded:
            return RefreshIndicator(
              onRefresh: () => cubit.load(forceRefresh: true),
              child: ResponsiveListGrid(
                itemCount: build.todos.length,
                tileHeight: 80,
                minTileWidth: 420,
                itemBuilder: (BuildContext context, int index) {
                  final TodoModel todo = build.todos[index];
                  // One todo tile: the checkbox toggles it, a tap elsewhere
                  // opens its details.
                  return TodoListItem(
                    todo: todo,
                    onToggle: () => cubit.onToggle(todo),
                    onTap: () => cubit.onTodoTapped(todo),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
