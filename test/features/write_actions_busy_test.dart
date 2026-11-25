import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/progress_dialog.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/square_loader.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/post_form_screen.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/todo_list_screen.dart';
import 'package:sample_app_for_jalanidhi/global/models/auth_user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../helpers/fake_backend.dart';
import '../helpers/in_memory_storage.dart';
import '../helpers/pump_app.dart';
import '../helpers/sample_data.dart';

/// A slow server: long enough to press a button again while a write runs.
const Duration _slow = Duration(milliseconds: 200);

/// Checks that while a POST / PUT / PATCH / DELETE request is running, the
/// screen is locked and a second tap cannot send the request twice.
void main() {
  late FakeBackend backend;

  /// Backend with every route the write tests need, answering slowly.
  FakeBackend slowBackend() {
    return FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => usersJson,
      'GET /posts': (RequestOptions _) => postsJson,
      'GET /posts/2': (RequestOptions _) => postsJson[1],
      'GET /users/2': (RequestOptions _) => usersJson[1],
      'GET /comments': (RequestOptions _) => commentsJson,
      'GET /todos': (RequestOptions _) => todosJson,
      'POST /posts': (RequestOptions _) => <String, int>{'id': 101},
      'PUT /posts/2': (RequestOptions _) => postsJson[1],
      'DELETE /posts/2': (RequestOptions _) => <String, dynamic>{},
      'PATCH /todos/1': (RequestOptions _) => <String, int>{'id': 1},
      'PATCH /todos/3': (RequestOptions _) => <String, int>{'id': 3},
    }, latency: _slow);
  }

  setUp(() {
    ProgressDialog.hide();
    backend = slowBackend();
  });

  // ---------------------------------------------------------------------------
  // Cubit level: the second call is ignored
  // ---------------------------------------------------------------------------
  group('write actions ignore a second call while busy', () {
    test('login: two quick submits call the repository once', () async {
      int calls = 0;
      final InMemoryLocalStorage preferences = InMemoryLocalStorage();
      final _CountingAuth auth = _CountingAuth(() => calls++);
      final LoginCubit cubit = LoginCubit(
        authRepository: auth,
        preferences: preferences,
      );
      cubit.emailController.text = 'a@b.co';
      cubit.passwordController.text = 'secret';

      final Future<void> first = cubit.submit();
      expect(cubit.isBusy, isTrue); // the progress effect locked the screen
      final Future<void> second = cubit.submit(); // ignored
      await Future.wait(<Future<void>>[first, second]);

      expect(calls, 1);
      expect(cubit.isBusy, isFalse); // unlocked again afterwards
      await cubit.close();
    });

    test('post form: two quick saves send one POST', () async {
      final PostFormCubit cubit = _postFormCubit(backend);
      await cubit.load();
      cubit.titleController.text = 'Title';
      cubit.bodyController.text = 'Body';

      final Future<void> first = cubit.submit();
      final Future<void> second = cubit.submit(); // ignored
      await Future.wait(<Future<void>>[first, second]);

      expect(backend.count('POST /posts'), 1);
      await cubit.close();
    });

    test('post details: confirming delete twice sends one DELETE', () async {
      final PostDetailsCubit cubit = _postDetailsCubit(backend);
      await cubit.load();

      cubit.onConfirmed('delete');
      cubit.onConfirmed('delete'); // ignored: the first one is running
      await Future<void>.delayed(_slow * 2);

      expect(backend.count('DELETE /posts/2'), 1);
      await cubit.close();
    });

    test('post list: confirming delete twice sends one DELETE', () async {
      final PostListCubit cubit = PostListCubit(
        postRepository: PostRepository(backend.createClient()),
        userRepository: UserRepository(backend.createClient()),
      );
      await cubit.load();

      cubit.onConfirmed('delete:2');
      cubit.onConfirmed('delete:2');
      await Future<void>.delayed(_slow * 2);

      expect(backend.count('DELETE /posts/2'), 1);
      await cubit.close();
    });

    test('todo: a second toggle during the PATCH is ignored', () async {
      final TodoListCubit cubit = TodoListCubit(
        todoRepository: TodoRepository(backend.createClient()),
      );
      await cubit.load();

      final Future<void> first = cubit.onToggle(cubit.state.build.todos[0]);
      final Future<void> second = cubit.onToggle(cubit.state.build.todos[2]);
      await Future.wait(<Future<void>>[first, second]);

      expect(backend.count('PATCH /todos/1'), 1);
      expect(backend.count('PATCH /todos/3'), 0);
      await cubit.close();
    });

    test('the todo toggle shows and hides the progress loader', () async {
      final TodoListCubit cubit = TodoListCubit(
        todoRepository: TodoRepository(backend.createClient()),
      );
      await cubit.load();
      final List<UiEffect> effects = <UiEffect>[];
      cubit.stream.listen((ScreenState<TodoListBuildState> state) {
        if (state.effect != null) {
          effects.add(state.effect!);
        }
      });

      await cubit.onToggle(cubit.state.build.todos.first);
      await Future<void>.delayed(Duration.zero);

      expect(effects.first, isA<ShowProgressEffect>());
      expect(effects.last, isA<HideProgressEffect>());
      await cubit.close();
    });

    test('a failed write unlocks the screen again', () async {
      final FakeBackend failing = FakeBackend(<String, RouteHandler>{
        'GET /users': (RequestOptions _) => usersJson,
      });
      final PostFormCubit cubit = _postFormCubit(failing);
      await cubit.load();
      cubit.titleController.text = 'Title';
      cubit.bodyController.text = 'Body';

      await cubit.submit(); // POST /posts is not routed: it fails

      expect(cubit.isBusy, isFalse);
      await cubit.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Screen level: the loader appears and the controls are locked
  // ---------------------------------------------------------------------------
  group('screen behaviour while a request runs', () {
    testWidgets('saving a post shows the loader and locks the form', (
      WidgetTester tester,
    ) async {
      final PostFormCubit cubit = _postFormCubit(backend);
      await pumpApp(
        tester,
        // Provides the post form Cubit to the screen.
        BlocProvider<PostFormCubit>.value(
          value: cubit..load(),
          child: const PostFormScreen(),
        ),
        size: const Size(500, 900),
      );
      await tester.pump(_slow * 2);
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Title');
      await tester.enterText(find.byType(TextField).at(1), 'Body');
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
      await tester.pump(); // request started
      await tester.pump(const Duration(milliseconds: 50));

      // The square loader covers the screen ...
      expect(find.byType(SquareLoader), findsOneWidget);
      expect(cubit.isBusy, isTrue);
      // ... and tapping Save again does nothing.
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.save),
        warnIfMissed: false,
      );
      await tester.pump(_slow * 2);
      await tester.pump(const Duration(milliseconds: 400));
      expect(backend.count('POST /posts'), 1);
      expect(cubit.isBusy, isFalse);
      await cubit.close();
    });

    testWidgets('ticking a todo shows the loader and locks the other items', (
      WidgetTester tester,
    ) async {
      final TodoListCubit cubit = TodoListCubit(
        todoRepository: TodoRepository(backend.createClient()),
      );
      await pumpApp(
        tester,
        // Provides the todo list Cubit to the screen.
        BlocProvider<TodoListCubit>.value(
          value: cubit..load(),
          child: const TodoListScreen(),
        ),
        size: const Size(500, 900),
      );
      await tester.pump(_slow * 2);
      await tester.pump();

      await tester.tap(find.byType(Checkbox).at(0)); // Todo 1: PATCH starts
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SquareLoader), findsOneWidget);

      await tester.tap(find.byType(Checkbox).at(2), warnIfMissed: false);
      await tester.pump(_slow * 2);
      await tester.pump(const Duration(milliseconds: 400));

      expect(backend.count('PATCH /todos/1'), 1);
      expect(backend.count('PATCH /todos/3'), 0);
      await cubit.close();
    });
  });
}

/// Builds a post form Cubit (create mode) on top of [backend].
PostFormCubit _postFormCubit(FakeBackend backend) {
  return PostFormCubit(
    postId: null,
    postRepository: PostRepository(backend.createClient()),
    userRepository: UserRepository(backend.createClient()),
  );
}

/// Builds a post details Cubit for the post 2 on top of [backend].
PostDetailsCubit _postDetailsCubit(FakeBackend backend) {
  return PostDetailsCubit(
    postId: 2,
    postRepository: PostRepository(backend.createClient()),
    userRepository: UserRepository(backend.createClient()),
    commentRepository: CommentRepository(backend.createClient()),
  );
}

/// An [AuthRepository] whose `login` is slow and counts how often it runs.
class _CountingAuth extends AuthRepository {
  /// Creates it; [onLogin] is called on every login attempt.
  _CountingAuth(this.onLogin)
    : super(secureStorage: InMemorySecureStorage(), simulatedLatency: _slow);

  /// Called each time `login` runs.
  final void Function() onLogin;

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    onLogin();
    await Future<void>.delayed(_slow);
    return AuthUserModel(name: 'A', email: email);
  }
}
