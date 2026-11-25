import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/models/todo_filter.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';

/// Cubit of the todo list: All/Pending/Completed filter, counters and the
/// optimistic "mark as completed" toggle.
///
/// It keeps its working data in private fields and turns them into a fresh,
/// immutable [TodoListBuildState] in [_render]. The details bottom sheet and
/// error snackbars are emitted as one-time effects.
class TodoListCubit extends ScreenCubit<TodoListBuildState> {
  /// Creates the Cubit in the `initial` status. The route in
  /// `app_routes.dart` calls [load] right after creating it.
  TodoListCubit({required this._todoRepository})
    : super(const TodoListBuildState(), name: 'TodoListCubit');

  /// Where the todos are fetched from and where toggles are saved.
  final TodoRepository _todoRepository;

  // Working data. The immutable build state is rebuilt from these fields.

  /// Every todo returned by the repository, before filtering. The counters
  /// are computed from this list.
  List<TodoModel> _all = const <TodoModel>[];

  /// The todos that match [_filter]; this is what the list shows.
  List<TodoModel> _visible = const <TodoModel>[];

  /// The selected filter segment (All / Pending / Completed).
  TodoFilter _filter = TodoFilter.all;

  /// Current content status (loading, loaded, empty, error ...).
  ViewStatus _status = ViewStatus.initial;

  /// User-friendly error text, set only when [_status] is `error`.
  String? _errorMessage;

  /// Copies the working fields into a new [TodoListBuildState] and emits it,
  /// so the BlocBuilders of the filter bar and the list can rebuild.
  ///
  /// The counters are computed from [_all], so they ignore the filter. The
  /// list is copied as unmodifiable so widgets cannot change it by accident.
  void _render() {
    emitBuild(
      TodoListBuildState(
        status: _status,
        filter: _filter,
        todos: List<TodoModel>.unmodifiable(_visible),
        totalCount: _all.length,
        completedCount: _all.where((TodoModel todo) => todo.completed).length,
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads the todos.
  ///
  /// Triggered by the route when the screen opens, and with
  /// [forceRefresh] = `true` by pull-to-refresh and the "Retry" button (so the
  /// repository skips its cache). Emits `loading`, then `loaded`/`empty`, or
  /// `error` plus an error snackbar on failure.
  ///
  /// The request uses a `'load'` token: starting another load, or closing
  /// the screen, cancels it. A cancelled request is ignored silently.
  Future<void> load({bool forceRefresh = false}) async {
    // Cancels any earlier load that is still running.
    final RequestToken token = startBlockingRequest('load');
    _status = ViewStatus.loading;
    _errorMessage = null;
    _render();
    try {
      _all = await _todoRepository.getTodos(
        forceRefresh: forceRefresh,
        requestToken: token,
      );
      // Applies the selected filter and emits the result.
      _applyFilter();
    } on Object catch (error) {
      if (isCancellation(error)) {
        return; // the screen was closed or a newer load started
      }
      _status = ViewStatus.error;
      _errorMessage = ErrorHandler.messageFor(error);
      _render();
      showErrorMessage(_errorMessage!);
    } finally {
      // Un-block the screen (ignored if a newer load took over).
      endBlockingRequest(token);
    }
  }

  /// Switches the visible todos to [filter].
  ///
  /// Triggered when the user picks a segment in `TodoFilterBar`. Emits a new
  /// build state with the matching todos (or `empty`).
  void onFilterChanged(TodoFilter filter) {
    _filter = filter;
    _applyFilter();
  }

  /// Optimistic update: the UI changes at once and is rolled back on failure.
  ///
  /// Triggered by the checkbox of a `TodoListItem`. Emits a build state with
  /// the flipped todo right away; if saving fails, emits the old list again
  /// plus an error snackbar.
  ///
  /// This is a write, so it deliberately uses no request token: the server
  /// may already have applied it, and it must finish even if the user leaves.
  Future<void> onToggle(TodoModel todo) async {
    // A request is already running: ignore a second tap / Enter key press.
    if (isBusy) {
      return;
    }
    // The new value of the checkbox.
    final bool completed = !todo.completed;
    // Kept so the change can be undone if the request fails.
    final List<TodoModel> previous = _all;
    // A new list where only the toggled todo is replaced by an updated copy.
    _all = <TodoModel>[
      for (final TodoModel item in _all)
        if (item.id == todo.id)
          TodoModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            completed: completed,
          )
        else
          item,
    ];
    _applyFilter();
    // PATCH request: show the square loader and lock the screen until done.
    showProgress();
    try {
      await _todoRepository.setCompleted(todo.id, completed: completed);
      hideProgress();
    } on Object catch (error) {
      // Roll back to the list from before the toggle.
      _all = previous;
      _applyFilter();
      hideProgress();
      showError(error);
    }
  }

  /// Opens a bottom sheet with the todo details.
  ///
  /// Triggered when the user taps a `TodoListItem` (outside its checkbox).
  /// Emits a [ShowInfoSheetEffect]; the build state does not change.
  void onTodoTapped(TodoModel todo) {
    emitEffect(
      ShowInfoSheetEffect(
        title: 'Todo #${todo.id}',
        // One label/value row per detail shown in the sheet.
        fields: <MapEntry<String, String>>[
          MapEntry<String, String>('Title', todo.title),
          MapEntry<String, String>('User', '#${todo.userId}'),
          MapEntry<String, String>(
            'Status',
            todo.completed ? 'Completed' : 'Pending',
          ),
        ],
      ),
    );
  }

  /// Rebuilds [_visible] from [_all] and [_filter], updates the status and
  /// emits the new build state.
  void _applyFilter() {
    _visible = _all.where(_filter.matches).toList(growable: false);
    _status = _visible.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    _errorMessage = null;
    _render();
  }
}
