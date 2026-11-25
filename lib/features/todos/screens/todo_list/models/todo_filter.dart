import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';

/// The three segments of the todo filter bar.
///
/// Each value knows its label and which todos it lets through ([matches]),
/// so the Cubit and the filter bar need no `switch` of their own for that.
enum TodoFilter {
  /// Shows every todo.
  all(AppStrings.all),

  /// Shows only the todos that are not completed yet.
  pending(AppStrings.pending),

  /// Shows only the completed todos.
  completed(AppStrings.completed);

  /// Creates a filter value with its segment [label].
  const TodoFilter(this.label);

  /// Text of the segment (without the count).
  final String label;

  /// `true` when [todo] should be visible with this filter selected.
  ///
  /// Used with `where` in `TodoListCubit._applyFilter`.
  bool matches(TodoModel todo) {
    switch (this) {
      case TodoFilter.all:
        return true;
      case TodoFilter.pending:
        return !todo.completed;
      case TodoFilter.completed:
        return todo.completed;
    }
  }
}
