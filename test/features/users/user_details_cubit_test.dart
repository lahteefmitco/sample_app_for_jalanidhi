import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_state.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/sample_data.dart';

/// Unit tests for [UserDetailsCubit]: loading a user with their posts, the
/// error state for an unknown user, and opening one of the posts.
void main() {
  /// Fake JSONPlaceholder server; also counts the requests it receives.
  late FakeBackend backend;

  /// Creates a [UserDetailsCubit] for [userId] that uses the fake [backend].
  UserDetailsCubit buildCubit(int userId) {
    final ApiClient api = backend.createClient();
    return UserDetailsCubit(
      userId: userId,
      userRepository: UserRepository(api),
      postRepository: PostRepository(api),
    );
  }

  setUp(() {
    // Only user 2 exists; its posts are the sample posts with userId 2.
    backend = FakeBackend(<String, RouteHandler>{
      'GET /users/2': (RequestOptions _) => usersJson[1],
      'GET /users/2/posts': (RequestOptions _) => postsJson
          .where((Map<String, dynamic> p) => p['userId'] == 2)
          .toList(),
    });
  });

  test('loads the user and the user\'s posts in one go', () async {
    // Arrange: record the status of every state the cubit emits.
    final UserDetailsCubit cubit = buildCubit(2);
    final List<ViewStatus> statuses = <ViewStatus>[];
    final StreamSubscription<ScreenState<UserDetailsBuildState>> sub = cubit
        .stream
        .listen(
          (ScreenState<UserDetailsBuildState> s) =>
              statuses.add(s.build.status),
        );

    // Act
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // Assert: a single loading -> loaded transition for both requests.
    expect(statuses, <ViewStatus>[ViewStatus.loading, ViewStatus.loaded]);
    expect(cubit.state.build.user!.name, 'Alice Smith');
    expect(cubit.state.build.posts, hasLength(15));
    await cubit.close();
  });

  test('an unknown user ends in the error state', () async {
    final UserDetailsCubit cubit = buildCubit(99);
    await cubit.load();
    expect(cubit.state.build.status, ViewStatus.error);
    expect(cubit.state.build.errorMessage, isNotNull);
    expect(cubit.state.effect, isA<ShowSnackbarEffect>());
    await cubit.close();
  });

  test('tapping a post navigates to its details', () async {
    final UserDetailsCubit cubit = buildCubit(2);
    await cubit.load();
    cubit.onPostTapped(cubit.state.build.posts.first);
    final NavigateEffect navigate = cubit.state.effect as NavigateEffect;
    expect(navigate.routeName, RouteNames.postDetails);
    expect(navigate.arguments, cubit.state.build.posts.first.id);
    await cubit.close();
  });
}
