import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/effects.dart';
import '../../helpers/fake_backend.dart';
import '../../helpers/sample_data.dart';

/// Unit tests for [PostFormCubit] in both modes: creating a new post and
/// editing an existing one (validation, saving, server errors, cleanup).
void main() {
  /// Fake JSONPlaceholder server; also counts the requests it receives.
  late FakeBackend backend;

  /// Real [PostRepository] that talks to the fake [backend].
  late PostRepository postRepository;

  /// Real [UserRepository] that talks to the fake [backend].
  late UserRepository userRepository;

  /// Creates the cubit: create mode when [postId] is null, edit mode otherwise.
  PostFormCubit buildCubit({int? postId}) => PostFormCubit(
    postId: postId,
    postRepository: postRepository,
    userRepository: userRepository,
  );

  setUp(() {
    // Fake routes for loading authors / posts and for saving a post.
    backend = FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => usersJson,
      'GET /posts': (RequestOptions _) => postsJson,
      'GET /posts/2': (RequestOptions _) => postsJson[1],
      'POST /posts': (RequestOptions _) => <String, int>{'id': 101},
      'PUT /posts/2': (RequestOptions _) => postsJson[1],
    });
    final ApiClient api = backend.createClient();
    postRepository = PostRepository(api);
    userRepository = UserRepository(api);
  });

  // Create mode: the form starts empty and saving sends a POST.
  group('create mode', () {
    late PostFormCubit cubit;
    setUp(() => cubit = buildCubit());
    tearDown(() => cubit.close());

    test('loads the authors and selects the first one', () async {
      await cubit.load();
      expect(cubit.isEdit, isFalse);
      expect(cubit.state.build.status, ViewStatus.loaded);
      expect(cubit.state.build.users, hasLength(3));
      expect(cubit.state.build.selectedUserId, 1);
      expect(cubit.titleController.text, isEmpty);
    });

    test('empty title/body show errors and nothing is sent', () async {
      await cubit.load();
      final List<UiEffect> effects = await collectEffects(cubit, cubit.submit);
      expect(cubit.state.build.titleError, isNotNull);
      expect(cubit.state.build.bodyError, isNotNull);
      expect(effects, isEmpty);
      expect(backend.count('POST /posts'), 0);
    });

    test('saving creates the post and pops with "saved"', () async {
      // Arrange: fill the form (the title has extra spaces to trim).
      await cubit.load();
      cubit.onUserChanged(2);
      cubit.titleController.text = ' New title ';
      cubit.bodyController.text = 'New body';

      // Act
      final List<UiEffect> effects = await collectEffects(cubit, cubit.submit);

      // Assert
      expect(backend.count('POST /posts'), 1);
      expect(effects[0], isA<ShowProgressEffect>());
      expect(effects[1], isA<HideProgressEffect>());
      expect((effects[2] as PopEffect).result, 'saved');
      final PostModel created = (await postRepository.getPosts()).first;
      expect(created.title, 'New title');
      expect(created.userId, 2);
    });

    test('a server failure hides progress and shows an error', () async {
      // Removing the route makes the fake backend fail the POST request.
      backend.routes.remove('POST /posts');
      await cubit.load();
      cubit.titleController.text = 't';
      cubit.bodyController.text = 'b';
      final List<UiEffect> effects = await collectEffects(cubit, cubit.submit);
      expect(effects[1], isA<HideProgressEffect>());
      expect((effects[2] as ShowSnackbarEffect).type, SnackbarType.error);
      expect(effects.whereType<PopEffect>(), isEmpty);
    });
  });

  // Edit mode: the form is filled from post 2 and saving sends a PUT.
  group('edit mode', () {
    late PostFormCubit cubit;
    setUp(() => cubit = buildCubit(postId: 2));
    tearDown(() => cubit.close());

    test('fills the fields with the existing post', () async {
      await cubit.load();
      expect(cubit.isEdit, isTrue);
      expect(cubit.titleController.text, 'Post title 2');
      expect(cubit.bodyController.text, 'Post body 2');
      expect(cubit.state.build.selectedUserId, 2);
    });

    test('saving updates the post', () async {
      await cubit.load();
      cubit.titleController.text = 'Edited';
      final List<UiEffect> effects = await collectEffects(cubit, cubit.submit);
      expect(backend.count('PUT /posts/2'), 1);
      expect((effects.last as PopEffect).result, 'saved');
      expect((await postRepository.getPost(2)).title, 'Edited');
    });

    test('a missing post produces an error state', () async {
      // Post 999 has no route in the fake backend, so loading it fails.
      final PostFormCubit missing = buildCubit(postId: 999);
      await missing.load();
      expect(missing.state.build.status, ViewStatus.error);
      await missing.close();
    });
  });

  test('closing disposes both controllers', () async {
    final PostFormCubit cubit = buildCubit();
    final TextEditingController title = cubit.titleController;
    final TextEditingController body = cubit.bodyController;
    await cubit.close();
    // A disposed controller throws when it is used again.
    expect(() => title.addListener(() {}), throwsStateError);
    expect(() => body.addListener(() {}), throwsStateError);
  });
}
