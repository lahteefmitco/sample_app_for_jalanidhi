import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/models/todo_filter.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';

/// What the todo list renders: status, filter, visible todos and counters.
///
/// Immutable: the Cubit creates a new instance for every change, which is
/// how the BlocBuilders know they may need to rebuild.
@immutable
class TodoListBuildState {
  /// Creates a build state. The defaults describe the screen before anything
  /// was loaded.
  const TodoListBuildState({
    this.status = ViewStatus.initial,
    this.filter = TodoFilter.all,
    this.todos = const <TodoModel>[],
    this.totalCount = 0,
    this.completedCount = 0,
    this.errorMessage,
  });

  /// Which view to show: loader, error, empty or the list.
  final ViewStatus status;

  /// The selected filter segment.
  final TodoFilter filter;

  /// The todos that match [filter], in display order.
  final List<TodoModel> todos;

  /// Number of all todos, whatever the filter (shown on the "All" segment).
  final int totalCount;

  /// Number of completed todos, whatever the filter (shown on the
  /// "Completed" segment).
  final int completedCount;

  /// Text shown by the error view; `null` unless [status] is `error`.
  final String? errorMessage;

  /// Number of todos not completed yet (shown on the "Pending" segment).
  /// Derived from the two counters, so it can never be out of sync.
  int get pendingCount => totalCount - completedCount;

  /// Short description for logs (prints only the todo count).
  @override
  String toString() =>
      'TodoListBuildState(status: $status, filter: $filter, '
      'todos: ${todos.length}, totalCount: $totalCount, '
      'completedCount: $completedCount, errorMessage: $errorMessage)';
}

/// Full state of the todo list screen: the [TodoListBuildState] plus the
/// one-time effect handled by `ScreenEffectListener`.
typedef TodoListState = ScreenState<TodoListBuildState>;
