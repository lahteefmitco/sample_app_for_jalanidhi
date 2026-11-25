import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/models/todo_filter.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/sample_data.dart';

/// Unit tests for [TodoListCubit]: loading with counters, filtering, and
/// toggling a todo (including rolling back when the request fails).
void main() {
  /// Fake JSONPlaceholder server; also counts the requests it receives.
  late FakeBackend backend;

  /// The [TodoListCubit] under test.
  late TodoListCubit cubit;
  // When true, the fake `PATCH /todos/1` request fails with a network error.
  bool failPatch = false;

  setUp(() {
    failPatch = false;
    backend = FakeBackend(<String, RouteHandler>{
      'GET /todos': (RequestOptions _) => todosJson,
      'PATCH /todos/1': (RequestOptions options) {
        if (failPatch) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return <String, int>{'id': 1};
      },
    });
    cubit = TodoListCubit(
      todoRepository: TodoRepository(backend.createClient()),
    );
  });

  tearDown(() => cubit.close());

  test('loads all todos with counters', () async {
    await cubit.load();
    final TodoListBuildState build = cubit.state.build;
    expect(build.status, ViewStatus.loaded);
    expect(build.todos, hasLength(5));
    expect(build.completedCount, 2);
    expect(build.pendingCount, 3);
  });

  test('filters completed and pending todos', () async {
    await cubit.load();
    cubit.onFilterChanged(TodoFilter.completed);
    expect(cubit.state.build.todos.every((TodoModel t) => t.completed), isTrue);
    expect(cubit.state.build.todos, hasLength(2));
    cubit.onFilterChanged(TodoFilter.pending);
    expect(
      cubit.state.build.todos.every((TodoModel t) => !t.completed),
      isTrue,
    );
    expect(cubit.state.build.todos, hasLength(3));
  });

  test(
    'toggling updates counts and moves the item out of the filter',
    () async {
      // Arrange: show only pending todos; todo 1 is pending.
      await cubit.load();
      cubit.onFilterChanged(TodoFilter.pending);
      // Act: mark todo 1 as completed.
      await cubit.onToggle(
        cubit.state.build.todos.firstWhere((TodoModel t) => t.id == 1),
      );
      // Assert: it is now completed, so it left the "pending" list.
      expect(cubit.state.build.completedCount, 3);
      expect(cubit.state.build.todos.any((TodoModel t) => t.id == 1), isFalse);
      expect(backend.count('PATCH /todos/1'), 1);
    },
  );

  test('a failed toggle is rolled back and reported', () async {
    failPatch = true;
    await cubit.load();
    await cubit.onToggle(
      cubit.state.build.todos.firstWhere((TodoModel t) => t.id == 1),
    );
    // The counters and the todo are back to how they were before.
    expect(cubit.state.build.completedCount, 2);
    expect(
      cubit.state.build.todos.firstWhere((TodoModel t) => t.id == 1).completed,
      isFalse,
    );
    expect((cubit.state.effect as ShowSnackbarEffect).type, SnackbarType.error);
  });
}
