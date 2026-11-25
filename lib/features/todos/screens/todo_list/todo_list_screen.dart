import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/widgets/todo_filter_bar.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/widgets/todo_list_view.dart';

/// Todo list page: All / Pending / Completed filter and a checkbox per item.
///
/// Toggling a checkbox updates the UI immediately (optimistic update) and
/// is rolled back by the Cubit if the request fails.
///
/// The [TodoListCubit] is created and provided by the route in
/// `app_routes.dart` (which also calls `load()`); the child widgets read it.
class TodoListScreen extends StatelessWidget {
  /// Creates the todo list screen.
  const TodoListScreen({super.key});

  /// Builds the app bar, the filter bar and the todo content below it.
  @override
  Widget build(BuildContext context) {
    // Listens to the Cubit's one-time effects: opens the todo bottom sheet
    // and shows error snackbars (failed load or failed toggle).
    return ScreenEffectListener<TodoListCubit, TodoListBuildState>(
      screenName: 'TodoListScreen',
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.todos)),
        // `const`: neither child needs anything from here; each one reads
        // the Cubit itself and rebuilds on its own.
        body: BusyGuard<TodoListCubit, TodoListBuildState>(
          // Disabled while a request is running.
          child: const Column(
            children: <Widget>[
              // All / Pending / Completed selector with counts.
              MaxWidthContainer(child: TodoFilterBar()),
              // The (filtered) todos, using all the remaining height.
              Expanded(child: TodoListView()),
            ],
          ),
        ),
      ),
    );
  }
}
