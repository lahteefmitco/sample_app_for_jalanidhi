import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/effects.dart';
import '../../helpers/fake_backend.dart';
import '../../helpers/sample_data.dart';

/// Unit tests for [PostDetailsCubit]: loading a post with its author and
/// comments, errors, editing, deleting and opening a comment.
void main() {
  /// Fake JSONPlaceholder server; also counts the requests it receives.
  late FakeBackend backend;

  /// The [PostDetailsCubit] under test.
  late PostDetailsCubit cubit;

  /// Creates a [PostDetailsCubit] for [postId] that uses the fake [backend].
  PostDetailsCubit buildCubit(int postId) {
    final ApiClient api = backend.createClient();
    return PostDetailsCubit(
      postId: postId,
      postRepository: PostRepository(api),
      userRepository: UserRepository(api),
      commentRepository: CommentRepository(api),
    );
  }

  setUp(() {
    backend = FakeBackend(<String, RouteHandler>{
      'GET /posts/1': (RequestOptions _) => postsJson[0],
      'GET /users/1': (RequestOptions _) => usersJson[0],
      // Like the real API: filter by the `postId` query when it is present.
      'GET /comments': (RequestOptions options) {
        final Object? postId = options.queryParameters['postId'];
        return postId == null
            ? commentsJson
            : commentsJson
                  .where((Map<String, dynamic> c) => c['postId'] == postId)
                  .toList();
      },
      'DELETE /posts/1': (RequestOptions _) => <String, dynamic>{},
    });
    cubit = buildCubit(1);
  });

  tearDown(() => cubit.close());

  test('loads the post, its author and only its comments', () async {
    await cubit.load();
    final PostDetailsBuildState build = cubit.state.build;
    expect(build.status, ViewStatus.loaded);
    expect(build.post!.id, 1);
    expect(build.author!.name, 'Charlie Brown');
    // sample comments alternate between post 1 and 2: 3 belong to post 1
    expect(build.comments, hasLength(3));
    expect(build.comments.every((CommentModel c) => c.postId == 1), isTrue);
  });

  test('a failing request becomes an error state plus a snackbar', () async {
    // Post 77 has no route in the fake backend, so the request fails.
    final PostDetailsCubit failing = buildCubit(77);
    await failing.load();
    expect(failing.state.build.status, ViewStatus.error);
    expect(failing.state.effect, isA<ShowSnackbarEffect>());
    await failing.close();
  });

  test('edit navigates to the form with the post id', () {
    cubit.onEditPressed();
    final NavigateEffect navigate = cubit.state.effect as NavigateEffect;
    expect(navigate.routeName, RouteNames.postForm);
    expect(navigate.arguments, 1);
  });

  test('delete asks first and only deletes after confirmation', () async {
    // Act 1: pressing delete only shows a confirmation.
    await cubit.load();
    cubit.onDeletePressed();
    final ShowConfirmationEffect confirm =
        cubit.state.effect as ShowConfirmationEffect;
    expect(backend.count('DELETE /posts/1'), 0);

    // Act 2: confirming sends the DELETE and pops the screen.
    final List<UiEffect> effects = await collectEffects(
      cubit,
      () => cubit.onConfirmed(confirm.actionId),
    );
    expect(backend.count('DELETE /posts/1'), 1);
    expect(effects[0], isA<ShowProgressEffect>());
    expect(effects[1], isA<HideProgressEffect>());
    expect((effects[2] as PopEffect).result, 'deleted');
  });

  test('tapping a comment opens an info sheet with its fields', () async {
    await cubit.load();
    cubit.onCommentTapped(cubit.state.build.comments.first);
    final ShowInfoSheetEffect sheet = cubit.state.effect as ShowInfoSheetEffect;
    expect(sheet.fields.map((MapEntry<String, String> f) => f.key), <String>[
      'Name',
      'Email',
      'Post',
      'Body',
    ]);
  });

  test(
    'returning from the form reloads silently and reports success',
    () async {
      await cubit.load();
      final PostDetailsBuildState before = cubit.state.build;
      // The form screen pops with the result 'saved'.
      final List<UiEffect> effects = await collectEffects(
        cubit,
        () => cubit.onNavigationReturn('saved'),
      );
      expect(identical(before, cubit.state.build), isFalse); // reloaded
      expect(
        effects.whereType<ShowSnackbarEffect>().single.message,
        AppStrings.postSaved,
      );
    },
  );
}
