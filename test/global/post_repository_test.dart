import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_exception.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';

import '../helpers/fake_backend.dart';
import '../helpers/sample_data.dart';

/// Tests for [PostRepository]: caching, per-user posts, and the local
/// create / update / delete overlay on top of the (fake) server data.
void main() {
  /// Fake server; also counts how often each route was called.
  late FakeBackend backend;

  /// The repository under test, recreated before every test.
  late PostRepository repository;

  // Fresh fake server and repository for every test.
  setUp(() {
    backend = FakeBackend(<String, RouteHandler>{
      'GET /posts': (RequestOptions _) => postsJson,
      'GET /posts/2': (RequestOptions _) => postsJson[1],
      'GET /users/1/posts': (RequestOptions _) => postsJson
          .where((Map<String, dynamic> p) => p['userId'] == 1)
          .toList(),
      'POST /posts': (RequestOptions _) => <String, int>{'id': 101},
      'PUT /posts/2': (RequestOptions _) => postsJson[1],
      'DELETE /posts/3': (RequestOptions _) => <String, dynamic>{},
    });
    repository = PostRepository(backend.createClient());
  });

  test('getPosts fetches once and then serves from cache', () async {
    expect(await repository.getPosts(), hasLength(45));
    expect(await repository.getPosts(), hasLength(45));
    expect(backend.count('GET /posts'), 1);
    await repository.getPosts(forceRefresh: true);
    expect(backend.count('GET /posts'), 2);
  });

  test('getPostsByUser uses /users/{id}/posts', () async {
    final List<PostModel> result = await repository.getPostsByUser(1);
    expect(result, hasLength(15));
    expect(result.every((PostModel post) => post.userId == 1), isTrue);
  });

  test('createPost adds a local post with a unique id on top', () async {
    final PostModel first = await repository.createPost(
      userId: 1,
      title: 'a',
      body: 'b',
    );
    final PostModel second = await repository.createPost(
      userId: 1,
      title: 'c',
      body: 'd',
    );
    expect(first.id, isNot(second.id));
    final List<PostModel> list = await repository.getPosts();
    expect(list, hasLength(47));
    expect(list.first.id, second.id);
    expect(await repository.getPost(first.id), isNotNull);
  });

  test('updatePost overlays the server data', () async {
    await repository.getPosts();
    final PostModel original = await repository.getPost(2);
    await repository.updatePost(
      PostModel(
        id: original.id,
        userId: original.userId,
        title: 'edited',
        body: original.body,
      ),
    );
    final List<PostModel> list = await repository.getPosts();
    expect(list.firstWhere((PostModel p) => p.id == 2).title, 'edited');
    expect((await repository.getPost(2)).title, 'edited');
  });

  test('deletePost hides the post and getPost then fails with 404', () async {
    await repository.getPosts();
    await repository.deletePost(3);
    expect(
      (await repository.getPosts()).any((PostModel p) => p.id == 3),
      isFalse,
    );
    expect(
      repository.getPost(3),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.statusCode,
          'status',
          404,
        ),
      ),
    );
  });

  test('server failures surface as ApiException', () async {
    // A backend without routes answers every request with a 404.
    final PostRepository failing = PostRepository(
      FakeBackend(<String, RouteHandler>{}).createClient(),
    );
    expect(failing.getPosts(), throwsA(isA<ApiException>()));
  });
}
