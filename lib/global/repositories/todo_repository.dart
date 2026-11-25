import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/json_parsers.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';

/// Reads todos and changes their "completed" flag.
///
/// Shared by the home dashboard and the todo list. Like posts, changes are
/// only simulated by JSONPlaceholder, so they are kept in a memory-only
/// overlay for the current session.
class TodoRepository {
  /// Creates the repository on top of the shared [ApiClient].
  TodoRepository(this._api);

  /// HTTP client used for every request.
  final ApiClient _api;

  /// Todos loaded by [getTodos]; `null` until the first successful load.
  List<TodoModel>? _remote;

  /// "completed" values changed by the user in this session, keyed by id.
  final Map<int, bool> _completedOverrides = <int, bool>{};

  /// Returns every todo (`GET /todos`) with the session changes applied.
  Future<List<TodoModel>> getTodos({
    bool forceRefresh = false,
    RequestToken? requestToken,
  }) async {
    List<TodoModel>? remote = _remote;
    if (forceRefresh || remote == null) {
      repositoryLog(
        'getTodos: fetching',
        funtionName: 'TodoRepository.getTodos',
      );
      final ApiResponse<List<TodoModel>> response = await _api
          .get<List<TodoModel>>(
            ApiEndpoints.todos,
            parser: (Object? json) =>
                parseList<TodoModel>(json, TodoModel.fromJson),
            requestToken: requestToken,
          );
      remote = response.data;
      _remote = remote;
    }

    final List<TodoModel> result = <TodoModel>[];
    for (final TodoModel todo in remote) {
      // The user's own "completed" value, or null if never changed.
      final bool? override = _completedOverrides[todo.id];
      if (override == null) {
        result.add(todo);
      } else {
        result.add(
          TodoModel(
            id: todo.id,
            userId: todo.userId,
            title: todo.title,
            completed: override,
          ),
        );
      }
    }
    return List<TodoModel>.unmodifiable(result);
  }

  /// Marks the todo [id] as completed or pending (`PATCH /todos/{id}`).
  ///
  /// Not cancellable: it is a write the user expects to finish.
  Future<void> setCompleted(int id, {required bool completed}) async {
    await _api.patch<Object?>(
      ApiEndpoints.todo(id),
      data: <String, bool>{'completed': completed},
      parser: (Object? json) => json,
    );
    _completedOverrides[id] = completed;
    repositoryLog(
      'setCompleted($id, $completed) (local only)',
      funtionName: 'TodoRepository.setCompleted',
    );
  }
}
