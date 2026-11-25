import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_state.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/models/home_summary.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/album_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/in_memory_storage.dart';
import '../../helpers/sample_data.dart';

/// Unit tests for [HomeCubit]: the dashboard summary it computes from every
/// repository, the error state when one request fails, and the menu / logout
/// actions.
void main() {
  // Shared objects, re-created before every test in `setUp`.
  /// In-memory stand-in for the secure storage.
  late InMemorySecureStorage secure;

  /// Real [AuthRepository] using the in-memory secure storage.
  late AuthRepository auth;

  /// The [HomeCubit] under test.
  late HomeCubit cubit;

  /// Creates a [HomeCubit] whose repositories all talk to [backend].
  HomeCubit buildCubit(FakeBackend backend) {
    final ApiClient api = backend.createClient();
    return HomeCubit(
      authRepository: auth,
      userRepository: UserRepository(api),
      postRepository: PostRepository(api),
      commentRepository: CommentRepository(api),
      todoRepository: TodoRepository(api),
      albumRepository: AlbumRepository(api),
    );
  }

  // Fake routes for every endpoint the dashboard needs.
  final Map<String, RouteHandler> fullBackend = <String, RouteHandler>{
    'GET /users': (RequestOptions _) => usersJson,
    'GET /posts': (RequestOptions _) => postsJson,
    'GET /comments': (RequestOptions _) => commentsJson,
    'GET /todos': (RequestOptions _) => todosJson,
    'GET /albums': (RequestOptions _) => albumsJson,
  };

  setUp(() async {
    // A logged-in user named "Jane", stored in memory instead of the device.
    secure = InMemorySecureStorage();
    auth = AuthRepository(
      secureStorage: secure,
      simulatedLatency: Duration.zero,
    );
    await auth.register(name: 'Jane', email: 'j@mail.test', password: '123456');
  });

  tearDown(() => cubit.close());

  test('computes the dashboard summary', () async {
    cubit = buildCubit(FakeBackend(fullBackend));
    await cubit.load();
    final HomeBuildState build = cubit.state.build;
    expect(build.status, ViewStatus.loaded);
    expect(build.userName, 'Jane');
    final HomeSummary summary = build.summary!;
    expect(summary.userCount, 3);
    expect(summary.postCount, 45);
    expect(summary.commentCount, 6);
    expect(summary.albumCount, 3);
    expect(summary.completedTodoCount, 2);
    expect(summary.pendingTodoCount, 3);
    expect(summary.todoCompletionRate, closeTo(0.4, 1e-9));
  });

  test('a failing endpoint produces an error state', () async {
    // Arrange: the same backend, but without the todos route (it will fail).
    cubit = buildCubit(
      FakeBackend(<String, RouteHandler>{...fullBackend}..remove('GET /todos')),
    );
    await cubit.load();
    expect(cubit.state.build.status, ViewStatus.error);
    expect(cubit.state.effect, isA<ShowSnackbarEffect>());
  });

  test(
    'menu selection navigates; logout asks first, then clears the stack',
    () async {
      cubit = buildCubit(FakeBackend(fullBackend));
      cubit.onMenuItemSelected(HomeCubit.menuItems.first);
      expect(
        (cubit.state.effect as NavigateEffect).routeName,
        RouteNames.userList,
      );

      // Logout only shows a confirmation; the user is still logged in.
      cubit.onLogoutPressed();
      final ShowConfirmationEffect confirm =
          cubit.state.effect as ShowConfirmationEffect;
      expect(await auth.isLoggedIn(), isTrue);

      // Confirming logs out; two zero delays let the async work finish.
      cubit.onConfirmed(confirm.actionId);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(await auth.isLoggedIn(), isFalse);
      final NavigateEffect navigate = cubit.state.effect as NavigateEffect;
      expect(navigate.routeName, RouteNames.login);
      expect(navigate.mode, NavigationStyle.clearStack);
    },
  );
}
