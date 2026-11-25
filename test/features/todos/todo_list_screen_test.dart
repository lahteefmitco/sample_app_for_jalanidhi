import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/todo_list_screen.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sample_data.dart';

/// Widget tests for [TodoListScreen]: the list with its filter counters,
/// filtering, ticking a checkbox and opening a todo's details sheet.
void main() {
  // Re-created by `pumpTodos`, so each test can count its own requests.
  /// Fake JSONPlaceholder server; also counts the requests it receives.
  late FakeBackend backend;

  /// Shows [TodoListScreen] backed by the sample todos and waits for it.
  Future<void> pumpTodos(WidgetTester tester) async {
    backend = FakeBackend(<String, RouteHandler>{
      'GET /todos': (RequestOptions _) => todosJson,
      'PATCH /todos/1': (RequestOptions _) => <String, int>{'id': 1},
    });
    await pumpApp(
      tester,
      // Provides the TodoListCubit that TodoListScreen reads from the
      // context; `..load()` starts fetching the todos right away.
      BlocProvider<TodoListCubit>(
        create: (BuildContext _) => TodoListCubit(
          todoRepository: TodoRepository(backend.createClient()),
        )..load(),
        child: const TodoListScreen(),
      ),
      size: const Size(500, 900),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every todo with counters on the filter bar', (
    WidgetTester tester,
  ) async {
    await pumpTodos(tester);
    for (int i = 1; i <= 5; i++) {
      expect(find.text('Todo $i'), findsOneWidget);
    }
    expect(find.text('${AppStrings.all} (5)'), findsOneWidget);
    expect(find.text('${AppStrings.pending} (3)'), findsOneWidget);
    expect(find.text('${AppStrings.completed} (2)'), findsOneWidget);
  });

  testWidgets('the Completed filter hides pending todos', (
    WidgetTester tester,
  ) async {
    await pumpTodos(tester);
    await tester.tap(find.text('${AppStrings.completed} (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Todo 2'), findsOneWidget);
    expect(find.text('Todo 4'), findsOneWidget);
    expect(find.text('Todo 1'), findsNothing);
  });

  testWidgets('ticking a checkbox updates the counters and calls the API', (
    WidgetTester tester,
  ) async {
    await pumpTodos(tester);
    await tester.tap(find.byType(Checkbox).first); // Todo 1 (pending)
    await tester.pumpAndSettle();
    expect(backend.count('PATCH /todos/1'), 1);
    expect(find.text('${AppStrings.completed} (3)'), findsOneWidget);
    expect(find.text('${AppStrings.pending} (2)'), findsOneWidget);
  });

  testWidgets('tapping a todo opens its details sheet', (
    WidgetTester tester,
  ) async {
    await pumpTodos(tester);
    await tester.tap(find.text('Todo 3'));
    await tester.pumpAndSettle();
    expect(find.text('Todo #3'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
  });
}
